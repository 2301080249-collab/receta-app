package models

import (
	"time"

	"github.com/google/uuid"
)

type UsuarioDevice struct {
	ID         uuid.UUID `json:"id" db:"id"`
	UsuarioID  uuid.UUID `json:"usuario_id" db:"usuario_id"`
	FCMToken   string    `json:"fcm_token" db:"fcm_token"`
	Plataforma string    `json:"plataforma" db:"plataforma"` // "android", "ios", "web"
	Activo     bool      `json:"activo" db:"activo"`
	CreatedAt  time.Time `json:"created_at" db:"created_at"`
	UpdatedAt  time.Time `json:"updated_at" db:"updated_at"`
}
