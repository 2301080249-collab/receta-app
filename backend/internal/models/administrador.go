package models

import "time"

type Administrador struct {
	ID                 string    `json:"id"`
	UsuarioID          string    `json:"usuario_id"`
	CodigoAdmin        string    `json:"codigo_admin,omitempty"` // ✅ Si lo usas en Flutter
	Departamento       string    `json:"departamento,omitempty"` // ✅ Si lo usas en Flutter
	NivelPermiso       string    `json:"nivel_permiso"`
	PuedeCrearUsuarios bool      `json:"puede_crear_usuarios"`
	PuedeEditarCursos  bool      `json:"puede_editar_cursos,omitempty"` // ✅ Permisos adicionales
	PuedeVerReportes   bool      `json:"puede_ver_reportes,omitempty"`
	Permisos           []string  `json:"permisos,omitempty"` // ✅ Si prefieres array como en Flutter
	CreatedAt          time.Time `json:"created_at"`
	UpdatedAt          time.Time `json:"updated_at"`
}
