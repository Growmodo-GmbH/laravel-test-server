#!/bin/sh

export EVENT_NAME=$1
export BRANCH=$2
# Add local .env
if [ -f .env ]; then
    export $(echo $(cat .env | sed 's/#.*//g'| xargs) | envsubst)
fi

if [ ! -d "$INIT_DIR/$BRANCH" ]; then
    exit 0;
fi

cd "$INIT_DIR/$BRANCH"

set -e

echo "Running actions..."

# Add application .env
if [ -f .env ]; then
    export $(echo $(cat .env | sed 's/#.*//g'| xargs) | envsubst)
fi

# Delete Action
if [ "$EVENT_NAME" = "delete" ]; then
    echo "Deleting application..."
    # Maintenance mode
    (php artisan down) || true
    # Delete database
    php artisan tinker --execute="(new PDO('mysql:host=' . env('DB_HOST'), env('DB_USERNAME'), env('DB_PASSWORD')))->exec('DROP DATABASE \`' . env('DB_DATABASE') . '\`')"
    cd ../ && rm -rf $BRANCH
fi

echo "Done!"

