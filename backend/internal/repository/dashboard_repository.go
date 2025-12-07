package repository

import (
	"encoding/json"
	"fmt"
	"recetario-backend/internal/config"
	"time"
)

type DashboardRepository struct {
	client *SupabaseClient
}

func NewDashboardRepository(client *SupabaseClient) *DashboardRepository {
	return &DashboardRepository{client: client}
}

// ==================== MÉTRICAS PRINCIPALES ====================

// ✅ CORREGIDO: GetTotalEstudiantes ahora filtra por ciclo
func (r *DashboardRepository) GetTotalEstudiantes(cicloID, estado string) (int, error) {
	// Si no hay cicloID, contar todos los estudiantes
	if cicloID == "" {
		url := config.AppConfig.SupabaseURL + "/rest/v1/usuarios?rol=eq.estudiante&select=id"

		if estado != "" && estado != "todos" {
			activo := "true"
			if estado == "inactivo" {
				activo = "false"
			}
			url += "&activo=eq." + activo
		}

		headers := r.client.GetAuthHeaders()
		result, err := r.client.DoRequest("GET", url, nil, headers)
		if err != nil {
			return 0, err
		}

		var usuarios []map[string]interface{}
		if err := json.Unmarshal(result, &usuarios); err != nil {
			return 0, err
		}

		return len(usuarios), nil
	}

	// Contar estudiantes matriculados en el ciclo
	url := config.AppConfig.SupabaseURL + "/rest/v1/matriculas?select=estudiante_id&ciclo_id=eq." + cicloID

	headers := r.client.GetAuthHeaders()
	result, err := r.client.DoRequest("GET", url, nil, headers)
	if err != nil {
		return 0, err
	}

	var matriculas []map[string]interface{}
	if err := json.Unmarshal(result, &matriculas); err != nil {
		return 0, err
	}

	// Contar estudiantes únicos
	estudiantesUnicos := make(map[string]bool)
	for _, mat := range matriculas {
		if estudianteID, ok := mat["estudiante_id"].(string); ok {
			estudiantesUnicos[estudianteID] = true
		}
	}

	return len(estudiantesUnicos), nil
}

// ✅ CORREGIDO: GetTotalDocentes ahora filtra por ciclo
func (r *DashboardRepository) GetTotalDocentes(cicloID, estado string) (int, error) {
	// Si no hay cicloID, contar todos los docentes
	if cicloID == "" {
		url := config.AppConfig.SupabaseURL + "/rest/v1/usuarios?rol=eq.docente&select=id"

		if estado != "" && estado != "todos" {
			activo := "true"
			if estado == "inactivo" {
				activo = "false"
			}
			url += "&activo=eq." + activo
		}

		headers := r.client.GetAuthHeaders()
		result, err := r.client.DoRequest("GET", url, nil, headers)
		if err != nil {
			return 0, err
		}

		var usuarios []map[string]interface{}
		if err := json.Unmarshal(result, &usuarios); err != nil {
			return 0, err
		}

		return len(usuarios), nil
	}

	// Contar docentes que tienen cursos en el ciclo
	url := config.AppConfig.SupabaseURL + "/rest/v1/cursos?select=docente_id&ciclo_id=eq." + cicloID

	if estado == "activo" {
		url += "&activo=eq.true"
	} else if estado == "inactivo" {
		url += "&activo=eq.false"
	}

	headers := r.client.GetAuthHeaders()
	result, err := r.client.DoRequest("GET", url, nil, headers)
	if err != nil {
		return 0, err
	}

	var cursos []map[string]interface{}
	if err := json.Unmarshal(result, &cursos); err != nil {
		return 0, err
	}

	// Contar docentes únicos
	docentesUnicos := make(map[string]bool)
	for _, curso := range cursos {
		if docenteID, ok := curso["docente_id"].(string); ok && docenteID != "" {
			docentesUnicos[docenteID] = true
		}
	}

	return len(docentesUnicos), nil
}

