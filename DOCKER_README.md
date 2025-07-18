# Dockerized Moodle Deployment

This project provides a complete Docker-based deployment solution for Moodle, including the application, MySQL database, Redis cache, and optional Nginx reverse proxy.

## 🐳 Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Nginx Proxy   │    │   Moodle App    │    │   phpMyAdmin    │
│   (Optional)    │    │   (PHP 8.1)     │    │   (Dev Only)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐    ┌─────────────────┐
                    │   MySQL 8.0     │    │   Redis 7       │
                    │   Database      │    │   Cache         │
                    └─────────────────┘    └─────────────────┘
```

## 📋 Prerequisites

- Docker Engine 20.10+
- Docker Compose 2.0+
- Git
- At least 4GB RAM available
- 10GB free disk space

## 🚀 Quick Start

### 1. Clone and Setup

```bash
git clone https://github.com/uLesson-Education/moodle.git
cd moodle
cp env.example .env
```

### 2. Configure Environment

Edit `.env` file with your settings:

```bash
# Database
MYSQL_ROOT_PASSWORD=your_secure_password
MYSQL_DATABASE=moodle
MYSQL_USER=moodle
MYSQL_PASSWORD=your_moodle_password

# Moodle
MOODLE_URL=http://localhost:8080
MOODLE_FULLNAME="My Learning Platform"
MOODLE_ADMIN_USER=admin
MOODLE_ADMIN_PASS=your_admin_password
MOODLE_ADMIN_EMAIL=admin@yourdomain.com
```

### 3. Start Services

```bash
# Development environment (includes phpMyAdmin)
docker-compose --profile development up -d

# Production environment (includes Nginx)
docker-compose --profile production up -d

# Basic environment (Moodle + MySQL + Redis only)
docker-compose up -d
```

### 4. Access Moodle

- **Moodle**: http://localhost:8080
- **phpMyAdmin**: http://localhost:8081 (development only)
- **Admin credentials**: As configured in `.env`

## 🔧 Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `MYSQL_ROOT_PASSWORD` | MySQL root password | `rootpassword` |
| `MYSQL_DATABASE` | Database name | `moodle` |
| `MYSQL_USER` | Database user | `moodle` |
| `MYSQL_PASSWORD` | Database password | `moodle` |
| `MOODLE_URL` | Moodle site URL | `http://localhost:8080` |
| `MOODLE_FULLNAME` | Site full name | `My Moodle Site` |
| `MOODLE_ADMIN_USER` | Admin username | `admin` |
| `MOODLE_ADMIN_PASS` | Admin password | `admin` |
| `MOODLE_ADMIN_EMAIL` | Admin email | `admin@example.com` |
| `PHP_MEMORY_LIMIT` | PHP memory limit | `512M` |
| `MOODLE_PORT` | Moodle port | `8080` |

### Docker Compose Profiles

#### Development Profile
```bash
docker-compose --profile development up -d
```
Includes:
- Moodle application
- MySQL database
- Redis cache
- phpMyAdmin (port 8081)

#### Production Profile
```bash
docker-compose --profile production up -d
```
Includes:
- Moodle application
- MySQL database
- Redis cache
- Nginx reverse proxy (ports 80, 443)

## 🛠️ Management Commands

### Basic Operations

```bash
# Start all services
docker-compose up -d

# Stop all services
docker-compose down

# View logs
docker-compose logs -f moodle

# Restart a specific service
docker-compose restart moodle

# Update and restart
docker-compose pull && docker-compose up -d
```

### Data Management

```bash
# Backup database
docker-compose exec mysql mysqldump -u root -p moodle > backup.sql

# Restore database
docker-compose exec -T mysql mysql -u root -p moodle < backup.sql

# Backup Moodle data
docker-compose exec moodle tar -czf /var/www/backups/moodledata_$(date +%Y%m%d).tar.gz -C /var/www/moodledata .

# Access MySQL shell
docker-compose exec mysql mysql -u moodle -p moodle
```

### Maintenance

```bash
# Clear Moodle cache
docker-compose exec moodle rm -rf /var/www/moodledata/cache/*

# Run Moodle CLI commands
docker-compose exec moodle php /var/www/html/admin/cli/upgrade.php

# Check container health
docker-compose ps
```

## 🔒 Security Considerations

### Production Deployment

1. **Use HTTPS**:
   ```bash
   # Generate SSL certificates
   mkdir -p nginx/ssl
   openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
     -keyout nginx/ssl/nginx.key -out nginx/ssl/nginx.crt
   ```

