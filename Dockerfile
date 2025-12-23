# Stage 1: Build
FROM python:3.12-slim AS builder
WORKDIR /app
RUN pip install pygbag
COPY . .
# Force the archive name to be 'asteroids' to match what we expect
# running without --build just prepares the folder, then we run the main build
RUN python3 -m pygbag --archive asteroids --build $PWD

# Stage 2: Serve
FROM nginx:alpine

# Copy the build output
# Pygbag outputs to /app/build/web
COPY --from=builder /app/build/web /usr/share/nginx/html

# Create a simple, embedded Nginx config dynamically
# This ensures we have the headers without managing a separate file
RUN echo 'server { \
    listen 80; \
    root /usr/share/nginx/html; \
    index index.html; \
    \
    # SECURITY HEADERS (Mandatory) \
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
