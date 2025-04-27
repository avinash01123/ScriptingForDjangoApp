#!/bin/bash

# Function to clone the repository
code_clone(){
    echo "Cloning the django app..."
    if [ -d "django-notes-app" ]; then
        echo "The code directory already exists, skipping clone."
        return 1
    fi
    git clone https://github.com/LondheShubham153/django-notes-app.git || return 1
}

# Function to install required packages
install_requirements(){
    echo "Installing dependencies"
    sudo apt-get update && sudo apt-get install -y docker.io nginx docker-compose || return 1

    echo "Setting up Docker Buildx (optional)"
    mkdir -p ~/.docker/cli-plugins
    curl -SL https://github.com/docker/buildx/releases/latest/download/buildx-v0.14.1.linux-amd64 -o ~/.docker/cli-plugins/docker-buildx || return 1
    chmod +x ~/.docker/cli-plugins/docker-buildx
    echo "✅ Docker Buildx installed"

    echo "Cleaning up unnecessary packages"
    sudo apt autoremove -y
}

# Function to configure and restart services
required_restart(){
    echo "Configuring permissions and services"
    sudo chown "$USER" /var/run/docker.sock || return 1
    sudo systemctl enable docker || return 1

    # Check if port 80 is being used by host nginx, stop it
    if sudo lsof -i :80 | grep -q nginx; then
        echo "⚠️ Port 80 is already in use by host Nginx. Stopping host Nginx..."
        sudo systemctl stop nginx
        sudo systemctl disable nginx
    else
        echo "Port 80 is free. Proceeding..."
    fi

    sudo systemctl restart docker || return 1
}

# Function to deploy the application
deploy(){
    echo "Building and deploying the application"
    cd django-notes-app || return 1

    # Ensure .dockerignore exists to avoid permission issues
    if [ ! -f ".dockerignore" ]; then
        echo "Creating .dockerignore to exclude data directory"
        echo "data/" > .dockerignore
    fi

    docker build -t notes-app . || return 1
    docker-compose up -d || return 1
}

# Main deployment process
echo "***** Deployment Started *****"

# Clone the repository
if ! code_clone; then
    echo "Warning: Code directory already exists or clone failed - continuing with existing code"
fi

# Install requirements
if ! install_requirements; then
    echo "Error: Installation failed"
    exit 1
fi

# Configure and restart services
if ! required_restart; then
    echo "Error: System configuration failed"
    exit 1
fi

# Deploy the application
if ! deploy; then
    echo "Error: Deployment failed, mailing the admin"
    # Add actual sendmail or mailx command here
    exit 1
fi

