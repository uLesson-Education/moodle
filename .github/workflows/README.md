# GitHub Actions EC2 Deployment Setup

This directory contains GitHub Actions workflows for deploying Moodle to AWS EC2 instances.

## Workflows

### `deploy-to-ec2.yml`
Deploys Moodle to an EC2 instance with automatic backups, proper permissions, and health checks.

## Setup Instructions

### 1. AWS EC2 Instance Setup

1. **Launch an EC2 instance** with Ubuntu 20.04 or later
2. **Configure Security Groups** to allow:
   - SSH (port 22) from your IP
   - HTTP (port 80) from anywhere
   - HTTPS (port 443) from anywhere
3. **Install LAMP Stack**:
   ```bash
   sudo apt update
   sudo apt install apache2 mysql-server php php-mysql php-xml php-mbstring php-curl php-gd php-zip unzip
   ```

### 2. GitHub Repository Secrets

Add the following secrets to your GitHub repository (`Settings > Secrets and variables > Actions`):

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `AWS_ACCESS_KEY_ID` | AWS Access Key ID | `AKIAIOSFODNN7EXAMPLE` |
| `AWS_SECRET_ACCESS_KEY` | AWS Secret Access Key | `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY` |
| `EC2_HOST` | EC2 instance public IP or domain | `54.123.45.67` or `moodle.yourdomain.com` |
| `EC2_SSH_KEY` | Private SSH key for EC2 access | Content of your `.pem` file |

### 3. SSH Key Setup

1. **Generate SSH key pair** (if you don't have one):
   ```bash
   ssh-keygen -t rsa -b 4096 -C "your-email@example.com"
   ```

2. **Add public key to EC2 instance**:
   ```bash
   # Copy your public key content
   cat ~/.ssh/id_rsa.pub
   
   # On EC2 instance, add to authorized_keys
   echo "your-public-key-content" >> ~/.ssh/authorized_keys
   ```

3. **Add private key to GitHub secrets**:
   - Copy the content of your private key file (`~/.ssh/id_rsa`)
   - Add it as the `EC2_SSH_KEY` secret in GitHub

### 4. AWS IAM User Setup

Create an IAM user with the following permissions:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeInstances",
                "ec2:DescribeInstanceStatus"
            ],
            "Resource": "*"
        }
    ]
}
```

### 5. Moodle Configuration

1. **Create `config.php`** on your EC2 instance:
   ```php
   <?php
   unset($CFG);
   global $CFG;
   $CFG = new stdClass();
   
   $CFG->dbtype    = 'mysqli';
   $CFG->dblibrary = 'native';
   $CFG->dbhost    = 'localhost';
   $CFG->dbname    = 'moodle';
   $CFG->dbuser    = 'moodle_user';
   $CFG->dbpass    = 'your_password';
   $CFG->prefix    = 'mdl_';
   $CFG->dboptions = array(
       'dbpersist' => 0,
       'dbport' => '',
       'dbsocket' => '',
       'dbcollation' => 'utf8mb4_unicode_ci',
   );
   
   $CFG->wwwroot   = 'http://your-domain.com';
   $CFG->dataroot  = '/var/www/html/moodledata';
   $CFG->admin     = 'admin';
   
   $CFG->directorypermissions = 02777;
   
   require_once(__DIR__ . '/lib/setup.php');
   ```

2. **Create MySQL database**:
   ```sql
   CREATE DATABASE moodle CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
   CREATE USER 'moodle_user'@'localhost' IDENTIFIED BY 'your_password';
   GRANT ALL PRIVILEGES ON moodle.* TO 'moodle_user'@'localhost';
   FLUSH PRIVILEGES;
   ```

### 6. Customization

#### Environment Variables
- Update `AWS_REGION` in the workflow file to match your region
- Modify `DEPLOY_PATH` in the deployment script if needed

#### Deployment Triggers
The workflow triggers on:
- Push to `main` branch
- Push to `staging` branch
- Manual workflow dispatch

#### Backup Strategy
- Automatic backups are created before each deployment
- Backups are stored in `/var/www/backups/`
- Backup files are named with timestamps

## Usage

### Automatic Deployment
Push to `main` or `staging` branches to trigger automatic deployment.

### Manual Deployment
1. Go to `Actions` tab in GitHub
2. Select `Deploy Moodle to EC2` workflow
3. Click `Run workflow`
4. Choose environment (staging/production)
5. Click `Run workflow`

## Troubleshooting

### Common Issues

1. **SSH Connection Failed**
   - Verify EC2 instance is running
   - Check security group allows SSH from GitHub Actions
   - Ensure SSH key is correctly added to GitHub secrets

2. **Permission Denied**
   - Verify `www-data` user exists on EC2
   - Check file permissions after deployment

3. **Health Check Failed**
   - Verify web server is running
   - Check Apache/Nginx configuration
   - Ensure Moodle is properly configured

### Logs
- Check GitHub Actions logs for detailed error messages
- SSH into EC2 instance to check web server logs:
  ```bash
  sudo tail -f /var/log/apache2/error.log
  sudo tail -f /var/log/nginx/error.log
  ```

## Security Considerations

1. **Use HTTPS** in production
2. **Regular security updates** for EC2 instance
3. **Database backups** outside of deployment backups
4. **Monitor access logs** for suspicious activity
5. **Use AWS Secrets Manager** for sensitive data in production

## Support

For issues with this workflow, check:
1. GitHub Actions documentation
2. AWS EC2 documentation
3. Moodle installation documentation 