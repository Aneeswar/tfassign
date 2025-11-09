# Use an official lightweight Python runtime as a parent image
FROM python:3.9-slim

# Set the working directory within the container
WORKDIR /app

# Copy the requirements file into the container
COPY requirements.txt .

# Install the Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the backend application code into the container
COPY . .

# Inform Docker that the container listens on port 5000
EXPOSE 5000

# Command to run the Flask application when the container starts
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app:app"]
