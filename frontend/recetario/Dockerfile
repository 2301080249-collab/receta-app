FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

# Copiar archivos de configuración
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copiar todo el código
COPY . .

# Compilar para web (simple, sin opciones extras)
RUN flutter build web --release

# Stage 2: Servir con nginx
FROM nginx:alpine

# Copiar archivos compilados
COPY --from=build /app/build/web /usr/share/nginx/html

# Configurar nginx para puerto 10000
RUN echo 'server { \
    listen 10000; \
    location / { \
        root /usr/share/nginx/html; \
        index index.html; \
        try_files $uri $uri/ /index.html; \
    } \
}' > /etc/nginx/conf.d/default.conf

EXPOSE 10000

CMD ["nginx", "-g", "daemon off;"]