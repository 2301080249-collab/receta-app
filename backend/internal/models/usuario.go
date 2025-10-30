package models

import "time"

type Usuario struct {
	ID             string    `json:"id"`
	Email          string    `json:"email"`
	NombreCompleto string    `json:"nombre_completo"`
	Rol            string    `json:"rol"`
	Codigo         string    `json:"codigo"`
	Telefono       string    `json:"telefono"`
	Ciclo          string    `json:"ciclo"` // Ciclo en números romanos (I-X)
	PrimeraVez     bool      `json:"primera_vez"`
	AvatarURL      string    `json:"avatar_url,omitempty"`
	Activo         bool      `json:"activo"`
	CreatedAt      time.Time `json:"created_at"`
	UpdatedAt      time.Time `json:"updated_at"`

	// ✅ NUEVO: Relación con estudiantes (para cuando se incluya en la query)
	Estudiante *Estudiante `json:"estudiantes,omitempty"`
}

// ✅ Métodos útiles (opcionales)
func (u *Usuario) IsAdmin() bool {
	return u.Rol == "administrador"
}

func (u *Usuario) IsDocente() bool {
	return u.Rol == "docente"
}

func (u *Usuario) IsEstudiante() bool {
	return u.Rol == "estudiante"
}

type LoginRequest struct {
	Email    string `json:"email" validate:"required,email"`
	Password string `json:"password" validate:"required,min=8"`
}

type LoginResponse struct {
	User       Usuario `json:"user"`
	Token      string  `json:"token"`
	PrimeraVez bool    `json:"primera_vez"`
}

type ChangePasswordRequest struct {
	UserID      string `json:"user_id" validate:"required"`
	NewPassword string `json:"new_password" validate:"required,min=8"`
}
