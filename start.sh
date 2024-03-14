#!/bin/bash

# Function to check if a package is installed
check_package() {
    dpkg -s "$1" &> /dev/null
}

# Function to prompt user for input
prompt_user() {
    read -p "$1" input_var
    echo "$input_var"
}

# Update package lists
sudo apt-get update

# Install necessary packages
sudo apt-get install gnupg2 wget apt-transport-https unzip -y

# Create directory for keyrings
sudo mkdir -p /etc/apt/keyrings

# Download and add Adoptium key
sudo wget -O - https://packages.adoptium.net/artifactory/api/gpg/key/public | sudo tee /etc/apt/keyrings/adoptium.asc

# Add Adoptium repository
echo "deb [signed-by=/etc/apt/keyrings/adoptium.asc] https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" | sudo tee /etc/apt/sources.list.d/adoptium.list

# Update package lists again
sudo apt-get update

# Install Temurin JDK 21
sudo apt-get install temurin-21-jdk

# Check if libfreetype-dev is installed
if ! check_package libfreetype-dev; then
    # If not installed, install libfreetype-dev
    sudo apt-get install libfreetype-dev
fi

# Download JavaFX 21
wget https://download2.gluonhq.com/openjfx/21/openjfx-21_linux-x64_bin-jmods.zip

# Unzip JavaFX 21
unzip openjfx-21_linux-x64_bin-jmods.zip

# Copy JavaFX modules to Temurin JDK directory
sudo cp javafx-jmods-21/* /usr/lib/jvm/temurin-21-jdk-amd64/jmods

# Clean up downloaded JavaFX modules
rm -r javafx-jmods-21

# Update alternatives for Java and Javac
sudo update-alternatives --config java
sudo update-alternatives --config javac

# Create launcher user
sudo useradd -m -s /bin/bash launcher

# Switch to launcher user
su - launcher

# Prompt for domain or IP
domain_or_ip=$(prompt_user "Enter your domain or IP address: ")

# Prompt for project name
project_name=$(prompt_user "Enter your project name: ")

# Execute setup script for launcher
wget -O - https://mirror.gravitlauncher.com/scripts/setup-master.sh | bash <(cat) </dev/tty

# After setup is complete, prompt to start
read -p "Press Enter to start the launcher server..."

# Start launcher server
./start.sh

# Provide feedback that installation is complete
echo "Launcher setup complete."
