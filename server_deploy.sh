#!/bin/sh

export BRANCH=$1
export DEPLOY=$2
export REPO=$3
export DEPLOY_HOST="http://test.growmodo.com/$BRANCH/public"
export EXEC_FILE='commands.sh'
export DB_DEFAULT="laravel-test"
# Add local .env
if [ -f .env ]; then
    export $(echo $(cat .env | sed 's/#.*//g'| xargs) | envsubst)
fi

(git clone --branch $DEPLOY $REPO $INIT_DIR/$BRANCH) || echo ""
pwd
cd "$INIT_DIR/$BRANCH"
pwd
set -e

echo "Deploying application..."

# Enter maintenance mode
(php artisan down) || true
    # Update codebase
    git fetch origin $DEPLOY
    git reset --hard origin/$DEPLOY
    
    # Add application .env
    if [ -f .env ]; then
        export $(echo $(cat .env | sed 's/#.*//g'| xargs) | envsubst)
    fi

    # Install dependencies based on lock file
    composer install --no-interaction --prefer-dist --optimize-autoloader

    # Create database
    [ "$DB_DATABSE" = "$DB_DEFAULT" ] && php artisan tinker --execute="(new PDO('mysql:host=' . env('DB_HOST'), env('DB_USERNAME'), env('DB_PASSWORD')))->exec('CREATE DATABASE \`' . env('DB_DATABASE') . '\`')"

    # Migrate database
    php artisan migrate --force

    # Note: If you're using queue workers, this is the place to restart them.
    # ...
    if [ -f $EXEC_FILE ]; then
        (chmod +x $EXEC_FILE) || echo ""
        (./$EXEC_FILE) || echo "Warning: Commands Failed!"
    fi

    # Clear cache
    php artisan optimize:clear

    # Reload PHP to update opcache
    echo "" | sudo -S service php8.1-fpm reload | echo ""
# Exit maintenance mode

php artisan up

echo "Application deployed!"
echo ""
echo "URL: $DEPLOY_HOST"
