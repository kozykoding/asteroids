# Stage 1: Build
FROM python:3.12-slim AS builder

# 1. INSTALL FFMPEG (Required for Pygbag build)
RUN apt-get update && apt-get install -y ffmpeg

# 2. Use directory name matching your game
WORKDIR /asteroids

RUN pip install pygbag
COPY . .

# 3. Clean up & Build
RUN rm -rf build/web *.apk
RUN python3 -m pygbag --build .

# Stage 2: Serve
FROM nginx:alpine

# Copy the build output
COPY --from=builder /asteroids/build/web /usr/share/nginx/html

# Create Nginx Config
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
