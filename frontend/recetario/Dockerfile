FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .

# ✅ VALORES DIRECTOS (sin variables)
RUN flutter build web --release \
    --dart-define=API_URL=https://receta-backend.onrender.com \
    --dart-define=SUPABASE_URL=https://mqwaijsnybindsxvgjss.supabase.co \
    --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1xd2FpanNueWJpbmRzeHZnanNzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkxNzQyMDksImV4cCI6MjA3NDc1MDIwOX0.sR_W-Nc1-qoisLUBJWR16PpZ8uRj693CgtBK1jVg1N8 \
    --dart-define=GEMINI_API_KEY=AIzaSyBiKWJ9fvVSo43Pl57eNWXVPHMTh8Vu87Q

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