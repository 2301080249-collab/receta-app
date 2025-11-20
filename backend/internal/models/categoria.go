package models

import (
	"time"

	"github.com/google/uuid"
)

// Categoria representa una categoría de portafolio
type Categoria struct {
	ID          uuid.UUID `json:"id" db:"id"`
	Nombre      string    `json:"nombre" db:"nombre"`
	Descripcion string    `json:"descripcion" db:"descripcion"`
	Icono       string    `json:"icono" db:"icono"`
	Orden       int       `json:"orden" db:"orden"`
	Activo      bool      `json:"activo" db:"activo"`
	CreatedAt   time.Time `json:"created_at,omitempty" db:"created_at"`
}

// CrearCategoriaRequest representa los datos para crear una categoría
type CrearCategoriaRequest struct {
	Nombre      string `json:"nombre" validate:"required"`
	Descripcion string `json:"descripcion"`
	Icono       string `json:"icono"`
	Orden       int    `json:"orden"`
}

// ActualizarCategoriaRequest representa los datos para actualizar una categoría
type ActualizarCategoriaRequest struct {
	Nombre      *string `json:"nombre,omitempty"`
	Descripcion *string `json:"descripcion,omitempty"`
	Icono       *string `json:"icono,omitempty"`
	Orden       *int    `json:"orden,omitempty"`
	Activo      *bool   `json:"activo,omitempty"`
}
