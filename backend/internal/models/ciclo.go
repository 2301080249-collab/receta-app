package models

import "time"

// Ciclo representa un ciclo académico (2024-I, 2024-II, etc.)
type Ciclo struct {
	ID              string    `json:"id"`
	Nombre          string    `json:"nombre"`           // "2024-I", "2024-II"
	FechaInicio     string    `json:"fecha_inicio"`     // "2024-03-01"
	FechaFin        string    `json:"fecha_fin"`        // "2024-06-15"
	DuracionSemanas int       `json:"duracion_semanas"` // 16
	Activo          bool      `json:"activo"`           // true/false
	CreatedAt       time.Time `json:"created_at"`
}

// CrearCicloRequest representa los datos para crear un ciclo
type CrearCicloRequest struct {
	Nombre          string `json:"nombre" validate:"required"`
	FechaInicio     string `json:"fecha_inicio" validate:"required"`
	FechaFin        string `json:"fecha_fin" validate:"required"`
	DuracionSemanas int    `json:"duracion_semanas" validate:"required,min=1,max=52"`
}

// ActualizarCicloRequest representa los datos para actualizar un ciclo
type ActualizarCicloRequest struct {
	Nombre          *string `json:"nombre,omitempty"`
	FechaInicio     *string `json:"fecha_inicio,omitempty"`
	FechaFin        *string `json:"fecha_fin,omitempty"`
	DuracionSemanas *int    `json:"duracion_semanas,omitempty"`
	Activo          *bool   `json:"activo,omitempty"`
}
