FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

# Declarar build arguments
ARG BACKEND_URL
ARG SUPABASE_URL
ARG SUPABASE_KEY
ARG SUPABASE_ANON_KEY
ARG ENVIRONMENT
ARG CONNECTION_TIMEOUT
ARG GEMINI_API_KEY

# Copiar archivos de configuración
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copiar todo el código
COPY . .

# ✅ CREAR .env desde build arguments
RUN echo "BACKEND_URL=${BACKEND_URL}" > .env && \
    echo "SUPABASE_URL=${SUPABASE_URL}" >> .env && \
    echo "SUPABASE_KEY=${SUPABASE_KEY}" >> .env && \
    echo "SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}" >> .env && \
    echo "ENVIRONMENT=${ENVIRONMENT}" >> .env && \
    echo "CONNECTION_TIMEOUT=${CONNECTION_TIMEOUT}" >> .env && \
    echo "GEMINI_API_KEY=${GEMINI_API_KEY}" >> .env

# Verificar que se creó correctamente
RUN cat .env

# Compilar para web
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