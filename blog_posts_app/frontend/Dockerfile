FROM node:22-alpine AS build

WORKDIR /app

ARG NODE_ENV=development

COPY package*.json ./

RUN if [ "$NODE_ENV" = "production" ]; then \
      npm ci --omit=dev; \
    else \
      npm ci; \
    fi

COPY src/ ./src
COPY public/ ./public
COPY index.html vite.config.ts tsconfig.json tsconfig.app.json tsconfig.node.json ./

RUN npx vite build --mode ${NODE_ENV}

# Serve via Nginx
FROM nginxinc/nginx-unprivileged:stable-alpine

COPY default.conf.template /etc/nginx/templates/default.conf.template

COPY config.js.template /etc/nginx/templates/config.js.template

COPY --from=build /app/dist /usr/share/nginx/html

USER root

RUN chown -R 10005:10005 /usr/share/nginx/html

HEALTHCHECK --interval=30s --timeout=5s --start-period=3s --retries=3 \
  CMD curl -f http://localhost:80/ || exit 1

EXPOSE 8080

USER 10005