// GetTotalCursos obtiene el total de cursos
func (r *DashboardRepository) GetTotalCursos(cicloID, estado string) (int, error) {
	url := config.AppConfig.SupabaseURL + "/rest/v1/cursos?select=id"

	if cicloID != "" {
		url += "&ciclo_id=eq." + cicloID
	}

	if estado != "" && estado != "todos" {
		activo := "true"
		if estado == "inactivo" {
			activo = "false"
		}
		url += "&activo=eq." + activo
	}

	headers := r.client.GetAuthHeaders()
	result, err := r.client.DoRequest("GET", url, nil, headers)
	if err != nil {
		return 0, err
	}

	var cursos []map[string]interface{}
	if err := json.Unmarshal(result, &cursos); err != nil {
		return 0, err
	}

	return len(cursos), nil
}

// GetTotalMatriculas obtiene el total de matrículas
func (r *DashboardRepository) GetTotalMatriculas(cicloID string) (int, error) {
	url := config.AppConfig.SupabaseURL + "/rest/v1/matriculas?select=id"

	if cicloID != "" {
		url += "&ciclo_id=eq." + cicloID
	}

	headers := r.client.GetAuthHeaders()
	result, err := r.client.DoRequest("GET", url, nil, headers)
	if err != nil {
		return 0, err
	}

	var matriculas []map[string]interface{}
	if err := json.Unmarshal(result, &matriculas); err != nil {
		return 0, err
	}

	return len(matriculas), nil
}

// GetTotalCiclos obtiene el total de ciclos
func (r *DashboardRepository) GetTotalCiclos() (int, error) {
	url := config.AppConfig.SupabaseURL + "/rest/v1/ciclos?select=id"

	headers := r.client.GetAuthHeaders()
	result, err := r.client.DoRequest("GET", url, nil, headers)
	if err != nil {
		return 0, err
	}

	var ciclos []map[string]interface{}
	if err := json.Unmarshal(result, &ciclos); err != nil {
		return 0, err
	}

	return len(ciclos), nil
}

// GetEstudiantesNuevos obtiene estudiantes creados en los últimos 7 días
func (r *DashboardRepository) GetEstudiantesNuevos() (int, error) {
	hace7Dias := time.Now().AddDate(0, 0, -7).Format(time.RFC3339)
	url := config.AppConfig.SupabaseURL + "/rest/v1/usuarios?rol=eq.estudiante&created_at=gte." + hace7Dias + "&select=id"

	headers := r.client.GetAuthHeaders()
	result, err := r.client.DoRequest("GET", url, nil, headers)
	if err != nil {
		return 0, err
	}

	var usuarios []map[string]interface{}
	if err := json.Unmarshal(result, &usuarios); err != nil {
		return 0, err
	}

	return len(usuarios), nil
}

// ==================== CICLO ACTUAL ====================

// GetCicloActivo obtiene información del ciclo activo
func (r *DashboardRepository) GetCicloActivo() ([]byte, error) {
	url := config.AppConfig.SupabaseURL + "/rest/v1/ciclos?activo=eq.true&select=*"

	headers := r.client.GetAuthHeaders()
	return r.client.DoRequest("GET", url, nil, headers)
}

// ==================== DISTRIBUCIONES ====================

// ✅ CORREGIDO: GetEstudiantesPorCiclo ahora filtra por ciclo_id
func (r *DashboardRepository) GetEstudiantesPorCiclo(cicloID string) ([]byte, error) {
	// Si no hay cicloID, devolver array vacío
	if cicloID == "" {
		return json.Marshal([]interface{}{})
	}

	// Obtener estudiantes matriculados en cursos del ciclo específico
	url := config.AppConfig.SupabaseURL + "/rest/v1/matriculas?select=estudiante_id,estudiantes!inner(ciclo_actual,usuarios!inner(activo))&ciclo_id=eq." + cicloID + "&estudiantes.usuarios.activo=eq.true"

	headers := r.client.GetAuthHeaders()
	return r.client.DoRequest("GET", url, nil, headers)
}

