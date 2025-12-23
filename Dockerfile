# Stage 1: Build
FROM python:3.12-slim AS builder
WORKDIR /app
RUN pip install pygbag
COPY . .

# Build
RUN python3 -m pygbag --build .

# Stage 2: Serve
FROM nginx:alpine

# Copy the build output
COPY --from=builder /app/build/web /usr/share/nginx/html

# This solves the "loader asks for X but file is Y" problem instantly
RUN cp /usr/share/nginx/html/*.apk /usr/share/nginx/html/app.apk || true
RUN cp /usr/share/nginx/html/*.apk /usr/share/nginx/html/asteroids.apk || true

# Simple Nginx Config with Headers
RUN echo 'server { \
    listen 80; \
    root /usr/share/nginx/html; \
    index index.html; \
    \
    # SECURITY HEADERS \
    add_header Cross-Origin-Opener-Policy same-origin always; \
    add_header Cross-Origin-Embedder-Policy credentialless always; \
    \
    location / { \
        try_files $uri $uri/ =404; \
    } \
    \
    include /etc/nginx/mime.types; \
    types { \
        application/wasm wasm; \
        application/octet-stream apk; \
    } \
}' > /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
