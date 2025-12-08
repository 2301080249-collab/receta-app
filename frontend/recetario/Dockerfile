FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

# Copiar archivos de configuración
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copiar todo el código
COPY . .

# ✅ Las variables se pasan como argumentos desde Render
ARG API_URL
ARG SUPABASE_URL
ARG SUPABASE_ANON_KEY

# Compilar con variables inyectadas
RUN flutter build web --release \
    --dart-define=API_URL=${API_URL} \
    --dart-define=SUPABASE_URL=${SUPABASE_URL} \
    --dart-define=SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}

# Stage 2: Servir con nginx
FROM nginx:alpine

COPY --from=build /app/build/web /usr/share/nginx/html

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