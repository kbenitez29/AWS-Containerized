resource "aws_vpc" "main" {
    cidr_block = var.vpc_cidr

    tags = {
        name = "main_vpc"
    }
}

# PUBLIC SUBNET CONFIGURATION

# Create the igw in the correct VPC, but "empty", you need to associate it
resource "aws_internet_gateway" "igw"{
    vpc_id = aws_vpc.main.id

    tags = {
        name = "main-igw"
    }
}

resource "aws_subnet" "public" {
    vpc_id = aws_vpc.main.id
    count = lenght(var.public_subnets) # Give the length of the var
    cidr_block = var.public_subnets[count.index] # Maps the var in main.tf in each iteration
    map_public_ip_on_launch = true

    tags = {
        name = "public-subnet-${count.index}" # ${} Print the value
    }
}

resource "aws_subnet" "private" {
    vpc_id = aws_vpc.main.id
    count = lenght(var.private_subnets) # Give the length of the var
    cidr_block = var.private_subnets[count.index] # Map the var in main.tf in each iteration
    map_public_ip_on_launch = false

    tags = {
        name = "private-subnet-${count.index}" # ${} Print the value
    }
}

# Create an empty route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
}

# You set up the rules in the route table (here you define the igw routing)
resource "aws_route" "public_access"{
    route_table_id = aws_route_table.public.id
    destination_cidr_block = "0.0.0.0/"
    gateway_id = aws_internet_gateway.igw.id
}


# Before this you just have separated things, you need to put it together to make it work
resource "aws_route_table_association" "route_internet_bind" {
    count = lenght(aws_subnet.public)
    subnet_id = aws_subnet.public[count.index].id
    route_table_id = aws_route_table.public.id
}

# PRIVATE SUBNET CONFIGURATION

# Create the elastic ip to attach to NAT gw (needs a public ip)
resource "aws_eip" "nat_ip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat"{
    allocation_id = aws_eip.nat_ip.id #Bind the eip with the NAT
    subnet_id = aws_subnet.public[0].id
    tags = {
        name = "main-nat"
    }
}

# Create an empty route table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route" "private_access" {
    route_table_id = aws_route_table.public.id

    # In this time the internet access is given by the Nat
    destination_cidr_block = "0.0.0.0/"
    nat_gateway_id = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "route_private" {
    count = lenght(aws_subnet.private)
    subnet_id = aws_subnet.private[count.index].id
    route_table_id = aws_route_table.private.id
}