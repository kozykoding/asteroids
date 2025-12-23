# Stage 1: Build the game
FROM python:3.12-slim AS builder
WORKDIR /app

# Install pygbag
RUN pip install pygbag

# Copy source code
COPY . .

# Build (generates build/web folder)
RUN pygbag --build . 

# Stage 2: Serve with Nginx
FROM nginx:alpine

# Copy the built files to Nginx
COPY --from=builder /app/build/web /usr/share/nginx/html

# Add custom Nginx config for Headers (Create this file too!)
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
