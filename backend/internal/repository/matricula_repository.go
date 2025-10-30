package repository

import (
	"fmt"
	"recetario-backend/internal/config"
)

type matriculaRepository struct {
	client *SupabaseClient
}

func NewMatriculaRepository(client *SupabaseClient) MatriculaRepository {
	return &matriculaRepository{client: client}
}

// ==================== MATRÍCULAS ====================

func (r *matriculaRepository) CreateMatricula(data map[string]interface{}) ([]byte, error) {
	url := config.AppConfig.SupabaseURL + "/rest/v1/matriculas"

	headers := r.client.GetAuthHeadersWithPrefer()

	return r.client.DoRequest("POST", url, data, headers)
}

func (r *matriculaRepository) GetMatriculasByCurso(cursoID string) ([]byte, error) {
	// JOIN: matriculas -> estudiantes -> usuarios
	// ✅ AGREGADO: observaciones, fecha_matricula
	url := config.AppConfig.SupabaseURL + "/rest/v1/matriculas?curso_id=eq." + cursoID +
		"&select=id,estudiante_id,curso_id,ciclo_id,estado,nota_final,observaciones,fecha_matricula,created_at,estudiantes!inner(codigo_estudiante,usuarios!inner(nombre_completo,codigo,email))&order=created_at.desc"

	headers := r.client.GetAuthHeaders()

	return r.client.DoRequest("GET", url, nil, headers)
}

func (r *matriculaRepository) GetMatriculasByEstudiante(estudianteID string) ([]byte, error) {
	// ✅ El * ya incluye observaciones y fecha_matricula automáticamente
	url := config.AppConfig.SupabaseURL + "/rest/v1/matriculas?estudiante_id=eq." + estudianteID +
		"&select=*,cursos(nombre),ciclos(nombre)"

	headers := r.client.GetAuthHeaders()

	return r.client.DoRequest("GET", url, nil, headers)
}

func (r *matriculaRepository) CheckMatriculaExists(estudianteID, cursoID, cicloID string) ([]byte, error) {
	url := config.AppConfig.SupabaseURL + "/rest/v1/matriculas?estudiante_id=eq." + estudianteID +
		"&curso_id=eq." + cursoID + "&ciclo_id=eq." + cicloID

	headers := r.client.GetAuthHeaders()

	return r.client.DoRequest("GET", url, nil, headers)
}

func (r *matriculaRepository) UpdateMatricula(matriculaID string, data map[string]interface{}) error {
	url := config.AppConfig.SupabaseURL + "/rest/v1/matriculas?id=eq." + matriculaID

	headers := r.client.GetAuthHeadersWithPrefer()

	_, err := r.client.DoRequest("PATCH", url, data, headers)
	return err
}

func (r *matriculaRepository) DeleteMatricula(matriculaID string) error {
	url := config.AppConfig.SupabaseURL + "/rest/v1/matriculas?id=eq." + matriculaID

	headers := r.client.GetAuthHeaders()

	_, err := r.client.DoRequest("DELETE", url, nil, headers)
	return err
}

func (r *matriculaRepository) GetAllMatriculas() ([]byte, error) {
	// Query CON datos anidados
	// ✅ El * ya incluye observaciones y fecha_matricula automáticamente
	url := config.AppConfig.SupabaseURL + "/rest/v1/matriculas?" +
		"select=" +
		"*," + // Todos los campos base de matrícula (incluye observaciones y fecha_matricula)
		"estudiantes(" + // Relación con estudiantes
		"id," +
		"usuario_id," +
		"codigo_estudiante," +
		"ciclo_actual," +
		"seccion," +
		"usuarios(nombre_completo,email,codigo)" + // Usuario del estudiante
		")," +
		"cursos(" + // Relación con cursos
		"id," +
		"nombre," +
		"nivel," +
		"seccion," +
		"creditos," +
		"docente_id," +
		"docentes(usuario_id,usuarios(nombre_completo))" + // Docente del curso
		")," +
		"ciclos(id,nombre,fecha_inicio,fecha_fin)" + // Relación con ciclos
		"&order=created_at.desc"

	headers := r.client.GetAuthHeaders()

	respBody, err := r.client.DoRequest("GET", url, nil, headers)

	// 🔍 DEBUG
	fmt.Println("=== RESPUESTA SUPABASE ===")
	fmt.Println("Error:", err)
	fmt.Println("Body:", string(respBody))
	fmt.Println("==========================")

	return respBody, err
}
