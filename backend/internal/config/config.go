package config

import (
	"log"
	"os"

	"github.com/joho/godotenv"
)

type Config struct {
	SupabaseURL        string
	SupabaseKey        string
	SupabaseServiceKey string
	SupabaseStorageURL string // ✅ AGREGADO
	SupabasePassword   string
	Port               string
	JWTSecret          string
}

var AppConfig *Config

func LoadConfig() {
	err := godotenv.Load()
	if err != nil {
		log.Println("Warning: .env file not found")
	}

	AppConfig = &Config{
		SupabaseURL:        getEnv("SUPABASE_URL", ""),
		SupabaseKey:        getEnv("SUPABASE_KEY", ""),
		SupabaseServiceKey: getEnv("SUPABASE_SERVICE_KEY", ""),
		SupabaseStorageURL: getEnv("SUPABASE_STORAGE_URL", ""), // ✅ AGREGADO
		SupabasePassword:   getEnv("SUPABASE_DB_PASSWORD", ""),
		Port:               getEnv("PORT", "8080"),
		JWTSecret:          getEnv("JWT_SECRET", "default-secret"),
	}
}

func getEnv(key, defaultValue string) string {
	value := os.Getenv(key)
	if value == "" {
		return defaultValue
	}
	return value
}
