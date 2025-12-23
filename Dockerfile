# Stage 1: Build
FROM python:3.12-slim AS builder
WORKDIR /app
RUN pip install pygbag
COPY . .

# Build the game
RUN python3 -m pygbag --build .

# --- DEBUG STEP ---
# This will print the exact files generated to your Coolify Build Logs
RUN echo "⬇⬇⬇⬇ CHECKING BUILD OUTPUT ⬇⬇⬇⬇" && \
    ls -la /app/build/web && \
    echo "⬆⬆⬆⬆ END BUILD OUTPUT ⬆⬆⬆⬆"

# Stage 2: Serve
FROM nginx:alpine

# Copy the build output
COPY --from=builder /app/build/web /usr/share/nginx/html

# Ensure permissions are correct (sometimes an issue)
RUN chmod -R 755 /usr/share/nginx/html

# Simple Nginx Config
RUN echo 'server { \
    listen 80; \
    root /usr/share/nginx/html; \
    index index.html; \
    \
    add_header Cross-Origin-Opener-Policy same-origin always; \
    add_header Cross-Origin-Embedder-Policy credentialless always; \
    \
    location / { \
        try_files $uri $uri/ =404; \
    } \
    \
    # catch-all for apk files to force correct MIME type \
    location ~ \.apk$ { \
        default_type application/octet-stream; \
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