2. **Secure Environment Variables**:
   ```bash
   # Use strong passwords
   MYSQL_ROOT_PASSWORD=your_very_secure_password
   MYSQL_PASSWORD=your_very_secure_moodle_password
   MOODLE_ADMIN_PASS=your_very_secure_admin_password
   ```

3. **Network Security**:
   ```bash
   # Restrict access to specific IPs
   # Edit docker-compose.yml to add network restrictions
   ```

4. **Regular Updates**:
   ```bash
   # Update images regularly
   docker-compose pull
   docker-compose up -d
   ```

### Backup Strategy

```bash
#!/bin/bash
# backup.sh - Automated backup script

DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backups"

# Database backup
docker-compose exec mysql mysqldump -u root -p$MYSQL_ROOT_PASSWORD moodle > $BACKUP_DIR/db_$DATE.sql

# Moodle data backup
docker-compose exec moodle tar -czf /var/www/backups/moodledata_$DATE.tar.gz -C /var/www/moodledata .

# Clean old backups (keep last 7 days)
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete
```

## 🚀 Deployment Options

### 1. Local Development

```bash
# Quick start for development
git clone <repository>
cd moodle
cp env.example .env
# Edit .env with your settings
docker-compose --profile development up -d
```

### 2. EC2 Deployment

Use the provided GitHub Actions workflow:

1. **Set up EC2 instance** with Docker and Docker Compose
2. **Configure GitHub secrets**:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `EC2_HOST`
   - `EC2_SSH_KEY`
3. **Push to main/staging** to trigger deployment

### 3. ECS Deployment

Uncomment the ECS deployment section in `.github/workflows/deploy-docker-ec2.yml`:

```yaml
# Create ECS cluster, service, and task definition
# Update environment variables for ECS
```

### 4. Kubernetes Deployment

Create Kubernetes manifests:

```yaml
# moodle-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: moodle
spec:
  replicas: 2
  selector:
    matchLabels:
      app: moodle
  template:
    metadata:
      labels:
        app: moodle
    spec:
      containers:
      - name: moodle
        image: your-registry/moodle:latest
        ports:
        - containerPort: 80
        env:
        - name: DB_HOST
          value: mysql-service
        # ... other environment variables
```

## 🔍 Troubleshooting

### Common Issues

#### 1. Moodle Not Accessible
```bash
# Check if containers are running
docker-compose ps

# Check Moodle logs
docker-compose logs moodle

# Check if port is accessible
curl http://localhost:8080
```

#### 2. Database Connection Issues
```bash
# Check MySQL container
docker-compose logs mysql

# Test database connection
docker-compose exec moodle mysql -h mysql -u moodle -p moodle

# Check environment variables
docker-compose exec moodle env | grep DB_
```

#### 3. Permission Issues
```bash
# Fix permissions
docker-compose exec moodle chown -R moodle:moodle /var/www/html /var/www/moodledata
docker-compose exec moodle chmod -R 755 /var/www/html
docker-compose exec moodle chmod -R 777 /var/www/moodledata
```

#### 4. Performance Issues
```bash
# Check resource usage
docker stats

# Increase PHP memory limit
# Edit .env: PHP_MEMORY_LIMIT=1024M

# Enable Redis caching
# Configure Moodle to use Redis cache
```

### Log Locations

```bash
# Moodle logs
docker-compose logs moodle

# Apache logs
docker-compose exec moodle tail -f /var/log/apache2/error.log

# MySQL logs
docker-compose logs mysql

# Redis logs
docker-compose logs redis
```

## 📊 Monitoring

### Health Checks

```bash
# Check all services
docker-compose ps

# Check specific service health
docker inspect moodle-app | grep Health -A 10

# Custom health check
curl -f http://localhost:8080/ || echo "Moodle is down"
```

### Performance Monitoring

```bash
# Resource usage
docker stats

# Container logs
docker-compose logs -f

# Database performance
docker-compose exec mysql mysql -u root -p -e "SHOW PROCESSLIST;"
```

## 🔄 Updates and Upgrades

### Moodle Updates

```bash
# Pull latest changes
git pull origin main

# Rebuild and restart
docker-compose build moodle
docker-compose up -d moodle

# Run Moodle upgrade
docker-compose exec moodle php /var/www/html/admin/cli/upgrade.php
```

### Docker Image Updates

```bash
# Update all images
docker-compose pull

# Restart with new images
docker-compose up -d

# Clean up old images
docker image prune -f
```

## 📚 Additional Resources

- [Moodle Documentation](https://docs.moodle.org/)
- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [PHP Configuration](https://www.php.net/manual/en/configuration.php)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the GPL-3.0 License - see the [LICENSE](LICENSE) file for details. 