// ✅ CORREGIDO: GetDocentesPorEspecialidad ahora filtra por ciclo_id
func (r *DashboardRepository) GetDocentesPorEspecialidad(cicloID string) ([]byte, error) {
	// Si no hay cicloID, devolver todos los docentes activos
	if cicloID == "" {
		url := config.AppConfig.SupabaseURL + "/rest/v1/docentes?select=especialidad,usuarios!inner(activo)&usuarios.activo=eq.true"
		headers := r.client.GetAuthHeaders()
		return r.client.DoRequest("GET", url, nil, headers)
	}

	// Filtrar docentes que tienen cursos en el ciclo específico
	url := config.AppConfig.SupabaseURL + "/rest/v1/cursos?select=docente_id,docentes!inner(especialidad,usuarios!inner(activo))&ciclo_id=eq." + cicloID + "&docentes.usuarios.activo=eq.true"

	headers := r.client.GetAuthHeaders()
	return r.client.DoRequest("GET", url, nil, headers)
}

// ✅ CORREGIDO: GetEstudiantesPorSeccion ahora filtra correctamente
func (r *DashboardRepository) GetEstudiantesPorSeccion(cicloID string) ([]byte, error) {
	// Si no hay cicloID, devolver array vacío
	if cicloID == "" {
		return json.Marshal([]interface{}{})
	}

	// Filtrar estudiantes matriculados en el ciclo específico
	url := config.AppConfig.SupabaseURL + "/rest/v1/matriculas?select=estudiante_id,estudiantes!inner(ciclo_actual,seccion,usuarios!inner(activo))&ciclo_id=eq." + cicloID + "&estudiantes.usuarios.activo=eq.true"

	headers := r.client.GetAuthHeaders()
	return r.client.DoRequest("GET", url, nil, headers)
}

// GetMatriculasPorCurso obtiene matrículas agrupadas por curso
func (r *DashboardRepository) GetMatriculasPorCurso(cicloID string) ([]byte, error) {
	url := config.AppConfig.SupabaseURL + "/rest/v1/cursos?select=id,nombre,seccion,creditos,docente_id,docentes(usuarios(nombre_completo)),matriculas(id)"

	if cicloID != "" {
		url += "&ciclo_id=eq." + cicloID
	}

	url += "&order=nombre.asc"

	headers := r.client.GetAuthHeaders()
	return r.client.DoRequest("GET", url, nil, headers)
}

// GetEvolucionMatriculas obtiene la evolución histórica de matrículas
func (r *DashboardRepository) GetEvolucionMatriculas(limit int) ([]byte, error) {
	if limit == 0 {
		limit = 6
	}

	url := fmt.Sprintf("%s/rest/v1/ciclos?select=id,nombre,fecha_inicio,matriculas(id)&order=fecha_inicio.desc&limit=%d",
		config.AppConfig.SupabaseURL, limit)

	headers := r.client.GetAuthHeaders()
	return r.client.DoRequest("GET", url, nil, headers)
}

// GetTimelineCiclos obtiene todos los ciclos para el timeline
func (r *DashboardRepository) GetTimelineCiclos() ([]byte, error) {
	url := config.AppConfig.SupabaseURL + "/rest/v1/ciclos?select=*&order=fecha_inicio.desc&limit=6"

	headers := r.client.GetAuthHeaders()
	return r.client.DoRequest("GET", url, nil, headers)
}

// GetCursosPorCiclo obtiene todos los cursos con sus matrículas agrupados por ciclo
func (r *DashboardRepository) GetCursosPorCiclo(cicloID string) ([]byte, error) {
	url := config.AppConfig.SupabaseURL + "/rest/v1/cursos?select=id,nombre,nivel,seccion,docente_id,docentes(usuarios(nombre_completo)),matriculas(id)&activo=eq.true"

	if cicloID != "" {
		url += "&ciclo_id=eq." + cicloID
	}

	url += "&order=nivel.asc,nombre.asc"

	headers := r.client.GetAuthHeaders()
	return r.client.DoRequest("GET", url, nil, headers)
}

// GetDocentesCursos obtiene docentes con su carga de trabajo
func (r *DashboardRepository) GetDocentesCursos(cicloID string) ([]byte, error) {
	url := config.AppConfig.SupabaseURL + "/rest/v1/cursos?select=docente_id,docentes!inner(usuarios!inner(nombre_completo)),matriculas(id)&activo=eq.true"

	if cicloID != "" {
		url += "&ciclo_id=eq." + cicloID
	}

	url += "&order=docente_id"

	headers := r.client.GetAuthHeaders()
	return r.client.DoRequest("GET", url, nil, headers)
}
