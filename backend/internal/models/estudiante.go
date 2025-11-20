package models

import (
	"time"
)

type Estudiante struct {
	ID               string    `json:"id"`
	UsuarioID        string    `json:"usuario_id"`
	CodigoEstudiante string    `json:"codigo_estudiante"`
	CicloActual      int       `json:"ciclo_actual"`
	Seccion          string    `json:"seccion,omitempty"`
	Telefono         string    `json:"telefono,omitempty"`
	FechaNacimiento  string    `json:"fecha_nacimiento,omitempty"`
	CreatedAt        time.Time `json:"created_at"`
	UpdatedAt        time.Time `json:"updated_at"`
}

