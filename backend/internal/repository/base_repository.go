package repository

import (
	"database/sql"
	"fmt"

	"recetario-backend/internal/config"

	_ "github.com/lib/pq"
)

// BaseRepository contiene la conexión SQL a PostgreSQL
type BaseRepository struct {
	db *sql.DB
}

// NewSupabaseSQLClient crea una conexión directa a PostgreSQL de Supabase
func NewSupabaseSQLClient() (*sql.DB, error) {
	// Construir connection string de PostgreSQL
	connStr := fmt.Sprintf(
		"host=%s port=5432 user=postgres password=%s dbname=postgres sslmode=require",
		extractHostFromURL(config.AppConfig.SupabaseURL),
		config.AppConfig.SupabasePassword, // Necesitas agregar esto
	)

	db, err := sql.Open("postgres", connStr)
	if err != nil {
		return nil, fmt.Errorf("error abriendo conexión: %w", err)
	}

	// Verificar conexión
	if err := db.Ping(); err != nil {
		return nil, fmt.Errorf("error conectando a la base de datos: %w", err)
	}

	// Configurar pool de conexiones
	db.SetMaxOpenConns(25)
	db.SetMaxIdleConns(5)

	return db, nil
}

// NewBaseRepository crea una nueva instancia de BaseRepository
func NewBaseRepository(db *sql.DB) *BaseRepository {
	return &BaseRepository{
		db: db,
	}
}

// Extraer host de URL de Supabase
func extractHostFromURL(url string) string {
	// Ejemplo: https://xxxxx.supabase.co -> xxxxx.supabase.co
	url = url[8:] // Quitar "https://"
	return url
}
