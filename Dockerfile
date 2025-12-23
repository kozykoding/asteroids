# Stage 1: Build
FROM python:3.12-slim AS builder
WORKDIR /app
RUN pip install pygbag
COPY . .

# Build standard
RUN python3 -m pygbag --build .

# DEBUG: List what was actually built to the build logs
RUN echo "--- LISTING BUILD OUPUT ---" && ls -la build/web

# Stage 2: Serve
FROM nginx:alpine

# Copy files
COPY --from=builder /app/build/web /usr/share/nginx/html

# Overwrite index.html temporarily
RUN mv /usr/share/nginx/html/index.html /usr/share/nginx/html/game.html

# Create Debug Nginx Config
RUN echo 'server { \
    listen 80; \
    root /usr/share/nginx/html; \
    index game.html; \
    \
    # ENABLE DIRECTORY LISTING (For Debugging) \
    autoindex on; \
    \
    # HEADERS \
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
