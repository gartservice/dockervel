#!/bin/bash

# Function to check if aliases already exist in .bashrc
check_aliases_exist() {
    local bashrc_file="$HOME/.bashrc"
    local alias_section="# Laravel Development Aliases"
    
    if grep -q "$alias_section" "$bashrc_file" 2>/dev/null; then
        return 0  # Aliases section exists
    else
        return 1  # Aliases section doesn't exist
    fi
}

# Function to backup .bashrc file
backup_bashrc() {
    local bashrc_file="$HOME/.bashrc"
    local backup_file="$HOME/.bashrc.backup.$(date +%Y%m%d_%H%M%S)"
    
    if cp "$bashrc_file" "$backup_file" 2>/dev/null; then
        echo -e "\033[1;34m✓ Backup created: $backup_file\033[0m"
        return 0
    else
        echo -e "\033[1;31m✗ Failed to create backup\033[0m"
        return 1
    fi
}

# Function to add aliases to .bashrc
add_aliases_to_bashrc() {
    local bashrc_file="$HOME/.bashrc"
    
    # Create the aliases section
    cat >> "$bashrc_file" << 'EOF'

# Laravel Development Aliases
# Added by Laravel Multi-Site Management System
# Laravel aliases
alias pam="php artisan migrate"
alias pa="php artisan"
alias pat="php artisan tinker"
alias pam:r="php artisan migrate:rollback"
alias patest="php artisan optimize:clear | php artisan test --env=testing"
alias paml="php artisan make:livewire"
alias paoc="php artisan optimize:clear"
alias spaoc="sudo php artisan optimize:clear"

alias palm="php artisan livewire:move"
alias paqr="php artisan queue:restart"
alias pamld="php artisan make:livewire-datatable"
alias showlog="clear | tail -f -n0 storage/logs/laravel.log"

alias pads="php artisan dump-server"
alias ds="php artisan dump-server"

# Project management aliases
alias main="./main.sh"

# Ubuntu aliases
alias cl="clear"
alias add.alias="nano ~/.bashrc"
alias sc="source ~/.bashrc"

# Docker aliases
alias dcu-d="docker-compose up -d"
alias dcd="docker-compose down"
alias dl="docker logs"
alias dc="docker-compose"
alias de-it="docker exec -it"
alias d="docker"
alias dps="docker ps"
alias dcs="docker-compose stop"

# End Laravel Development Aliases
EOF
}

# Function to show the aliases that will be added
show_aliases_preview() {
    echo -e "\n\033[1;36m====================================\033[0m"
    echo -e "\033[1;36m       Laravel Aliases Preview      \033[0m"
    echo -e "\033[1;36m====================================\033[0m"
    
    echo -e "\n\033[1;33mLaravel Commands:\033[0m"
    echo -e "  pam     - php artisan migrate"
    echo -e "  pa      - php artisan"
    echo -e "  pat     - php artisan tinker"
    echo -e "  pam:r   - php artisan migrate:rollback"
    echo -e "  patest  - php artisan optimize:clear | php artisan test --env=testing"
    echo -e "  paml    - php artisan make:livewire"
    echo -e "  paoc    - php artisan optimize:clear"
    echo -e "  spaoc   - sudo php artisan optimize:clear"
    echo -e "  palm    - php artisan livewire:move"
    echo -e "  paqr    - php artisan queue:restart"
    echo -e "  pamld   - php artisan make:livewire-datatable"
    echo -e "  showlog - clear | tail -f -n0 storage/logs/laravel.log"
    echo -e "  pads    - php artisan dump-server"
    echo -e "  ds      - php artisan dump-server"
    
    echo -e "\n\033[1;33mProject Management Commands:\033[0m"
    echo -e "  main    - ./main.sh (Laravel Multi-Site Management System)"
    
    echo -e "\n\033[1;33mUbuntu Commands:\033[0m"
    echo -e "  cl        - clear"
    echo -e "  add.alias - nano ~/.bashrc"
    echo -e "  sc        - source ~/.bashrc"
    
    echo -e "\n\033[1;33mDocker Commands:\033[0m"
    echo -e "  dcu-d  - docker-compose up -d"
    echo -e "  dcd    - docker-compose down"
    echo -e "  dl     - docker logs"
    echo -e "  dc     - docker-compose"
    echo -e "  de-it  - docker exec -it"
    echo -e "  d      - docker"
    echo -e "  dps    - docker ps"
    echo -e "  dcs    - docker-compose stop"
}

