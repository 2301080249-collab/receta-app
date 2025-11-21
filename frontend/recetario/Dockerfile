FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

# Copiar solo archivos de dependencias primero (para cache)
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copiar el resto del código
COPY . .

# Compilar con opciones optimizadas para Render
RUN flutter build web \
    --release \
    --no-tree-shake-icons \
    --dart-define=FLUTTER_WEB_USE_SKIA=false

# Imagen final más ligera
FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html

# Configuración de nginx
RUN echo 'server { listen 80; location / { root /usr/share/nginx/html; try_files $uri $uri/ /index.html; } }' > /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]