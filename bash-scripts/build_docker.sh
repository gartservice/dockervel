#!/bin/bash

build_docker_containers() {
    echo -e "\n\033[1;34mBuilding and starting Docker containers...\033[0m"
    docker-compose up --build -d
    echo -e "\033[1;32mDocker containers are up and running!\033[0m"
}
