package models

// DashboardStats representa las estadísticas generales del dashboard
type DashboardStats struct {
	TotalEstudiantes        int                       `json:"total_estudiantes"`
	TotalDocentes           int                       `json:"total_docentes"`
	TotalCursos             int                       `json:"total_cursos"`
	TotalMatriculas         int                       `json:"total_matriculas"`
	TotalCiclos             int                       `json:"total_ciclos"`
	CursosActivos           int                       `json:"cursos_activos"`
	EstudiantesNuevos       int                       `json:"estudiantes_nuevos"` // Últimos 7 días
	DocentesActivos         int                       `json:"docentes_activos"`
	MatriculasOcupacion     float64                   `json:"matriculas_ocupacion"` // Porcentaje
	MatriculasPendientes    int                       `json:"matriculas_pendientes"`
	CicloActual             *CicloActual              `json:"ciclo_actual"`
	EstudiantesPorCiclo     []EstudiantesPorCiclo     `json:"estudiantes_por_ciclo"`
	DocentesPorEspecialidad []DocentesPorEspecialidad `json:"docentes_por_especialidad"`
	EstudiantesPorSeccion   []EstudiantesPorSeccion   `json:"estudiantes_por_seccion"`
	MatriculasPorCurso      []MatriculasPorCurso      `json:"matriculas_por_curso"`
	EvolucionMatriculas     []EvolucionMatriculas     `json:"evolucion_matriculas"`
	TimelineCiclos          []TimelineCiclo           `json:"timeline_ciclos"`
	CursosPorCiclo          []CursosPorCiclo          `json:"cursos_por_ciclo"`
	DocentesCursos          []DocenteCursos           `json:"docentes_cursos"`
}

// CicloActual representa el ciclo académico activo
type CicloActual struct {
	ID               string  `json:"id"`
	Nombre           string  `json:"nombre"`
	FechaInicio      string  `json:"fecha_inicio"`
	FechaFin         string  `json:"fecha_fin"`
	DuracionSemanas  int     `json:"duracion_semanas"`
	SemanaActual     int     `json:"semana_actual"`
	DiasRestantes    int     `json:"dias_restantes"`
	PorcentajeAvance float64 `json:"porcentaje_avance"`
}

// EstudiantesPorCiclo representa la distribución de estudiantes por ciclo académico
type EstudiantesPorCiclo struct {
	Ciclo      int     `json:"ciclo"`       // 1, 2, 3, 4, 5
	CicloLabel string  `json:"ciclo_label"` // "Ciclo I", "Ciclo II"
	Cantidad   int     `json:"cantidad"`
	Porcentaje float64 `json:"porcentaje"`
}

// DocentesPorEspecialidad representa la distribución de docentes
type DocentesPorEspecialidad struct {
	Especialidad string `json:"especialidad"`
	Cantidad     int    `json:"cantidad"`
}

// EstudiantesPorSeccion representa estudiantes agrupados por ciclo y sección
type EstudiantesPorSeccion struct {
	Ciclo    int    `json:"ciclo"`
	Seccion  string `json:"seccion"`
	Cantidad int    `json:"cantidad"`
}

// MatriculasPorCurso representa las matrículas de cada curso
type MatriculasPorCurso struct {
	CursoID       string  `json:"curso_id"`
	CursoNombre   string  `json:"curso_nombre"`
	Matriculados  int     `json:"matriculados"`
	Capacidad     int     `json:"capacidad"`
	Porcentaje    float64 `json:"porcentaje"`
	DocenteNombre string  `json:"docente_nombre"`
	Seccion       string  `json:"seccion"`
}

// EvolucionMatriculas representa la tendencia histórica
type EvolucionMatriculas struct {
	CicloID     string `json:"ciclo_id"`
	CicloNombre string `json:"ciclo_nombre"`
	Cantidad    int    `json:"cantidad"`
	Fecha       string `json:"fecha"` // Fecha de inicio del ciclo
}

// TimelineCiclo representa el timeline de ciclos
type TimelineCiclo struct {
	ID               string  `json:"id"`
	Nombre           string  `json:"nombre"`
	FechaInicio      string  `json:"fecha_inicio"`
	FechaFin         string  `json:"fecha_fin"`
	Activo           bool    `json:"activo"`
	PorcentajeAvance float64 `json:"porcentaje_avance"`
	Estado           string  `json:"estado"` // "finalizado", "en_curso", "proximo", "planificado"
	DiasRestantes    int     `json:"dias_restantes"`
}

// DashboardFilters representa los filtros aplicables
type DashboardFilters struct {
	CicloID string `json:"ciclo_id,omitempty"`
	Seccion string `json:"seccion,omitempty"`
	Estado  string `json:"estado,omitempty"` // "activo", "inactivo", "todos"

}

// Agregar al final del archivo internal/models/dashboard_stats.go

// CursosPorCiclo representa cursos agrupados por ciclo académico
type CursosPorCiclo struct {
	Ciclo        int                  `json:"ciclo"`
	CicloLabel   string               `json:"ciclo_label"`
	TotalCursos  int                  `json:"total_cursos"`
	TotalAlumnos int                  `json:"total_alumnos"`
	Cursos       []CursoInfoDashboard `json:"cursos"`
}

// CursoInfoDashboard representa un curso con su cantidad de alumnos (para dashboard)
type CursoInfoDashboard struct {
	ID            string `json:"id"`
	Nombre        string `json:"nombre"`
	Alumnos       int    `json:"alumnos"`
	DocenteNombre string `json:"docente_nombre"`
	Seccion       string `json:"seccion"`
}

// DocenteCursos representa la carga de trabajo de cada docente
type DocenteCursos struct {
	DocenteID        string `json:"docente_id"`
	DocenteNombre    string `json:"docente_nombre"`
	TotalCursos      int    `json:"total_cursos"`
	TotalEstudiantes int    `json:"total_estudiantes"`
}
