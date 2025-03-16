#!/bin/bash

ensure_fzf_installed() {
    if ! command -v fzf &> /dev/null; then
        echo -e "\n\033[1;31mfzf is required for interactive menu. Installing...\033[0m"
        sudo apt update && sudo apt install -y fzf
    fi
}
