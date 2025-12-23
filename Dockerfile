# Stage 1: Build
FROM python:3.12-slim AS builder
WORKDIR /app
RUN pip install pygbag
COPY . .

# 1. Standard build (This works, but might output 'app.apk' or 'asteroids.apk')
RUN python3 -m pygbag --build .

# 2. Force-rename APK was generated to 'game.apk'
RUN find build/web -name "*.apk" -exec mv {} build/web/game.apk \;

# Stage 2: Serve
FROM nginx:alpine

# Copy the build output
COPY --from=builder /app/build/web /usr/share/nginx/html

# Create Nginx Config
# "If the browser asks for ANY .apk file, give it game.apk"
RUN echo 'server { \
    listen 80; \
    root /usr/share/nginx/html; \
    index index.html; \
    \
    # REQUIRED HEADERS \
    add_header Cross-Origin-Opener-Policy same-origin always; \
    add_header Cross-Origin-Embedder-Policy credentialless always; \
    \
    location / { \
        try_files $uri $uri/ =404; \
    } \
    \
    # THE MAGIC FIX: \
    # The javascript might ask for "app.apk" or "asteroids.apk". \
    # We ignore the name and just serve the actual file we renamed to "game.apk". \
    location ~ \.apk$ { \
        alias /usr/share/nginx/html/game.apk; \
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
