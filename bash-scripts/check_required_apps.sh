#!/bin/bash

# List of required applications
REQUIRED_APPS=("curl" "wget" "git" "docker" "docker-compose" "ufw" "jq" "fzf" "cloudflared")

# Function to check if a package is installed
check_installed() {
    dpkg -l | grep -qw "$1"
}

# Function to install a package
install_package() {
    sudo apt update && sudo apt install -y "$1"
}

# Function to check all required applications
check_all_apps() {
    echo -e "\n\033[1;34mChecking required applications...\033[0m"
    MISSING_APPS=()
    for app in "${REQUIRED_APPS[@]}"; do
        if check_installed "$app"; then
            echo -e "\033[1;32m✔ $app is installed\033[0m"
        else
            echo -e "\033[1;31m✘ $app is missing\033[0m"
            MISSING_APPS+=("$app")
        fi
    done

    if [ ${#MISSING_APPS[@]} -eq 0 ]; then
        echo -e "\n\033[1;32mAll required applications are installed!\033[0m"
    else
        echo -e "\n\033[1;33mThe following applications are missing: ${MISSING_APPS[*]}\033[0m"
    fi
}

# Function to install missing applications
install_missing_apps() {
    if [ ${#MISSING_APPS[@]} -eq 0 ]; then
        echo -e "\n\033[1;32mNothing to install. All applications are present.\033[0m"
        return
    fi

    echo -e "\n\033[1;34mInstalling missing applications...\033[0m"
    for app in "${MISSING_APPS[@]}"; do
        install_package "$app"
    done
    echo -e "\033[1;32mInstallation complete.\033[0m"
}
