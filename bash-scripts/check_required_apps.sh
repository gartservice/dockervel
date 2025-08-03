#!/bin/bash

# List of required applications
REQUIRED_APPS=("curl" "wget" "git" "docker" "docker-compose" "ufw" "jq" "fzf" "cloudflared")

# Function to check if a package is installed
check_installed() {
    local app="$1"
    
    # Special case for cloudflared - check if it's available in PATH
    if [[ "$app" == "cloudflared" ]]; then
        if command -v cloudflared &> /dev/null; then
            return 0  # cloudflared is installed
        else
            return 1  # cloudflared is not installed
        fi
    fi
    
    # Special case for fake test app
    if [[ "$app" == "fake-test-app" ]]; then
        return 1  # Always return as missing for testing
    fi
    
    # For other packages, use dpkg
    dpkg -l | grep -qw "$app"
}

# Function to install cloudflared using official Cloudflare repository
install_cloudflared() {
    echo -e "\033[1;36mInstalling cloudflared from official Cloudflare repository...\033[0m"
    
    # Detect Ubuntu version
    local ubuntu_version=$(lsb_release -cs 2>/dev/null)
    local ubuntu_version_number=$(lsb_release -rs 2>/dev/null | cut -d. -f1)
    
    # Map Ubuntu versions to repository names
    case "$ubuntu_version" in
        "focal")
            local repo_name="focal"
            ;;
        "jammy")
            local repo_name="jammy"
            ;;
        "noble")
            local repo_name="noble"
            ;;
        *)
            # For unsupported versions, try to use a compatible repository
            if [[ "$ubuntu_version_number" -ge 20 && "$ubuntu_version_number" -le 24 ]]; then
                echo -e "\033[1;33mWarning: Ubuntu version $ubuntu_version is not officially supported by Cloudflare\033[0m"
                echo -e "\033[1;33mAttempting to use jammy (22.04) repository as fallback...\033[0m"
                local repo_name="jammy"
            else
                echo -e "\033[1;31mError: Unsupported Ubuntu version: $ubuntu_version\033[0m"
                echo -e "\033[1;33mPlease install cloudflared manually from: https://pkg.cloudflare.com/cloudflared\033[0m"
                return 1
            fi
            ;;
    esac
    
    echo -e "\033[1;34mDetected Ubuntu version: $ubuntu_version (using $repo_name repository)\033[0m"
    
    # Add cloudflare gpg key
    echo -e "\033[1;34mAdding Cloudflare GPG key...\033[0m"
    sudo mkdir -p --mode=0755 /usr/share/keyrings
    curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null
    
    # Add repository
    echo -e "\033[1;34mAdding Cloudflare repository...\033[0m"
    echo "deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared $repo_name main" | sudo tee /etc/apt/sources.list.d/cloudflared.list
    
    # Update and install
    echo -e "\033[1;34mUpdating package list and installing cloudflared...\033[0m"
    sudo apt-get update && sudo apt-get install -y cloudflared
    
    if command -v cloudflared &> /dev/null; then
        echo -e "\033[1;32m✓ cloudflared installed successfully!\033[0m"
        return 0
    else
        echo -e "\033[1;31m✗ Failed to install cloudflared\033[0m"
        echo -e "\033[1;33mTrying alternative installation method...\033[0m"
        
        # Try alternative installation method for unsupported versions
        if [[ "$ubuntu_version" != "focal" && "$ubuntu_version" != "jammy" && "$ubuntu_version" != "noble" ]]; then
            echo -e "\033[1;34mAttempting direct download installation...\033[0m"
            
            # Download and install cloudflared directly
            local temp_dir=$(mktemp -d)
            cd "$temp_dir"
            
            # Download the latest version
            curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o cloudflared
            
            if [[ -f cloudflared ]]; then
                sudo mv cloudflared /usr/local/bin/
                sudo chmod +x /usr/local/bin/cloudflared
                
                if command -v cloudflared &> /dev/null; then
                    echo -e "\033[1;32m✓ cloudflared installed successfully via direct download!\033[0m"
                    cd - > /dev/null
                    rm -rf "$temp_dir"
                    return 0
                fi
            fi
            
            cd - > /dev/null
            rm -rf "$temp_dir"
        fi
        
        return 1
    fi
}

# Function to install a package
install_package() {
    # Don't actually install in test mode
    if [[ "$1" == "fake-test-app" ]]; then
        echo -e "\033[1;33m[TEST MODE] Would install: $1\033[0m"
        return 0
    fi
    
    # Special case for cloudflared
    if [[ "$1" == "cloudflared" ]]; then
        install_cloudflared
        return $?
    fi
    
    # For other packages, use standard apt install
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
        echo -e "\n\033[1;36mDo you want to install all missing applications? (y/n): \033[0m"
        read -p "" install_choice
        
        if [[ "$install_choice" =~ ^[Yy]$ ]]; then
            echo -e "\n\033[1;34mInstalling missing applications...\033[0m"
            for app in "${MISSING_APPS[@]}"; do
                echo -e "\033[1;36mInstalling $app...\033[0m"
                install_package "$app"
            done
            echo -e "\n\033[1;32m✓ All missing applications have been installed!\033[0m"
        else
            echo -e "\n\033[1;33mInstallation skipped. You can install missing applications manually later.\033[0m"
        fi
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
