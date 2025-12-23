# Stage 1: Build the Game
FROM python:3.12 AS builder

# 1. Install system dependencies (Fixes 'ffmpeg not found')
RUN apt-get update && \
    apt-get install -y ffmpeg && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 2. Install Pygbag
RUN pip install --no-cache-dir pygbag

# 3. Copy source code
COPY . .

# 4. Clean up any local build artifacts copied over
RUN rm -rf build

# 5. PRE-CREATE the output directory (Fixes 'FileNotFoundError')
RUN mkdir -p build/web

# 6. Build the game
RUN python3 -m pygbag --build .

# 7. Force-rename the APK to 'game.apk'
# This guarantees Nginx finds it, whether Pygbag calls it 'app.apk' or 'asteroids.apk'
RUN find build/web -name "*.apk" -exec mv {} build/web/game.apk \;

# Stage 2: Serve with Nginx
FROM nginx:alpine

# Copy the built web files
COPY --from=builder /app/build/web /usr/share/nginx/html

# Create Nginx Config
# Notice we serve 'game.apk' regardless of what the browser asks for
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
    # MAGIC FIX: Serve game.apk for ANY apk request \
    location ~ \.apk$ { \
        default_type application/octet-stream; \
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
