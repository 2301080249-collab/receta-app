package models

import (
	"time"

	"github.com/google/uuid"
)

type Material struct {
	ID              uuid.UUID `json:"id" db:"id"`
	TemaID          uuid.UUID `json:"tema_id" db:"tema_id"`
	Titulo          string    `json:"titulo" db:"titulo"`
	Tipo            string    `json:"tipo" db:"tipo"` // pdf, video, link, documento, imagen
	URLArchivo      string    `json:"url_archivo" db:"url_archivo"`
	TamanoMB        *float64  `json:"tamano_mb,omitempty" db:"tamano_mb"`
	DuracionMinutos *int      `json:"duracion_minutos,omitempty" db:"duracion_minutos"`
	Descripcion     *string   `json:"descripcion,omitempty" db:"descripcion"`
	Orden           int       `json:"orden" db:"orden"`
	Activo          bool      `json:"activo" db:"activo"`
	CreatedAt       time.Time `json:"created_at" db:"created_at"`

	// Para estudiante
	VistoPorMi bool `json:"visto_por_mi,omitempty"`

	// Para docente
	CantidadVistos   int `json:"cantidad_vistos,omitempty"`
	TotalEstudiantes int `json:"total_estudiantes,omitempty"`
}

type CreateMaterialRequest struct {
	TemaID          uuid.UUID `json:"tema_id" binding:"required"`
	Titulo          string    `json:"titulo" binding:"required"`
	Tipo            string    `json:"tipo" binding:"required,oneof=pdf video link documento imagen"`
	URLArchivo      string    `json:"url_archivo" binding:"required"`
	TamanoMB        *float64  `json:"tamano_mb"`
	DuracionMinutos *int      `json:"duracion_minutos"`
	Descripcion     *string   `json:"descripcion"`
	Orden           int       `json:"orden" binding:"required,min=1"`
}

type MaterialVisto struct {
	ID           uuid.UUID `json:"id" db:"id"`
	MaterialID   uuid.UUID `json:"material_id" db:"material_id"`
	EstudianteID uuid.UUID `json:"estudiante_id" db:"estudiante_id"`
	VistoEn      time.Time `json:"visto_en" db:"visto_en"`
}

// ✅ AGREGAR ESTE STRUCT A backend/internal/models/material.go

type UpdateMaterialRequest struct {
	Titulo      *string  `json:"titulo,omitempty"`
	Tipo        *string  `json:"tipo,omitempty"`
	URLArchivo  *string  `json:"url_archivo,omitempty"`
	Descripcion *string  `json:"descripcion,omitempty"`
	TamanoMB    *float64 `json:"tamano_mb,omitempty"`
	Orden       *int     `json:"orden,omitempty"`
}
