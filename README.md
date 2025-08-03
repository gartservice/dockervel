# Laravel Multi-Site Development Environment

A comprehensive bash-based management system for running multiple Laravel, WordPress, and other PHP applications in Docker containers with automatic SSL certificate generation, nginx configuration, and database management.

## 🚀 Features

- **Multi-Site Management**: Run multiple Laravel/WordPress sites simultaneously
- **Interactive Menu System**: User-friendly CLI interface with fuzzy search
- **Automatic SSL Generation**: Self-signed certificates for local development
- **Docker Integration**: Containerized PHP, MySQL, and nginx setup
- **Database Management**: Automatic database creation and migration support
- **Permission Management**: Laravel-specific permission fixing
- **Cloudflare Integration**: Support for Cloudflare tunnels
- **Version Control**: Support for different PHP and Laravel versions

## 📋 Prerequisites

### Required Applications
The system automatically checks for and can install these required applications:
- `curl` - HTTP client
- `wget` - File downloader
- `git` - Version control
- `docker` - Container platform
- `docker-compose` - Multi-container orchestration
- `ufw` - Firewall management
- `jq` - JSON processor
- `fzf` - Fuzzy finder (for interactive menus)
- `cloudflared` - Cloudflare tunnel client

### System Requirements
- Ubuntu/Debian-based Linux distribution
- Docker and Docker Compose installed
- Sudo privileges for package installation

## 🏗️ Project Structure

```
project-root/
├── sites/                  # Laravel/WordPress projects (one folder per site)
├── docker/                 # Docker configuration
│   ├── nginx/
│   │   └── conf.d/         # Generated nginx config files (*.conf)
│   ├── mysql/              # MySQL Docker setup
│   └── php/                # PHP Docker setup
├── certs/                  # Generated SSL certificates
├── bash-scripts/           # Management scripts
├── cloudflare/             # Cloudflare tunnel configuration
├── docs/                   # Documentation
├── docker-compose.yml      # Generated Docker Compose file
├── .env                    # Generated environment variables
├── config.json             # Main configuration file
├── config.base.json        # Configuration template
├── main.sh                 # Main interactive script
└── README.md               # This file
```

## 🚀 Quick Start

1. **Clone and Setup**:
   ```bash
   git clone <your-repo>
   cd <your-repo>
   chmod +x main.sh
   ```

2. **Generate Configuration**:
   ```bash
   ./main.sh
   # Select "Generate config.json from template"
   ```

3. **Check Requirements**:
   ```bash
   ./main.sh
   # Select "Check Required Applications"
   ```

4. **Add Your First Site**:
   ```bash
   ./main.sh
   # Select "Add New Site"
   ```

5. **Build and Start**:
   ```bash
   ./main.sh
   # Select "Build Docker Containers"
   docker-compose up -d
   ```

## 📖 Detailed Usage Guide

### Main Menu Options

#### 1. Add New Site
Creates a new Laravel, WordPress, or existing project site.

**Process**:
1. Enter site name (alphanumeric, dashes, underscores only)
2. Configure DNS (e.g., `mysite.local`)
3. Set database credentials
4. Choose public folder (`public` for Laravel, `.` for WordPress)
5. Enable/disable SSL
6. Select PHP version
7. Choose installation type:
   - **Laravel**: Fresh Laravel installation
   - **WordPress**: Fresh WordPress installation
   - **GitHub**: Clone from GitHub repository
   - **Existing**: Use existing code

**Generated Files**:
- Site folder in `sites/<site_name>/`
- SSL certificates in `certs/` (if enabled)
- Updated `config.json`
- Nginx configuration

#### 2. Delete Existing Site
Removes a site and all associated files.

**Process**:
1. Select site from list
2. Confirm deletion
3. Choose cleanup options:
   - Remove site folder
   - Delete database (with confirmation)
   - Remove nginx config
   - Delete SSL certificates
   - Update configuration

#### 3. Manual Scripts & Debug Menu
Access to scripts typically run automatically in the background. Use for manual execution, debugging, or testing.

