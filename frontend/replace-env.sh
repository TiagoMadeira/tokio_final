#!/bin/sh
# This script will now be run automatically by the official Nginx entrypoint
find /usr/share/nginx/html/assets -name "*.js" -exec sed -i "s|REPLACE_VITE_OTEL_SERVICE_NAME|$VITE_OTEL_SERVICE_NAME|g" {} +