package models

import "time"

// Curso representa una materia/curso académico
type Curso struct {
	ID          string    `json:"id"`
	Nombre      string    `json:"nombre"`
	Descripcion string    `json:"descripcion,omitempty"`
	DocenteID   string    `json:"docente_id"`
	CicloID     string    `json:"ciclo_id"`
	Nivel       int       `json:"nivel,omitempty"`
	Seccion     string    `json:"seccion,omitempty"`
	Creditos    int       `json:"creditos"`
	Horario     string    `json:"horario,omitempty"`
	Activo      bool      `json:"activo"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`

	// Relaciones (opcionales, para cuando se incluyan en la query)
	Docente *Docente `json:"docentes,omitempty"`
	Ciclo   *Ciclo   `json:"ciclos,omitempty"` // ✅ CAMBIO: "ciclo" → "ciclos"
}

// CrearCursoRequest representa los datos para crear un curso
type CrearCursoRequest struct {
	Nombre      string `json:"nombre" validate:"required"`
	Descripcion string `json:"descripcion"`
	DocenteID   string `json:"docente_id" validate:"required"`
	CicloID     string `json:"ciclo_id" validate:"required"`
	Nivel       int    `json:"nivel" validate:"required,min=1,max=10"`
	Seccion     string `json:"seccion"`
	Creditos    int    `json:"creditos" validate:"required,min=1,max=10"`
	Horario     string `json:"horario"`
}

// ActualizarCursoRequest representa los datos para actualizar un curso
type ActualizarCursoRequest struct {
	Nombre      *string `json:"nombre,omitempty"`
	Descripcion *string `json:"descripcion,omitempty"`
	DocenteID   *string `json:"docente_id,omitempty"`
	CicloID     *string `json:"ciclo_id,omitempty"`
	Nivel       *int    `json:"nivel,omitempty"`
	Seccion     *string `json:"seccion,omitempty"`
	Creditos    *int    `json:"creditos,omitempty"`
	Horario     *string `json:"horario,omitempty"`
	Activo      *bool   `json:"activo,omitempty"`
}
