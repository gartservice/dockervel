#!/bin/bash

source "./bash-scripts/parse_config.sh"

initialize_database() {
    echo -e "\n\033[1;34mInitializing database inside container: $MYSQL_CONTAINER...\033[0m"
    docker exec -it "$MYSQL_CONTAINER" bash -c /init.sh
    echo -e "\033[1;32mDatabase initialization completed.\033[0m"
}
