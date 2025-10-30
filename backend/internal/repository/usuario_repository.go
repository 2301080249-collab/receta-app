package repository

import (
	"encoding/json"
	"fmt"
	"recetario-backend/internal/config"
)

type usuarioRepository struct {
	client *SupabaseClient
}

func NewUsuarioRepository(client *SupabaseClient) UsuarioRepository {
	return &usuarioRepository{client: client}
}

// ==================== USUARIOS ====================

func (r *usuarioRepository) GetUserByID(userID string) ([]byte, error) {
	url := config.AppConfig.SupabaseURL + "/rest/v1/usuarios?id=eq." + userID

	headers := map[string]string{
		"Authorization": "Bearer " + config.AppConfig.SupabaseKey,
	}

	return r.client.DoRequest("GET", url, nil, headers)
}

func (r *usuarioRepository) UpdateUser(userID string, data map[string]interface{}) error {
	url := config.AppConfig.SupabaseURL + "/rest/v1/usuarios?id=eq." + userID

	headers := r.client.GetAuthHeadersWithPrefer()

	fmt.Println("🟡 [Supabase] PATCH usuarios:", url)
	fmt.Println("📦 Data enviada:", data)

	respBody, err := r.client.DoRequest("PATCH", url, data, headers)
	if err != nil {
		fmt.Println("❌ Error en DoRequest:", err)
		return err
	}

	fmt.Println("✅ Respuesta de Supabase:", string(respBody))
	return nil
}

func (r *usuarioRepository) UpdateEstudiante(userID string, data map[string]interface{}) error {
	url := config.AppConfig.SupabaseURL + "/rest/v1/estudiantes?usuario_id=eq." + userID

	headers := r.client.GetAuthHeadersWithPrefer()

	_, err := r.client.DoRequest("PATCH", url, data, headers)
	return err
}

func (r *usuarioRepository) UpdateDocente(userID string, data map[string]interface{}) error {
	url := config.AppConfig.SupabaseURL + "/rest/v1/docentes?usuario_id=eq." + userID

	headers := r.client.GetAuthHeadersWithPrefer()

	_, err := r.client.DoRequest("PATCH", url, data, headers)
	return err
}

func (r *usuarioRepository) GetAllUsers() ([]byte, error) {
	url := config.AppConfig.SupabaseURL + "/rest/v1/usuarios?select=*,estudiantes(ciclo_actual,seccion),docentes(*)"

	headers := r.client.GetAuthHeaders()

	return r.client.DoRequest("GET", url, nil, headers)
}

func (r *usuarioRepository) CreateUser(authBody, userData interface{}) ([]byte, error) {
	// 1. Crear usuario en Auth
	authURL := config.AppConfig.SupabaseURL + "/auth/v1/admin/users"
	headers := r.client.GetAuthHeaders()

	authResp, err := r.client.DoRequest("POST", authURL, authBody, headers)
	if err != nil {
		return nil, fmt.Errorf("error al crear usuario en auth: %w", err)
	}

	// Parsear respuesta para obtener el ID del usuario creado
	var authUser struct {
		ID string `json:"id"`
	}
	if err := json.Unmarshal(authResp, &authUser); err != nil {
		return nil, fmt.Errorf("error al parsear respuesta de auth: %w", err)
	}

	// Agregar el ID al userData si es necesario
	if userMap, ok := userData.(map[string]interface{}); ok {
		userMap["id"] = authUser.ID
	}

	// 2. Insertar en tabla usuarios
	userURL := config.AppConfig.SupabaseURL + "/rest/v1/usuarios"
	headers["Prefer"] = "return=representation"

	return r.client.DoRequest("POST", userURL, userData, headers)
}

func (r *usuarioRepository) CreateUsuario(data map[string]interface{}) error {
	url := config.AppConfig.SupabaseURL + "/rest/v1/usuarios"

	headers := r.client.GetAuthHeadersWithPrefer()

	_, err := r.client.DoRequest("POST", url, data, headers)
	return err
}

func (r *usuarioRepository) CreateEstudiante(data map[string]interface{}) error {
	url := config.AppConfig.SupabaseURL + "/rest/v1/estudiantes"

	headers := r.client.GetAuthHeaders()

	_, err := r.client.DoRequest("POST", url, data, headers)
	return err
}

func (r *usuarioRepository) CreateDocente(data map[string]interface{}) error {
	url := config.AppConfig.SupabaseURL + "/rest/v1/docentes"

	headers := r.client.GetAuthHeaders()

	_, err := r.client.DoRequest("POST", url, data, headers)
	return err
}

func (r *usuarioRepository) CreateAdministrador(data map[string]interface{}) error {
	url := config.AppConfig.SupabaseURL + "/rest/v1/administradores"

	headers := r.client.GetAuthHeaders()

	_, err := r.client.DoRequest("POST", url, data, headers)
	return err
}

func (r *usuarioRepository) GetAllUsersWithRelations() ([]byte, error) {
	url := config.AppConfig.SupabaseURL + "/rest/v1/usuarios?select=*,estudiantes(*),docentes(*),administradores(*)"

	headers := r.client.GetAuthHeaders()

	return r.client.DoRequest("GET", url, nil, headers)
}

func (r *usuarioRepository) GetUserByIDWithRelations(userID string) ([]byte, error) {
	url := config.AppConfig.SupabaseURL + "/rest/v1/usuarios?id=eq." + userID +
		"&select=*,estudiantes(*),docentes(*),administradores(*)"

	headers := r.client.GetAuthHeaders()

	return r.client.DoRequest("GET", url, nil, headers)
}

func (r *usuarioRepository) GetEstudiantesDisponibles(cursoID, cicloID string) ([]byte, error) {
	// Obtener todos los estudiantes activos
	url := config.AppConfig.SupabaseURL + "/rest/v1/usuarios?rol=eq.estudiante&activo=eq.true&select=*"

	headers := r.client.GetAuthHeaders()

	return r.client.DoRequest("GET", url, nil, headers)
}

// ==================== ✅ NUEVOS MÉTODOS PARA PERFIL POR ROL ====================

// GetDocenteByUserID obtiene los datos completos del docente por usuario_id
func (r *usuarioRepository) GetDocenteByUserID(userID string) ([]byte, error) {
	url := config.AppConfig.SupabaseURL + "/rest/v1/docentes?usuario_id=eq." + userID + "&select=*,usuarios(*)"

	headers := r.client.GetAuthHeaders()

	return r.client.DoRequest("GET", url, nil, headers)
}

// GetEstudianteByUserID obtiene los datos completos del estudiante por usuario_id
func (r *usuarioRepository) GetEstudianteByUserID(userID string) ([]byte, error) {
	url := config.AppConfig.SupabaseURL + "/rest/v1/estudiantes?usuario_id=eq." + userID + "&select=*,usuarios(*)"

	headers := r.client.GetAuthHeaders()

	return r.client.DoRequest("GET", url, nil, headers)
}

// GetAdministradorByUserID obtiene los datos completos del administrador por usuario_id
func (r *usuarioRepository) GetAdministradorByUserID(userID string) ([]byte, error) {
	url := config.AppConfig.SupabaseURL + "/rest/v1/administradores?usuario_id=eq." + userID + "&select=*,usuarios(*)"

	headers := r.client.GetAuthHeaders()

	return r.client.DoRequest("GET", url, nil, headers)
}
