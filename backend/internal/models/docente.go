package models

import "time"

type Docente struct {
	ID             string    `json:"id"`
	UsuarioID      string    `json:"usuario_id"`
	CodigoDocente  string    `json:"codigo_docente"`
	Especialidad   string    `json:"especialidad"`
	Departamento   string    `json:"departamento,omitempty"`    // ✅ opcional
	GradoAcademico string    `json:"grado_academico,omitempty"` // ✅ opcional
	Bio            string    `json:"bio,omitempty"`             // ✅ opcional
	FotoURL        string    `json:"foto_url,omitempty"`        // ✅ opcional
	Telefono       string    `json:"telefono,omitempty"`        // ✅ opcional
	CreatedAt      time.Time `json:"created_at"`
	UpdatedAt      time.Time `json:"updated_at"`
	// ✅ Agregado al final:
	Usuario *Usuario `json:"usuarios,omitempty"`
}
