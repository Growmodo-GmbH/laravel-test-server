#!/bin/sh

export BRANCH=$1
export REPO=$2

echo "Updating server..."

git fetch origin $BRANCH
git reset --hard origin/$BRANCH

echo "Done!"
