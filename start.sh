#!/bin/bash

# Function to check if a package is installed
check_package() {
    dpkg -s "$1" &> /dev/null
}

# Function to prompt user for input
prompt_user() {
    read -p "$1" input_value
    echo "$input_value"
}

# Prompt for domain or IP
domain=$(prompt_user "Enter your domain or IP address: ")

# Prompt for project name
project_name=$(prompt_user "Enter your project name: ")

# Prompt for project mail
mail=$(prompt_user "Enter your project mail: ")

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
sudo apt-get install temurin-21-jdk -y

# Check if libfreetype-dev is installed
if ! check_package libfreetype-dev; then
    # If not installed, install libfreetype-dev
    sudo apt-get install libfreetype-dev -y
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

# Add a new user for running Gravit Launcher
sudo useradd -m -s /bin/bash launcher

# Switch to the launcher user
su - launcher << EOF
# Function to install Gravit Launcher
install_gravit_launcher() {
    # Download and run Gravit Launcher setup script
    wget -O - https://mirror.gravitlauncher.com/scripts/setup-master.sh | bash <(cat) </dev/tty
}

# Install Gravit Launcher
install_gravit_launcher

# Check if the build failed
if [ -d "src" ]; then
    # Remove src directory
    rm -r src

    # Reinstall Gravit Launcher
    install_gravit_launcher
else
    # Press Ctrl+C after successful setup
    exit
    pkill -INT bash
fi
EOF

su - launcher << EOF
# Start the launcher
./start.sh <<EOL
$domain
$project_name
stop
exit
EOL
EOF

#install Nginx
sudo apt install -y certbot
sudo apt install -y python3-certbot-nginx
certbot certonly --nginx -d $domain <<EOL
$mail
a
c
EOL
certbot -d $domain --manual --preferred-challenges dns certonly <<EOL
$mail
EOL
systemctl stop nginx
certbot renew
systemctl start nginx

# Provide feedback that installation is complete
echo "JavaFX 21 and Temurin JDK 21 have been installed successfully. Gravit Launcher setup completed."