#!/bin/bash
set -e

echo "Starting MongoDB installation..."

# Update system packages
apt-get update
apt-get install -y gnupg curl wget

# Import MongoDB public GPG key
curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | \
   gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor

# Create list file for MongoDB
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/7.0 multiverse" | \
    tee /etc/apt/sources.list.d/mongodb-org-7.0.list

# Update package list
apt-get update

# Install MongoDB
apt-get install -y mongodb-org

# Start MongoDB service
systemctl start mongod
systemctl enable mongod

# Wait for MongoDB to start
sleep 5

# Check MongoDB status
systemctl status mongod --no-pager

# Install AWS CLI for backups
apt-get install -y awscli

echo "MongoDB installation completed successfully!"
echo "MongoDB version:"
mongod --version
