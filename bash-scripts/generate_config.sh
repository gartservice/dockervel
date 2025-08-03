#!/bin/bash

TEMPLATE_FILE="config.base.json"
TARGET_FILE="config.json"

# If config.example.json exists, use it as the template
if [ -f "config.example.json" ]; then
    TEMPLATE_FILE="config.example.json"
fi

generate_config_json() {
    if [ ! -f "$TEMPLATE_FILE" ]; then
        echo -e "\033[1;31mTemplate file $TEMPLATE_FILE not found!\033[0m"
        return 1
    fi
    if [ -f "$TARGET_FILE" ]; then
        read -p "config.json already exists. Overwrite? (y/n): " CONFIRM
        if [[ "$CONFIRM" != "y" ]]; then
            echo -e "\033[1;33mOperation cancelled. config.json was not modified.\033[0m"
            return 0
        fi
    fi
    cp "$TEMPLATE_FILE" "$TARGET_FILE"
    echo -e "\033[1;32m$TARGET_FILE generated from $TEMPLATE_FILE!\033[0m"
} 