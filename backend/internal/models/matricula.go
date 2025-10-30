package models

import "time"

// Matricula representa la inscripción de un estudiante en un curso
type Matricula struct {
	ID             string     `json:"id"`
	EstudianteID   string     `json:"estudiante_id"`
	CursoID        string     `json:"curso_id"`
	CicloID        string     `json:"ciclo_id"`
	Estado         string     `json:"estado"`
	NotaFinal      *float64   `json:"nota_final,omitempty"`
	Observaciones  *string    `json:"observaciones,omitempty"`   // ✅ NUEVO
	FechaMatricula *time.Time `json:"fecha_matricula,omitempty"` // ✅ NUEVO
	CreatedAt      time.Time  `json:"created_at"`

	// ✅ CAMBIAR JSON TAGS A PLURAL
	Estudiante *EstudianteDetalle `json:"estudiantes,omitempty"`
	Curso      *CursoDetalle      `json:"cursos,omitempty"`
	Ciclo      *CicloDetalle      `json:"ciclos,omitempty"`
}

// EstudianteDetalle - Datos del estudiante con usuario
type EstudianteDetalle struct {
	ID               string          `json:"id"`
	UsuarioID        string          `json:"usuario_id"`
	CodigoEstudiante string          `json:"codigo_estudiante"`
	CicloActual      int             `json:"ciclo_actual"`
	Seccion          string          `json:"seccion,omitempty"`
	Usuario          *UsuarioDetalle `json:"usuarios,omitempty"` // ✅ PLURAL
}

// CursoDetalle - Datos del curso con docente
type CursoDetalle struct {
	ID        string          `json:"id"`
	Nombre    string          `json:"nombre"`
	Nivel     *int            `json:"nivel"`
	Seccion   *string         `json:"seccion,omitempty"`
	Creditos  int             `json:"creditos"`
	DocenteID string          `json:"docente_id"`
	Docente   *DocenteDetalle `json:"docentes,omitempty"` // ✅ PLURAL
}

// DocenteDetalle - Datos del docente con usuario
type DocenteDetalle struct {
	UsuarioID string          `json:"usuario_id"`
	Usuario   *UsuarioDetalle `json:"usuarios,omitempty"` // ✅ PLURAL
}

// UsuarioDetalle - Datos básicos del usuario
type UsuarioDetalle struct {
	NombreCompleto string `json:"nombre_completo"`
	Email          string `json:"email,omitempty"`
	Codigo         string `json:"codigo,omitempty"`
}

// CicloDetalle - Datos del ciclo
type CicloDetalle struct {
	ID          string `json:"id"`
	Nombre      string `json:"nombre"`
	FechaInicio string `json:"fecha_inicio"`
	FechaFin    string `json:"fecha_fin"`
}

// CrearMatriculaRequest - Request para crear matrícula
type CrearMatriculaRequest struct {
	EstudianteID  string  `json:"estudiante_id"`
	CursoID       string  `json:"curso_id"`
	CicloID       string  `json:"ciclo_id"`
	Estado        *string `json:"estado,omitempty"`        // ✅ NUEVO (opcional)
	Observaciones *string `json:"observaciones,omitempty"` // ✅ NUEVO (opcional)
}

// MatriculaMasivaRequest - Request para matricular múltiples estudiantes
type MatriculaMasivaRequest struct {
	EstudiantesIDs []string `json:"estudiantes_ids"`
	CursoID        string   `json:"curso_id"`
	CicloID        string   `json:"ciclo_id"`
	Estado         *string  `json:"estado,omitempty"`        // ✅ NUEVO (opcional, se aplica a todos)
	Observaciones  *string  `json:"observaciones,omitempty"` // ✅ NUEVO (opcional, se aplica a todos)
}

// ActualizarMatriculaRequest - Request para actualizar matrícula
type ActualizarMatriculaRequest struct {
	Estado        *string  `json:"estado,omitempty"`
	NotaFinal     *float64 `json:"nota_final,omitempty"`
	Observaciones *string  `json:"observaciones,omitempty"` // ✅ NUEVO
}
