from flask import Flask, request, jsonify
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({"status": "healthy"}), 200

@app.route('/api/process', methods=['POST'])
def process_form():
    if not request.is_json:
        return jsonify({"error": "Request must be JSON"}), 400

    data = request.get_json()
    name = data.get('name')
    email = data.get('email')

    if not name or not email:
        return jsonify({"error": "Both name and email are required fields"}), 400

    processed_data = f"Welcome, {name}! Your registration for {email} has been processed."
    
    return jsonify({
        "message": "Data received and processed successfully by Flask!",
        "processed_data": processed_data
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
