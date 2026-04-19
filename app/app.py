from flask import Flask

# Creating the server
app = Flask(__name__)

# Defining the route
@app.route("/")
def home():
    return"""
    <div style="
        display: flex; 
        justify-content: center; 
        align-items: center; 
        height: 100vh; 
        margin: 0;
        font-family: Arial, sans-serif;
    ">
        <h1 style="font-size: 4rem; color: #2c3e50;">
            Greetings from ECS :)
        </h1>
    </div>
    """ # Defining the shown message

# Accepting inbound traffic from the internet in HTTP port (ALB)
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)