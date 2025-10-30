package models

import (
	"time"

	"github.com/google/uuid"
)

type Entrega struct {
	ID                   uuid.UUID `json:"id,omitempty" db:"id"` // ✅ Agregado omitempty
	TareaID              uuid.UUID `json:"tarea_id" db:"tarea_id"`
	EstudianteID         uuid.UUID `json:"estudiante_id" db:"estudiante_id"`
	Titulo               string    `json:"titulo" db:"titulo"`
	Descripcion          *string   `json:"descripcion,omitempty" db:"descripcion"`
	FechaEntrega         time.Time `json:"fecha_entrega" db:"fecha_entrega"`
	DiasRetraso          int       `json:"dias_retraso" db:"dias_retraso"`
	PenalizacionAplicada float64   `json:"penalizacion_aplicada" db:"penalizacion_aplicada"`
	Calificacion         *float64  `json:"calificacion,omitempty" db:"calificacion"`
	ComentarioDocente    *string   `json:"comentario_docente,omitempty" db:"comentario_docente"`
	Estado               string    `json:"estado" db:"estado"` // pendiente, evaluada, rechazada
	EntregaTardia        bool      `json:"entrega_tardia" db:"entrega_tardia"`
	CreatedAt            time.Time `json:"created_at,omitempty" db:"created_at"` // ✅ Agregado omitempty

	// Relaciones
	Archivos   []ArchivoEntrega `json:"archivos,omitempty"`
	Estudiante *EstudianteInfo  `json:"estudiante,omitempty"`
	Tarea      *Tarea           `json:"tarea,omitempty"`
}

type ArchivoEntrega struct {
	ID            uuid.UUID `json:"id,omitempty" db:"id"` // ✅ Agregado omitempty
	EntregaID     uuid.UUID `json:"entrega_id" db:"entrega_id"`
	NombreArchivo string    `json:"nombre_archivo" db:"nombre_archivo"`
	URLArchivo    string    `json:"url_archivo" db:"url_archivo"`
	TipoArchivo   *string   `json:"tipo_archivo,omitempty" db:"tipo_archivo"`
	TamanoMB      *float64  `json:"tamano_mb,omitempty" db:"tamano_mb"`
	UploadedAt    time.Time `json:"uploaded_at,omitempty" db:"uploaded_at"` // ✅ Agregado omitempty
}

type CreateEntregaRequest struct {
	TareaID     uuid.UUID `json:"tarea_id" binding:"required"`
	Titulo      string    `json:"titulo" binding:"required"`
	Descripcion *string   `json:"descripcion"`
}

type CalificarEntregaRequest struct {
	Calificacion      float64 `json:"calificacion" binding:"required,min=0"`
	ComentarioDocente string  `json:"comentario_docente" binding:"required"`
}

// EstudianteInfo contiene información básica del estudiante para entregas
type EstudianteInfo struct {
	UsuarioID        uuid.UUID `json:"usuario_id"`
	CodigoEstudiante *string   `json:"codigo_estudiante,omitempty"`
	Seccion          *string   `json:"seccion,omitempty"`
	Usuario          struct {
		NombreCompleto string  `json:"nombre_completo"`
		Email          string  `json:"email"`
		AvatarURL      *string `json:"avatar_url,omitempty"`
	} `json:"usuario"`
}
