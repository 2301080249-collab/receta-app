package models

import (
	"time"

	"github.com/google/uuid"
)

type Tema struct {
	ID              uuid.UUID  `json:"id" db:"id"`
	CursoID         uuid.UUID  `json:"curso_id" db:"curso_id"`
	Titulo          string     `json:"titulo" db:"titulo"`
	Descripcion     *string    `json:"descripcion,omitempty" db:"descripcion"`
	Orden           int        `json:"orden" db:"orden"`
	FechaDesbloqueo *time.Time `json:"fecha_desbloqueo,omitempty" db:"fecha_desbloqueo"`
	Activo          bool       `json:"activo" db:"activo"`
	CreatedAt       time.Time  `json:"created_at" db:"created_at"`
	UpdatedAt       time.Time  `json:"updated_at" db:"updated_at"`

	// Relaciones
	Materiales []Material `json:"materiales,omitempty"`
	Tareas     []Tarea    `json:"tareas,omitempty"`
}

type CreateTemaRequest struct {
	CursoID         uuid.UUID  `json:"curso_id" binding:"required"`
	Titulo          string     `json:"titulo" binding:"required"`
	Descripcion     *string    `json:"descripcion"`
	Orden           int        `json:"orden" binding:"required,min=1"`
	FechaDesbloqueo *time.Time `json:"fecha_desbloqueo"`
}

type UpdateTemaRequest struct {
	Titulo          *string    `json:"titulo"`
	Descripcion     *string    `json:"descripcion"`
	Orden           *int       `json:"orden" binding:"omitempty,min=1"`
	FechaDesbloqueo *time.Time `json:"fecha_desbloqueo"`
	Activo          *bool      `json:"activo"`
}
