# Stage 1: Build
FROM python:3.12 AS builder

# 1. Install dependencies
RUN apt-get update && \
    apt-get install -y ffmpeg && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN pip install pygbag
COPY . .

# 2. Build (Standard /app directory, produces app.apk)
RUN rm -rf build/web *.apk
RUN python3 -m pygbag --build .

# 3. CRITICAL: Create copies for every possible name the loader might ask for
# This solves the 404s/mismatches once and for all.
RUN cp build/web/*.apk build/web/app.apk || true
RUN cp build/web/*.apk build/web/asteroids.apk || true
RUN cp build/web/*.apk build/web/game.apk || true

# Stage 2: Serve
FROM nginx:alpine

# Copy the build output
COPY --from=builder /app/build/web /usr/share/nginx/html

# 4. Standard Nginx Config (No Alias Hacks)
# We removed the 'location /asteroids' and 'location = /apk' hacks.
# Since we copied the files to match the names, standard serving works.
RUN echo 'server { \
    listen 80; \
    root /usr/share/nginx/html; \
    index index.html; \
    \
    # SECURITY HEADERS (Mandatory) \
    add_header Cross-Origin-Opener-Policy same-origin always; \
    add_header Cross-Origin-Embedder-Policy credentialless always; \
    \
    # Standard file serving \
    location / { \
        try_files $uri $uri/ =404; \
    } \
    \
    # Force MIME types \
    include /etc/nginx/mime.types; \
    types { \
        application/wasm wasm; \
        application/octet-stream apk; \
    } \
}' > /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
