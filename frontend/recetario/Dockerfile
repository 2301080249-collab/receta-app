FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

COPY pubspec.* ./
RUN flutter pub get

COPY . .

# ✅ Copiar .env de producción
COPY .env.production .env

RUN flutter build web --release --web-renderer html

FROM nginx:alpine

COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]