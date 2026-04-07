#!/bin/bash
# entrypoint.sh

echo "Starting container in $ENV mode..."

if [ "$ENV" = "staging" ]; then
    echo "Installing staging requirements..."
    pip install --no-cache-dir -r requirements-stg.txt
else
    echo "Using production environment..."
fi

exec "$@"