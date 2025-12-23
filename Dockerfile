# Stage 1: Build
FROM python:3.12 AS builder

# 1. Install dependencies
RUN apt-get update && \
    apt-get install -y ffmpeg && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN pip install pygbag
COPY . .

# 2. CLEAN & PREPARE
# Remove old builds
RUN rm -rf build/web *.apk

# Create the directory structure manually to prevent FileNotFoundError
RUN mkdir -p /app/build/web

# 3. BUILD
# We use the specific --app_name argument to force the output name
RUN python3 -m pygbag --app_name asteroids --build $PWD

# 4. SAFETY COPY
# Create copies for every possible name (app.apk, asteroids.apk, game.apk)
# This prevents the 404 issue if the loader asks for a different name
RUN cp build/web/*.apk build/web/app.apk || true
RUN cp build/web/*.apk build/web/asteroids.apk || true
RUN cp build/web/*.apk build/web/game.apk || true

# Stage 2: Serve
FROM nginx:alpine

# Copy the build output
COPY --from=builder /app/build/web /usr/share/nginx/html

# 5. NGINX CONFIG
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
    # MIME TYPES \
    include /etc/nginx/mime.types; \
    types { \
        application/wasm wasm; \
        application/octet-stream apk; \
    } \
}' > /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
