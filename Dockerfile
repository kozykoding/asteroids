# Stage 1: Build
# FIX: Use the full python image (not slim) to ensure all system libs exist
FROM python:3.12 AS builder

# Install FFMPEG (Still required)
RUN apt-get update && apt-get install -y ffmpeg

# Directory setup
WORKDIR /asteroids

# Install build tool
RUN pip install pygbag

# Copy source
COPY . .

# Clean up any potential artifacts
RUN rm -rf build/web *.apk

# Build
RUN python3 -m pygbag --build .

# Stage 2: Serve
FROM nginx:alpine

# Copy the build output
COPY --from=builder /asteroids/build/web /usr/share/nginx/html

# Nginx Config
RUN echo 'server { \
    listen 80; \
    root /usr/share/nginx/html; \
    index index.html; \
    \
    # HEADERS \
    add_header Cross-Origin-Opener-Policy same-origin always; \
    add_header Cross-Origin-Embedder-Policy credentialless always; \
    \
    location / { \
        try_files $uri $uri/ =404; \
    } \
    \
    # Fix for file name mismatch \
    location ~ \.apk$ { \
        default_type application/octet-stream; \
        # If the browser asks for app.apk but we have asteroids.apk (or vice versa), \
        # we try to serve what exists. \
        try_files $uri /asteroids.apk /app.apk =404; \
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
