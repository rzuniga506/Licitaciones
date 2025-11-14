# Flutter Frontend Dockerfile
FROM cirrusci/flutter:stable

# Set working directory
WORKDIR /app

# Copy pubspec files
COPY pubspec.yaml pubspec.lock ./

# Get dependencies
RUN flutter pub get

# Copy application code
COPY . .

# Enable web
RUN flutter config --enable-web

# Build for web
RUN flutter build web --release

# Use nginx to serve the app
FROM nginx:alpine

# Copy built web app to nginx
COPY --from=0 /app/build/web /usr/share/nginx/html

# Copy nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
