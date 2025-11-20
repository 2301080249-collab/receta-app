package models

import (
	"time"

	"github.com/google/uuid"
)

type Notificacion struct {
	ID           uuid.UUID  `json:"id" db:"id"`
	UsuarioID    uuid.UUID  `json:"usuario_id" db:"usuario_id"`
	Tipo         string     `json:"tipo" db:"tipo"`
	Titulo       string     `json:"titulo" db:"titulo"`
	Mensaje      string     `json:"mensaje" db:"mensaje"`
	RecetaID     *uuid.UUID `json:"receta_id,omitempty" db:"receta_id"`
	EnviadoPorID *uuid.UUID `json:"enviado_por_id,omitempty" db:"enviado_por_id"`
	Leida        bool       `json:"leida" db:"leida"`
	CreatedAt    time.Time  `json:"created_at" db:"created_at"`
}

type NotificacionConInfo struct {
	Notificacion
	NombreEnviador *string `json:"nombre_enviador,omitempty"`
	TituloReceta   *string `json:"titulo_receta,omitempty"`
}