# Function to remove aliases from .bashrc
remove_aliases_from_bashrc() {
    local bashrc_file="$HOME/.bashrc"
    local temp_file=$(mktemp)
    
    # Remove the aliases section
    sed '/^# Laravel Development Aliases$/,/^# End Laravel Development Aliases$/d' "$bashrc_file" > "$temp_file"
    
    if mv "$temp_file" "$bashrc_file" 2>/dev/null; then
        echo -e "\033[1;32m✓ Laravel aliases removed from .bashrc\033[0m"
        return 0
    else
        echo -e "\033[1;31m✗ Failed to remove aliases\033[0m"
        return 1
    fi
}

# Function to show the aliases menu
show_aliases_menu() {
    clear
    echo -e "\n\033[1;36m====================================\033[0m"
    echo -e "\033[1;36m       Laravel Aliases Manager      \033[0m"
    echo -e "\033[1;36m====================================\033[0m"
    
    if check_aliases_exist; then
        echo -e "\n\033[1;32m✓ Laravel aliases are already installed\033[0m"
        echo -e "\n\033[1;33mOptions:\033[0m"
        echo -e "1. Preview aliases"
        echo -e "2. Remove aliases"
        echo -e "3. Reload .bashrc"
        echo -e "4. Back to main menu"
        
        read -p $'\n\033[1;34mSelect option (1-4): \033[0m' choice
        
        case $choice in
            1)
                show_aliases_preview
                read -p "Press Enter to continue..."
                ;;
            2)
                echo -e "\n\033[1;31mWarning: This will remove all Laravel aliases from .bashrc\033[0m"
                read -p "Are you sure? (y/n): " confirm
                if [[ "$confirm" =~ ^[Yy]$ ]]; then
                    if backup_bashrc; then
                        remove_aliases_from_bashrc
                    fi
                else
                    echo -e "\033[1;33mOperation cancelled.\033[0m"
                fi
                read -p "Press Enter to continue..."
                ;;
            3)
                echo -e "\n\033[1;34mReloading .bashrc...\033[0m"
                source ~/.bashrc
                echo -e "\033[1;32m✓ .bashrc reloaded successfully\033[0m"
                read -p "Press Enter to continue..."
                ;;
            4)
                echo -e "\n\033[1;34mReturning to main menu...\033[0m"
                return
                ;;
            *)
                echo -e "\n\033[1;31mInvalid option. Please try again.\033[0m"
                read -p "Press Enter to continue..."
                ;;
        esac
    else
        echo -e "\n\033[1;33mLaravel aliases are not installed\033[0m"
        echo -e "\n\033[1;33mOptions:\033[0m"
        echo -e "1. Preview aliases"
        echo -e "2. Install aliases"
        echo -e "3. Back to main menu"
        
        read -p $'\n\033[1;34mSelect option (1-3): \033[0m' choice
        
        case $choice in
            1)
                show_aliases_preview
                read -p "Press Enter to continue..."
                ;;
            2)
                echo -e "\n\033[1;34mInstalling Laravel aliases...\033[0m"
                if backup_bashrc; then
                    add_aliases_to_bashrc
                    echo -e "\033[1;32m✓ Laravel aliases installed successfully!\033[0m"
                    echo -e "\033[1;33mNote: Run 'source ~/.bashrc' or restart your terminal to activate the aliases.\033[0m"
                    
                    read -p "Reload .bashrc now? (y/n): " reload
                    if [[ "$reload" =~ ^[Yy]$ ]]; then
                        source ~/.bashrc
                        echo -e "\033[1;32m✓ .bashrc reloaded successfully\033[0m"
                    fi
                fi
                read -p "Press Enter to continue..."
                ;;
            3)
                echo -e "\n\033[1;34mReturning to main menu...\033[0m"
                return
                ;;
            *)
                echo -e "\n\033[1;31mInvalid option. Please try again.\033[0m"
                read -p "Press Enter to continue..."
                ;;
        esac
    fi
    
    # Recursive call to show menu again
    show_aliases_menu
}

# Execute function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    show_aliases_menu "$@"
fi 