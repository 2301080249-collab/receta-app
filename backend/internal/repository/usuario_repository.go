package repository

import (
	"encoding/json"
	"fmt"
	"recetario-backend/internal/config"
	"strings"
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
	// ✅ Consultar tabla estudiantes directamente (con JOIN a usuarios)
	// Así garantizamos que SÍ existen en tabla estudiantes
	url := config.AppConfig.SupabaseURL +
		"/rest/v1/estudiantes?" +
		"select=id,usuario_id,codigo_estudiante,ciclo_actual,seccion," +
		"usuarios!inner(id,nombre_completo,email,codigo,activo)" +
		"&usuarios.activo=eq.true"

	headers := r.client.GetAuthHeaders()

	respBody, err := r.client.DoRequest("GET", url, nil, headers)
	if err != nil {
		return nil, err
	}

	// ✅ Transformar respuesta al formato que espera el frontend
	var estudiantes []map[string]interface{}
	if err := json.Unmarshal(respBody, &estudiantes); err != nil {
		return nil, err
	}

	// Construir array compatible con modelo Usuario de Flutter
	usuarios := make([]map[string]interface{}, 0)
	for _, est := range estudiantes {
		if usuario, ok := est["usuarios"].(map[string]interface{}); ok {
			// ✅ Agregar campos del estudiante al objeto usuario
			usuario["estudiantes"] = []map[string]interface{}{
				{
					"usuario_id":        est["usuario_id"],
					"codigo_estudiante": est["codigo_estudiante"],
					"ciclo_actual":      est["ciclo_actual"],
					"seccion":           est["seccion"],
				},
			}
			usuarios = append(usuarios, usuario)
		}
	}

	return json.Marshal(usuarios)
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

// ==================== 🆕 MÉTODOS PARA FILTRAR USUARIOS POR RELACIÓN DE CURSO ====================

// GetUsuariosRelacionadosPorCurso obtiene usuarios relacionados por curso
// IMPORTANTE: matriculas.estudiante_id → estudiantes.usuario_id (no estudiantes.id)
func (r *usuarioRepository) GetUsuariosRelacionadosPorCurso(userID string, userRol string) ([]byte, error) {
	headers := r.client.GetAuthHeaders()

	switch userRol {
	case "estudiante":
		return r.getUsuariosParaEstudiante(userID, headers)
	case "docente":
		return r.getUsuariosParaDocente(userID, headers)
	default:
		// Para admin u otros roles, devolver lista vacía
		return []byte("[]"), nil
	}
}

// getUsuariosParaEstudiante: compañeros de curso + docentes
func (r *usuarioRepository) getUsuariosParaEstudiante(userID string, headers map[string]string) ([]byte, error) {
	// Paso 1: Obtener cursos del estudiante (matriculas.estudiante_id = estudiantes.usuario_id = userID)
	matriculasResp, err := r.client.DoRequest("GET",
		fmt.Sprintf("%s/rest/v1/matriculas?estudiante_id=eq.%s&select=curso_id",
			config.AppConfig.SupabaseURL, userID),
		nil, headers)
	if err != nil {
		return nil, err
	}

	var matriculas []map[string]interface{}
	if err := json.Unmarshal(matriculasResp, &matriculas); err != nil || len(matriculas) == 0 {
		return []byte("[]"), nil
	}

	// Extraer IDs únicos de cursos
	cursoIDsMap := make(map[string]bool)
	for _, m := range matriculas {
		if cursoID, ok := m["curso_id"].(string); ok {
			cursoIDsMap[cursoID] = true
		}
	}

	if len(cursoIDsMap) == 0 {
		return []byte("[]"), nil
	}

	// Convertir a slice
	cursoIDs := make([]string, 0, len(cursoIDsMap))
	for id := range cursoIDsMap {
		cursoIDs = append(cursoIDs, id)
	}

	usuariosIDsMap := make(map[string]bool)

	// Paso 2: Obtener compañeros (estudiantes en los mismos cursos)
	cursoIDsFilter := "(" + strings.Join(cursoIDs, ",") + ")"
	companerosResp, err := r.client.DoRequest("GET",
		fmt.Sprintf("%s/rest/v1/matriculas?curso_id=in.%s&estudiante_id=neq.%s&select=estudiante_id",
			config.AppConfig.SupabaseURL, cursoIDsFilter, userID),
		nil, headers)

	if err == nil {
		var companeros []map[string]interface{}
		if err := json.Unmarshal(companerosResp, &companeros); err == nil {
			for _, c := range companeros {
				// estudiante_id ya ES el usuario_id
				if estudianteUserID, ok := c["estudiante_id"].(string); ok {
					usuariosIDsMap[estudianteUserID] = true
				}
			}
		}
	}

	// Paso 3: Obtener docentes de los cursos
	cursosResp, err := r.client.DoRequest("GET",
		fmt.Sprintf("%s/rest/v1/cursos?id=in.%s&select=docente_id",
			config.AppConfig.SupabaseURL, cursoIDsFilter),
		nil, headers)

	if err == nil {
		var cursos []map[string]interface{}
		if err := json.Unmarshal(cursosResp, &cursos); err == nil {
			for _, c := range cursos {
				// docente_id ya ES el usuario_id del docente
				if docenteUserID, ok := c["docente_id"].(string); ok && docenteUserID != "" {
					usuariosIDsMap[docenteUserID] = true
				}
			}
		}
	}

	// Paso 4: Obtener datos completos de usuarios
	if len(usuariosIDsMap) == 0 {
		return []byte("[]"), nil
	}

	usuariosIDs := make([]string, 0, len(usuariosIDsMap))
	for id := range usuariosIDsMap {
		usuariosIDs = append(usuariosIDs, id)
	}

	usuariosFilter := "(" + strings.Join(usuariosIDs, ",") + ")"
	return r.client.DoRequest("GET",
		fmt.Sprintf("%s/rest/v1/usuarios?id=in.%s&activo=eq.true&select=id,codigo,nombre_completo,rol,avatar_url",
			config.AppConfig.SupabaseURL, usuariosFilter),
		nil, headers)
}

// getUsuariosParaDocente: estudiantes de sus cursos + otros docentes
func (r *usuarioRepository) getUsuariosParaDocente(userID string, headers map[string]string) ([]byte, error) {
	// Paso 1: Obtener cursos que enseña el docente (cursos.docente_id = docentes.usuario_id = userID)
	cursosResp, err := r.client.DoRequest("GET",
		fmt.Sprintf("%s/rest/v1/cursos?docente_id=eq.%s&select=id",
			config.AppConfig.SupabaseURL, userID),
		nil, headers)
	if err != nil {
		return nil, err
	}

	var cursos []map[string]interface{}
	if err := json.Unmarshal(cursosResp, &cursos); err != nil || len(cursos) == 0 {
		return []byte("[]"), nil
	}

	// Extraer IDs de cursos
	cursoIDs := make([]string, 0)
	for _, c := range cursos {
		if cursoID, ok := c["id"].(string); ok {
			cursoIDs = append(cursoIDs, cursoID)
		}
	}

	if len(cursoIDs) == 0 {
		return []byte("[]"), nil
	}

	usuariosIDsMap := make(map[string]bool)

	// Paso 2: Obtener estudiantes matriculados en estos cursos
	cursoIDsFilter := "(" + strings.Join(cursoIDs, ",") + ")"
	matriculasResp, err := r.client.DoRequest("GET",
		fmt.Sprintf("%s/rest/v1/matriculas?curso_id=in.%s&select=estudiante_id",
			config.AppConfig.SupabaseURL, cursoIDsFilter),
		nil, headers)

	if err == nil {
		var matriculas []map[string]interface{}
		if err := json.Unmarshal(matriculasResp, &matriculas); err == nil {
			for _, m := range matriculas {
				// estudiante_id ya ES el usuario_id
				if estudianteUserID, ok := m["estudiante_id"].(string); ok {
					usuariosIDsMap[estudianteUserID] = true
				}
			}
		}
	}

	// Paso 3: Obtener otros docentes de estos cursos
	cursosDocentesResp, err := r.client.DoRequest("GET",
		fmt.Sprintf("%s/rest/v1/cursos?id=in.%s&docente_id=neq.%s&select=docente_id",
			config.AppConfig.SupabaseURL, cursoIDsFilter, userID),
		nil, headers)

	if err == nil {
		var cursosDocentes []map[string]interface{}
		if err := json.Unmarshal(cursosDocentesResp, &cursosDocentes); err == nil {
			for _, c := range cursosDocentes {
				// docente_id ya ES el usuario_id
				if docenteUserID, ok := c["docente_id"].(string); ok && docenteUserID != "" {
					usuariosIDsMap[docenteUserID] = true
				}
			}
		}
	}

	// Paso 4: Obtener datos completos de usuarios
	if len(usuariosIDsMap) == 0 {
		return []byte("[]"), nil
	}

	usuariosIDs := make([]string, 0, len(usuariosIDsMap))
	for id := range usuariosIDsMap {
		usuariosIDs = append(usuariosIDs, id)
	}

	usuariosFilter := "(" + strings.Join(usuariosIDs, ",") + ")"
	return r.client.DoRequest("GET",
		fmt.Sprintf("%s/rest/v1/usuarios?id=in.%s&activo=eq.true&select=id,codigo,nombre_completo,rol,avatar_url",
			config.AppConfig.SupabaseURL, usuariosFilter),
		nil, headers)
}

// ==================== ✅ OBTENER TODOS LOS DOCENTES (CORREGIDO) ====================

func (r *usuarioRepository) GetDocentes() ([]byte, error) {
	// ✅ CAMBIO: Agregar usuario_id para que Flutter pueda usarlo al crear cursos
	url := config.AppConfig.SupabaseURL + "/rest/v1/docentes?" +
		"select=id,usuario_id,codigo_docente,especialidad,grado_academico,telefono," +
		"usuarios!inner(id,nombre_completo,email,codigo)"

	headers := r.client.GetAuthHeaders()

	return r.client.DoRequest("GET", url, nil, headers)
}
