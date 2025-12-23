# Stage 1: Build
FROM python:3.12-slim AS builder

# 1. FIX: Use a directory name that matches your game name
# This forces pygbag to name the archive 'asteroids.apk' automatically
WORKDIR /asteroids

RUN pip install pygbag

# Copy source code
COPY . .

# 2. Clean up any leftover builds/APKs from local testing so they don't confuse the build
RUN rm -rf build/web *.apk

# 3. Build using the folder name defaults
RUN python3 -m pygbag --build .

# Stage 2: Serve
FROM nginx:alpine

# Copy the build output
COPY --from=builder /asteroids/build/web /usr/share/nginx/html

# Create Nginx Config (Standardized)
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
    # Helper for mime types \
    include /etc/nginx/mime.types; \
    types { \
        application/wasm wasm; \
        application/octet-stream apk; \
    } \
}' > /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
