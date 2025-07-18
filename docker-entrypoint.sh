#!/bin/bash
set -e

# Function to wait for database
wait_for_db() {
    echo "Waiting for database connection..."
    while ! mysqladmin ping -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASS" --silent; do
        sleep 2
    done
    echo "Database is ready!"
}

# Function to create config.php
create_config() {
    if [ ! -f /var/www/html/config.php ]; then
        echo "Creating Moodle configuration..."
        cat > /var/www/html/config.php << EOF
<?php
unset(\$CFG);
global \$CFG;
\$CFG = new stdClass();

\$CFG->dbtype    = 'mysqli';
\$CFG->dblibrary = 'native';
\$CFG->dbhost    = '${DB_HOST}';
\$CFG->dbname    = '${DB_NAME}';
\$CFG->dbuser    = '${DB_USER}';
\$CFG->dbpass    = '${DB_PASS}';
\$CFG->prefix    = 'mdl_';
\$CFG->dboptions = array(
    'dbpersist' => 0,
    'dbport' => '${DB_PORT}',
    'dbsocket' => '',
    'dbcollation' => 'utf8mb4_unicode_ci',
);

\$CFG->wwwroot   = '${MOODLE_URL}';
\$CFG->dataroot  = '/var/www/moodledata';
\$CFG->admin     = 'admin';

\$CFG->directorypermissions = 02777;

require_once(__DIR__ . '/lib/setup.php');
EOF
        echo "Configuration created successfully!"
    else
        echo "Configuration file already exists."
    fi
}

# Function to install Moodle
install_moodle() {
    if [ ! -f /var/www/moodledata/installed ]; then
        echo "Installing Moodle..."
        
        # Create database if it doesn't exist
        mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASS" -e "CREATE DATABASE IF NOT EXISTS \`$DB_NAME\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
        
        # Run Moodle installation
        php /var/www/html/admin/cli/install.php \
            --non-interactive \
            --agree-license \
            --wwwroot="$MOODLE_URL" \
            --dataroot=/var/www/moodledata \
            --dbtype=mysqli \
            --dbhost="$DB_HOST" \
            --dbname="$DB_NAME" \
            --dbuser="$DB_USER" \
            --dbpass="$DB_PASS" \
            --dbport="$DB_PORT" \
            --prefix=mdl_ \
            --fullname="$MOODLE_FULLNAME" \
            --shortname="$MOODLE_SHORTNAME" \
            --adminuser="$MOODLE_ADMIN_USER" \
            --adminpass="$MOODLE_ADMIN_PASS" \
            --adminemail="$MOODLE_ADMIN_EMAIL"
        
        # Mark as installed
        touch /var/www/moodledata/installed
        echo "Moodle installation completed!"
    else
        echo "Moodle is already installed."
    fi
}

# Function to upgrade Moodle
upgrade_moodle() {
    if [ -f /var/www/moodledata/installed ]; then
        echo "Checking for Moodle upgrades..."
        php /var/www/html/admin/cli/upgrade.php --non-interactive
        echo "Moodle upgrade check completed!"
    fi
}

# Function to set permissions
set_permissions() {
    echo "Setting proper permissions..."
    chown -R moodle:moodle /var/www/html /var/www/moodledata /var/www/backups
    chmod -R 755 /var/www/html
    chmod -R 777 /var/www/moodledata
    find /var/www/html -type f -exec chmod 644 {} \;
    find /var/www/html -type d -exec chmod 755 {} \;
}

# Main execution
main() {
    echo "Starting Moodle container..."
    
    # Set default values if not provided
    export DB_HOST=${DB_HOST:-mysql}
    export DB_PORT=${DB_PORT:-3306}
    export DB_NAME=${DB_NAME:-moodle}
    export DB_USER=${DB_USER:-moodle}
    export DB_PASS=${DB_PASS:-moodle}
    export MOODLE_URL=${MOODLE_URL:-http://localhost}
    export MOODLE_FULLNAME=${MOODLE_FULLNAME:-"My Moodle Site"}
    export MOODLE_SHORTNAME=${MOODLE_SHORTNAME:-"moodle"}
    export MOODLE_ADMIN_USER=${MOODLE_ADMIN_USER:-admin}
    export MOODLE_ADMIN_PASS=${MOODLE_ADMIN_PASS:-admin}
    export MOODLE_ADMIN_EMAIL=${MOODLE_ADMIN_EMAIL:-admin@example.com}
    
    # Wait for database
    wait_for_db
    
    # Create configuration
    create_config
    
    # Install or upgrade Moodle
    if [ -f /var/www/moodledata/installed ]; then
        upgrade_moodle
    else
        install_moodle
    fi
    
    # Set permissions
    set_permissions
    
    # Clear cache
    echo "Clearing cache..."
    rm -rf /var/www/moodledata/cache/*
    rm -rf /var/www/moodledata/temp/*
    
    echo "Moodle container is ready!"
    
    # Execute the main command
    exec "$@"
}

# Run main function
main "$@" 