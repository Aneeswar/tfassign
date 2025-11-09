from flask import Flask, request, jsonify
from flask_cors import CORS

# Initialize the Flask application
app = Flask(__name__)
# Enable Cross-Origin Resource Sharing (CORS) to allow requests from the frontend
CORS(app)

@app.route('/process', methods=['POST'])
def process_form():
    """
    API endpoint to receive and process form data from the frontend.
    Expects a JSON payload with 'name' and 'email'.
    """
    # Check if the request contains JSON data
    if not request.is_json:
        return jsonify({"error": "Request must be JSON"}), 400

    data = request.get_json()
    name = data.get('name')
    email = data.get('email')

    # Validate that name and email are present
    if not name or not email:
        return jsonify({"error": "Both name and email are required fields"}), 400

    # Process the data (for this example, we just create a welcome message)
    processed_data = f"Welcome, {name}! Your registration for {email} has been processed."
    
    # Create a success response
    response = {
        "message": "Data received and processed successfully by Flask!",
        "processed_data": processed_data
    }
    
    return jsonify(response)

# Run the app on host 0.0.0.0 to be accessible from the Docker network
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
