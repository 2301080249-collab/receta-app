package models

import (
	"time"

	"github.com/google/uuid"
)

type Tarea struct {
	ID                   uuid.UUID  `json:"id" db:"id"`
	CursoID              uuid.UUID  `json:"curso_id" db:"curso_id"`
	TemaID               *uuid.UUID `json:"tema_id,omitempty" db:"tema_id"`
	Titulo               string     `json:"titulo" db:"titulo"`
	Descripcion          *string    `json:"descripcion,omitempty" db:"descripcion"`
	Semana               *int       `json:"semana,omitempty" db:"semana"`
	FechaPublicacion     time.Time  `json:"fecha_publicacion" db:"fecha_publicacion"`
	FechaLimite          time.Time  `json:"fecha_limite" db:"fecha_limite"`
	PuntajeMaximo        float64    `json:"puntaje_maximo" db:"puntaje_maximo"`
	PermiteEntregaTardia bool       `json:"permite_entrega_tardia" db:"permite_entrega_tardia"`
	PenalizacionPorDia   float64    `json:"penalizacion_por_dia" db:"penalizacion_por_dia"`
	DiasTolerancia       int        `json:"dias_tolerancia" db:"dias_tolerancia"`
	Tipo                 string     `json:"tipo" db:"tipo"`
	Activo               bool       `json:"activo" db:"activo"`
	CreatedAt            time.Time  `json:"created_at" db:"created_at"`

	// Stats para docente
	TotalEntregas        int `json:"total_entregas,omitempty"`
	EntregasSinCalificar int `json:"entregas_sin_calificar,omitempty"`
	EntregasCalificadas  int `json:"entregas_calificadas,omitempty"`
	EntregasPendientes   int `json:"entregas_pendientes,omitempty"`

	// Estado para estudiante
	MiEntrega      *Entrega `json:"mi_entrega,omitempty"`
	TiempoRestante *string  `json:"tiempo_restante,omitempty"`
	EstaVencida    bool     `json:"esta_vencida"`
}

type CreateTareaRequest struct {
	CursoID              uuid.UUID  `json:"curso_id" binding:"required"`
	TemaID               *uuid.UUID `json:"tema_id"`
	Titulo               string     `json:"titulo" binding:"required"`
	Descripcion          *string    `json:"descripcion"`
	Semana               *int       `json:"semana"`
	FechaLimite          time.Time  `json:"fecha_limite" binding:"required"`
	PuntajeMaximo        float64    `json:"puntaje_maximo" binding:"required,min=1"`
	PermiteEntregaTardia bool       `json:"permite_entrega_tardia"`
	PenalizacionPorDia   float64    `json:"penalizacion_por_dia"`
	DiasTolerancia       int        `json:"dias_tolerancia"`
	Tipo                 string     `json:"tipo" binding:"required,oneof=practica evaluacion proyecto"`
}
