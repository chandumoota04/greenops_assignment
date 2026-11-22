FROM node:22-alpine AS build
WORKDIR /src
COPY web/package.json web/package-lock.json ./
RUN npm ci
COPY web/ .
RUN npm run build

FROM nginx:1.28-alpine
COPY --from=build /src/dist /opt/surplus-food/current/web
# The EC2 site config talks to 127.0.0.1; in Docker the API is the "api" service.
COPY infra/nginx/surplus-food.conf /tmp/site.conf
RUN sed 's#http://127.0.0.1:8080#http://api:8080#' /tmp/site.conf > /etc/nginx/conf.d/default.conf && rm /tmp/site.conf
