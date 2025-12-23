# Stage 1: Build
FROM python:3.12-slim AS builder
WORKDIR /app
RUN pip install pygbag
COPY . .

# Explicitly name the archive 'asteroids'
RUN python3 -m pygbag --archive asteroids --build $PWD

# Stage 2: Serve
FROM nginx:alpine

# Copy the build output
COPY --from=builder /app/build/web /usr/share/nginx/html

# Explicitly handle the /asteroids.apk path to be safe
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
    # Handle both common names just in case the loader is confused \
    location = /app.apk { \
        try_files /asteroids.apk =404; \
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