**Available Options**:
- **Fix Laravel Permissions**: Fix file and directory permissions for Laravel applications
- **Build Docker Containers**: Build all Docker containers defined in configuration
- **Init Databases**: Initialize MySQL databases for all configured sites
- **Run Migrations**: Execute Laravel migrations for selected sites
- **Generate .env File**: Create `.env` file from `config.json` configuration
- **Generate docker-compose file**: Create `docker-compose.yml` from configuration
- **Generate nginx config files**: Create nginx configuration files for all sites
- **Generate database_config.json**: Create database configuration for MySQL initialization

#### 4. Check Required Applications
Verifies all required applications are installed.

**Features**:
- Checks each required application
- Reports missing applications
- Can install missing packages

#### 5. Generate config.json from template
Creates `config.json` from `config.base.json` template.

#### 6. Manage Laravel Aliases
Manages useful Laravel, Ubuntu, and Docker command aliases in your `.bashrc` file.

**Features**:
- **Install Aliases**: Adds comprehensive aliases to `.bashrc`
- **Preview Aliases**: Shows all available aliases before installation
- **Remove Aliases**: Safely removes aliases with backup
- **Reload .bashrc**: Automatically reloads configuration

**Available Aliases**:
- **Laravel**: `pa`, `pam`, `pat`, `pam:r`, `patest`, `paml`, `paoc`, `spaoc`, `palm`, `paqr`, `pamld`, `showlog`, `pads`, `ds`
- **Ubuntu**: `cl`, `add.alias`, `sc`
- **Docker**: `dcu-d`, `dcd`, `dl`, `dc`, `de-it`, `d`, `dps`, `dcs`

## ⚙️ Configuration

### config.json Structure

```json
{
  "docker_settings": {
    "networks": {
      "backend_network": "backend",
      "frontend_network": "frontend"
    },
    "mysql": {
      "container_name": "mysql",
      "root_password": "secret"
    },
    "nginx": {
      "container_name": "nginx",
      "http_port": 80,
      "https_port": 443,
      "ssl": {
        "cert": "certs/example.crt",
        "key": "certs/example.key"
      }
    },
    "sites": [
      {
        "name": "mysite",
        "server_name": "mysite.local",
        "root": "mysite",
        "public_folder": "public",
        "php_version": "8.3",
        "db_name": "mysite_db",
        "db_user": "root",
        "db_password": "secret",
        "ssl": {
          "enabled": true,
          "cert": "certs/mysite.crt",
          "key": "certs/mysite.key"
        }
      }
    ]
  },
  "local_settings": {
    "sites_folder": "./sites",
    "available_php_versions": ["8.4", "8.3", "8.2", "8.1", "8.0", "7.4"],
    "available_laravel_versions": ["12.*", "11.*", "10.*", "9.*"],
    "required_packages": ["curl", "wget", "git", "docker", "docker-compose", "ufw", "jq", "fzf", "cloudflared"],
    "cloudflare": {
      "email": "your-email@example.com",
      "api_key": "CHANGEME",
      "zone_id": "CHANGEME"
    }
  }
}
```

## 🔧 Script Reference

### Core Scripts

#### `main.sh`
Main interactive menu system that orchestrates all other scripts.

#### `bash-scripts/add_site.sh`
Handles new site creation with validation and configuration.

#### `bash-scripts/delete_site.sh`
Manages site deletion with cleanup options.

#### `bash-scripts/fix_permissions.sh`
Fixes Laravel-specific file and directory permissions.

#### `bash-scripts/generate_docker_compose.sh`
Generates Docker Compose configuration from JSON config.

#### `bash-scripts/generate_nginx_confs.sh`
Creates nginx configuration files for all sites.

#### `bash-scripts/run_migrations.sh`
Executes Laravel migrations in Docker containers.

#### `bash-scripts/check_required_apps.sh`
Verifies and installs required system applications.

#### `bash-scripts/generate_env.sh`
Creates `.env` file from configuration.

### Utility Scripts

#### `bash-scripts/utils.sh`
Common utility functions (fzf installation).

#### `bash-scripts/generate_config.sh`
Creates `config.json` from template.

#### `bash-scripts/generate_database_config.sh`
Generates database configuration for MySQL.

#### `bash-scripts/initialize_database.sh`
Initializes MySQL databases.

#### `bash-scripts/build_docker.sh`
Builds Docker containers.

#### `bash-scripts/docker_manager.sh`
Docker container management utilities.

