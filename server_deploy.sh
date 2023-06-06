#!/bin/sh

export BRANCH=$1
export DEPLOY=$2
export REPO=$3
export DEPLOY_HOST="https://test.growmodo.dev/$BRANCH/public/"
export EXEC_FILE="commands.sh"
export DB_DEFAULT="laravel-test"
# Add local .env
if [ -f .env ]; then
    export $(echo $(cat .env | sed 's/#.*//g'| xargs) | envsubst)
fi

(git clone --branch $DEPLOY $REPO $INIT_DIR/$BRANCH) || echo ""

cd "$INIT_DIR/$BRANCH"

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
    if [ "$DB_DATABASE" != "$DB_DEFAULT" -a "$DB_DATABASE" != "" ]; then
        php artisan tinker --execute="(new PDO('mysql:host=' . env('DB_HOST'), env('DB_USERNAME'), env('DB_PASSWORD')))->exec('CREATE DATABASE \`' . env('DB_DATABASE') . '\`')"
    fi
    
    # Migrate database
    php artisan migrate --force

    # Note: If you're want to run other commands, place here
    if [ -f $EXEC_FILE ]; then
        (chmod +x $EXEC_FILE) || echo ""
        (./$EXEC_FILE) || echo "Warning: Commands Failed!"
    fi

    # Clear cache
    php artisan optimize:clear
# Exit maintenance mode

php artisan up

echo "Application deployed!"
echo ""
echo "URL: $DEPLOY_HOST"
