# Use an official lightweight Node.js runtime as a parent image
FROM node:18-alpine

# Set the working directory within the container
WORKDIR /usr/src/app

# Copy package.json and package-lock.json (if available)
COPY package*.json ./

# Install app dependencies
RUN npm install

# Copy the rest of the frontend application code into the container
COPY . .

# Inform Docker that the container listens on port 3000
EXPOSE 3000

# Command to run the Express server when the container starts
CMD [ "node", "server.js" ]