#### `bash-scripts/add_laravel_aliases.sh`
Manages Laravel, Ubuntu, and Docker command aliases in `.bashrc`.

#### `bash-scripts/manual_scripts_menu.sh`
Provides a submenu for manual script execution and debugging options.

## 🌐 Accessing Your Sites

### Local Development
- **HTTP**: `http://your-site.local`
- **HTTPS**: `https://your-site.local` (if SSL enabled)

### Container Access
- **PHPMyAdmin**: `http://localhost:8081`
- **MySQL**: `localhost:3306`

### Container Management
```bash
# View running containers
docker-compose ps

# View logs
docker-compose logs -f

# Access container shell
docker exec -it php-83 bash
docker exec -it mysql bash

# Stop all containers
docker-compose down

# Rebuild containers
docker-compose up -d --build
```

## 🔒 SSL Certificates

The system automatically generates self-signed SSL certificates for local development:

- **Location**: `certs/` directory
- **Naming**: `{site_name}.crt` and `{site_name}.key`
- **Validity**: 365 days
- **Usage**: Automatically configured in nginx

**Note**: Self-signed certificates will show browser warnings. This is normal for local development.

## 🗄️ Database Management

### Automatic Database Creation
- Databases are created automatically when adding sites
- Each site gets its own database
- Default credentials: `root` / `secret`

### Manual Database Operations
```bash
# Access MySQL
docker exec -it mysql mysql -uroot -psecret

# Create database manually
CREATE DATABASE my_new_db;

# Import SQL file
docker exec -i mysql mysql -uroot -psecret my_db < backup.sql

# Export database
docker exec mysql mysqldump -uroot -psecret my_db > backup.sql
```

### Using Laravel Aliases
After installing aliases via the main menu, you can use these shortcuts:

```bash
# Laravel commands
pa          # php artisan
pam         # php artisan migrate
pat         # php artisan tinker
paoc        # php artisan optimize:clear
showlog     # tail -f storage/logs/laravel.log

# Docker commands
dcu-d       # docker-compose up -d
dcd         # docker-compose down
dps         # docker ps
de-it       # docker exec -it

# Ubuntu commands
cl          # clear
sc          # source ~/.bashrc
```

## 🛠️ Troubleshooting

### Common Issues

#### Permission Denied Errors
```bash
# Fix Laravel permissions
./main.sh
# Select "Fix Laravel Permissions"
```

#### Container Won't Start
```bash
# Check container logs
docker-compose logs <container_name>

# Rebuild containers
docker-compose down
docker-compose up -d --build
```

#### Site Not Accessible
1. Check if containers are running: `docker-compose ps`
2. Verify nginx config: `docker/nginx/conf.d/`
3. Check site DNS: Add to `/etc/hosts`
4. Verify SSL certificates: `certs/` directory

#### Database Connection Issues
1. Ensure MySQL container is running
2. Check database credentials in `config.json`
3. Verify `.env` file is generated
4. Check container networking

### Debug Commands
```bash
# Check all container status
docker-compose ps

# View nginx configuration
cat docker/nginx/conf.d/your-site.conf

# Check SSL certificates
ls -la certs/

# Verify site folder structure
ls -la sites/your-site/

# Test database connection
docker exec mysql mysql -uroot -psecret -e "SHOW DATABASES;"
```

## 🔄 Maintenance

### Regular Tasks
1. **Update Dependencies**: Run `composer update` in site directories
2. **Backup Databases**: Export databases regularly
3. **Clean Logs**: Clear Laravel logs in `storage/logs/`
4. **Update SSL**: Regenerate certificates if expired

### Backup Strategy
```bash
# Backup all databases
for db in $(docker exec mysql mysql -uroot -psecret -e "SHOW DATABASES;" | grep -v Database | grep -v information_schema | grep -v performance_schema); do
    docker exec mysql mysqldump -uroot -psecret "$db" > "backup_${db}_$(date +%Y%m%d).sql"
done

# Backup site files
tar -czf "sites_backup_$(date +%Y%m%d).tar.gz" sites/
```

## 📝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For issues and questions:
1. Check the troubleshooting section
2. Review the script documentation
3. Check container logs
4. Create an issue with detailed information

---

**Happy Coding! 🚀**


