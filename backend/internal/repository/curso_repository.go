package repository

import (
	"fmt"
	"recetario-backend/internal/config"
	"strings"
)

type cursoRepository struct {
	client *SupabaseClient
}

func NewCursoRepository(client *SupabaseClient) CursoRepository {
	return &cursoRepository{client: client}
}

// ==================== CURSOS ====================

func (r *cursoRepository) CreateCurso(data map[string]interface{}) ([]byte, error) {
	url := config.AppConfig.SupabaseURL + "/rest/v1/cursos"

	headers := r.client.GetAuthHeadersWithPrefer()

	return r.client.DoRequest("POST", url, data, headers)
}

// ✅ CORREGIDO: Agregar docentes(usuario_id,usuarios(nombre_completo))
func (r *cursoRepository) GetAllCursos() ([]byte, error) {
	url := config.AppConfig.SupabaseURL + "/rest/v1/cursos?select=*,ciclos(nombre),docentes(usuario_id,usuarios(nombre_completo))&order=created_at.desc"

	fmt.Println("🔍 [GetAllCursos] URL:", url)

	headers := r.client.GetAuthHeaders()

	result, err := r.client.DoRequest("GET", url, nil, headers)

	fmt.Println("📦 [GetAllCursos] Response length:", len(result))
	fmt.Println("📦 [GetAllCursos] Response RAW:", string(result))

	if strings.Contains(string(result), "ciclos") {
		fmt.Println("✅ Response CONTIENE 'ciclos'")
	} else {
		fmt.Println("❌ Response NO CONTIENE 'ciclos'")
	}

	if strings.Contains(string(result), "docentes") {
		fmt.Println("✅ Response CONTIENE 'docentes'")
	} else {
		fmt.Println("❌ Response NO CONTIENE 'docentes'")
	}

	return result, err
}

// ✅ CORREGIDO: Agregar docentes
func (r *cursoRepository) GetCursoByID(cursoID string) ([]byte, error) {
	url := config.AppConfig.SupabaseURL + "/rest/v1/cursos?id=eq." + cursoID + "&select=*,ciclos(nombre),docentes(usuario_id,usuarios(nombre_completo))"

	headers := r.client.GetAuthHeaders()

	return r.client.DoRequest("GET", url, nil, headers)
}

// ✅ CORREGIDO: Agregar docentes
func (r *cursoRepository) GetCursosByCiclo(cicloID string) ([]byte, error) {
	url := config.AppConfig.SupabaseURL + "/rest/v1/cursos?ciclo_id=eq." + cicloID + "&select=*,ciclos(nombre),docentes(usuario_id,usuarios(nombre_completo))&order=nombre.asc"

	headers := r.client.GetAuthHeaders()

	return r.client.DoRequest("GET", url, nil, headers)
}

// ✅ CORREGIDO: Agregar docentes
func (r *cursoRepository) GetCursosByDocente(docenteID string) ([]byte, error) {
	url := config.AppConfig.SupabaseURL + "/rest/v1/cursos?docente_id=eq." + docenteID + "&select=*,ciclos(nombre),docentes(usuario_id,usuarios(nombre_completo))&order=nombre.asc"

	headers := r.client.GetAuthHeaders()

	return r.client.DoRequest("GET", url, nil, headers)
}

func (r *cursoRepository) UpdateCurso(cursoID string, data map[string]interface{}) error {
	url := config.AppConfig.SupabaseURL + "/rest/v1/cursos?id=eq." + cursoID

	headers := r.client.GetAuthHeadersWithPrefer()

	_, err := r.client.DoRequest("PATCH", url, data, headers)
	return err
}

func (r *cursoRepository) DeleteCurso(cursoID string) error {
	url := config.AppConfig.SupabaseURL + "/rest/v1/cursos?id=eq." + cursoID

	headers := r.client.GetAuthHeaders()

	_, err := r.client.DoRequest("DELETE", url, nil, headers)
	return err
}

// ==================== CURSOS POR ESTUDIANTE ====================

func (r *cursoRepository) GetCursosByEstudiante(estudianteID string) ([]byte, error) {
	// ✅ CORREGIDO: Agregar docentes también aquí
	url := config.AppConfig.SupabaseURL + "/rest/v1/cursos?select=*,matriculas!inner(*),ciclos(nombre),docentes(usuario_id,usuarios(nombre_completo))&matriculas.estudiante_id=eq." + estudianteID + "&matriculas.estado=eq.activo&order=nombre.asc"

	headers := r.client.GetAuthHeaders()

	return r.client.DoRequest("GET", url, nil, headers)
}
