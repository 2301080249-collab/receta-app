package models

import (
	"encoding/json"
	"time"

	"github.com/google/uuid"
)

type Portafolio struct {
	ID             uuid.UUID `json:"id"`
	UsuarioID      uuid.UUID `json:"usuario_id"` // ✅ CORREGIDO: era estudiante_id
	Titulo         string    `json:"titulo"`
	Descripcion    *string   `json:"descripcion,omitempty"`
	Ingredientes   string    `json:"ingredientes"`
	Preparacion    string    `json:"preparacion"`
	Fotos          []string  `json:"fotos"`
	VideoURL       *string   `json:"video_url,omitempty"`
	CategoriaID    uuid.UUID `json:"categoria_id"`
	TipoReceta     string    `json:"tipo_receta"` // 'propia' o 'api'
	FuenteAPIID    *string   `json:"fuente_api_id,omitempty"`
	Visibilidad    string    `json:"visibilidad"` // 'publica', 'privada'
	NivelAlcanzado *string   `json:"nivel_alcanzado,omitempty"`
	Likes          int       `json:"likes"`
	Vistas         int       `json:"vistas"`
	EsDestacada    bool      `json:"es_destacada"`
	EsCertificada  bool      `json:"es_certificada"`
	CreatedAt      time.Time `json:"created_at,omitempty"`
	UpdatedAt      time.Time `json:"updated_at,omitempty"`
}

// Portafolio con información del estudiante
type PortafolioConEstudiante struct {
	Portafolio
	NombreEstudiante string  `json:"nombre_estudiante"`
	AvatarEstudiante *string `json:"avatar_estudiante,omitempty"`
	CodigoEstudiante string  `json:"codigo_estudiante"`
}

// Request para crear receta propia
type CrearPortafolioRequest struct {
	Titulo       string   `json:"titulo" binding:"required,min=3,max=200"`
	Descripcion  *string  `json:"descripcion"`
	Ingredientes string   `json:"ingredientes" binding:"required,min=10"`
	Preparacion  string   `json:"preparacion" binding:"required,min=10"`
	Fotos        []string `json:"fotos" binding:"required,min=1"`
	VideoURL     *string  `json:"video_url"`
	CategoriaID  string   `json:"categoria_id" binding:"required,uuid"`
	TipoReceta   string   `json:"tipo_receta" binding:"required,oneof=propia api"`
	FuenteAPIID  *string  `json:"fuente_api_id"`
	Visibilidad  string   `json:"visibilidad" binding:"required,oneof=publica privada"`
}

// Request para actualizar receta
type ActualizarPortafolioRequest struct {
	Titulo       *string  `json:"titulo"`
	Descripcion  *string  `json:"descripcion"`
	Ingredientes *string  `json:"ingredientes"`
	Preparacion  *string  `json:"preparacion"`
	Fotos        []string `json:"fotos"`
	VideoURL     *string  `json:"video_url"`
	CategoriaID  *string  `json:"categoria_id"`
	Visibilidad  *string  `json:"visibilidad"`
}

// Comentario de portafolio
type ComentarioPortafolio struct {
	ID           uuid.UUID `json:"id"`
	PortafolioID uuid.UUID `json:"portafolio_id"`
	UsuarioID    uuid.UUID `json:"usuario_id"`
	Comentario   string    `json:"comentario"`
	CreatedAt    time.Time `json:"created_at,omitempty"`
}

// Comentario con información del usuario
type ComentarioConUsuario struct {
	ID            uuid.UUID `json:"id"`
	PortafolioID  uuid.UUID `json:"portafolio_id"`
	UsuarioID     uuid.UUID `json:"usuario_id"`
	Comentario    string    `json:"comentario"`
	CreatedAt     time.Time `json:"created_at,omitempty"`
	NombreUsuario string    `json:"nombre_usuario"`
	AvatarUsuario *string   `json:"avatar_usuario,omitempty"`
}

// ✅ UnmarshalJSON custom para mapear el JSON anidado de Supabase
func (c *ComentarioConUsuario) UnmarshalJSON(data []byte) error {
	// Primero parsear la estructura base
	type Alias ComentarioConUsuario
	aux := &struct {
		Usuarios *struct {
			NombreCompleto string  `json:"nombre_completo"`
			AvatarURL      *string `json:"avatar_url"`
		} `json:"usuarios"`
		*Alias
	}{
		Alias: (*Alias)(c),
	}

	if err := json.Unmarshal(data, &aux); err != nil {
		return err
	}

	// Mapear datos del usuario si existen
	if aux.Usuarios != nil {
		c.NombreUsuario = aux.Usuarios.NombreCompleto
		c.AvatarUsuario = aux.Usuarios.AvatarURL
	}

	return nil
}

// Request para crear comentario
type CrearComentarioRequest struct {
	Comentario string `json:"comentario" binding:"required,min=1,max=500"`
}

// Like de portafolio
type LikePortafolio struct {
	ID           uuid.UUID `json:"id"`
	PortafolioID uuid.UUID `json:"portafolio_id"`
	UsuarioID    uuid.UUID `json:"usuario_id"`
	CreatedAt    time.Time `json:"created_at,omitempty"`
}
