Project structure

project-root/
├── sites/                  # Directory containing Laravel projects
│   ├── site1/              # Laravel application 1
│   ├── site2/              # Laravel application 2
│   ├── site3/              # Laravel application 3 (if added in the future)
│   ├── site4/              # Laravel application 4 (if added in the future)
│   └── shared/             # Shared files and resources (if needed)
├── docker/                 # Docker configuration directory
│   ├── nginx/              # Nginx configuration files
│   │   ├── conf.d/         # Individual configurations for each site
│   │   └── default.conf    # Main Nginx configuration file
│   ├── mysql/              # MySQL data storage (if manual management is required)
│   ├── php/                # PHP configuration files
│   ├── Dockerfile          # Common Dockerfile for Laravel applications
│   └── .env                # Environment variables for Docker services
├── bash-scripts/           # Bash scripts for automation (e.g., adding new sites)
├── cloudflare/             # Cloudflare Tunnel configuration (if needed)
├── docs/                   # Documentation related to the project setup and usage
├── docker-compose.yml      # Main Docker Compose file to orchestrate containers
├── .env                    # Global environment variables for the project
├── README.md               # Project description and setup instructions
└── LICENSE                 # Project license file (e.g., MIT, Apache 2.0)
