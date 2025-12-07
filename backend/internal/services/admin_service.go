package services

import (
	"encoding/json"
	"fmt"
	"recetario-backend/internal/repository"
	"strconv"
	"strings"
)

// ✅ AdminService con dependency injection
type AdminService struct {
	authRepo    repository.AuthRepository
	usuarioRepo repository.UsuarioRepository
}

// ✅ Constructor actualizado
func NewAdminService(authRepo repository.AuthRepository, usuarioRepo repository.UsuarioRepository) *AdminService {
	return &AdminService{
		authRepo:    authRepo,
		usuarioRepo: usuarioRepo,
	}
}

type CrearUsuarioRequest struct {
	NombreCompleto string `json:"nombre_completo"`
	Email          string `json:"email"`
	Codigo         string `json:"codigo"`
	Rol            string `json:"rol"`
	Telefono       string `json:"telefono,omitempty"`

	// Estudiante
	Ciclo       string `json:"ciclo,omitempty"`
	CicloActual int    `json:"ciclo_actual,omitempty"`
	Seccion     string `json:"seccion,omitempty"`

	// Docente
	Especialidad   string `json:"especialidad,omitempty"`
	GradoAcademico string `json:"grado_academico,omitempty"`
	Departamento   string `json:"departamento,omitempty"`
}

func (s *AdminService) CrearUsuario(req *CrearUsuarioRequest) (string, error) {
	// 1. Validaciones
	if err := s.validarCrearUsuario(req); err != nil {
		return "", err
	}

	// Manejar tanto string numérico como romano
	if req.Ciclo != "" {
		cicloStr := strings.ToUpper(strings.TrimSpace(req.Ciclo))

		if cicloNum, err := strconv.Atoi(cicloStr); err == nil {
			if cicloNum >= 1 && cicloNum <= 10 {
				req.CicloActual = cicloNum
			} else {
				return "", fmt.Errorf("ciclo debe estar entre 1 y 10")
			}
		} else {
			cicloInt, err := RomanoAEntero(cicloStr)
			if err != nil {
				return "", fmt.Errorf("ciclo inválido: %v", err)
			}
			req.CicloActual = cicloInt
		}
	}

	if req.CicloActual == 0 {
		req.CicloActual = 1
	}

	// 2. Crear en Auth - USAR CÓDIGO COMO CONTRASEÑA TEMPORAL
	userID, err := s.authRepo.CreateAuthUser(
		req.Email,
		req.Codigo, // ✅ Contraseña = código del usuario
		req.NombreCompleto,
		req.Rol,
	)
	if err != nil {
		return "", fmt.Errorf("el email ya está registrado")
	}

	// 3. Crear en tabla usuarios
	usuarioData := map[string]interface{}{
		"id":              userID,
		"email":           req.Email,
		"nombre_completo": req.NombreCompleto,
		"rol":             req.Rol,
		"codigo":          req.Codigo,
		"primera_vez":     true,
		"activo":          true,
	}

	if err := s.usuarioRepo.CreateUsuario(usuarioData); err != nil {
		s.authRepo.DeleteAuthUser(userID)
		fmt.Println("❌ Error real al crear usuario:", err)
		return "", fmt.Errorf("el código ya está en uso")
	}

	// 4. Crear en tabla específica según rol
	if err := s.crearRolEspecifico(userID, req); err != nil {
		s.authRepo.DeleteAuthUser(userID)
		return "", err
	}

	return userID, nil
}

func (s *AdminService) validarCrearUsuario(req *CrearUsuarioRequest) error {
	if req.NombreCompleto == "" || req.Email == "" || req.Codigo == "" || req.Rol == "" {
		return fmt.Errorf("los campos nombre, email, código y rol son obligatorios")
	}

	if req.Rol != "estudiante" && req.Rol != "docente" && req.Rol != "administrador" {
		return fmt.Errorf("el rol debe ser: estudiante, docente o administrador")
	}

	if !strings.Contains(req.Email, "@") || !strings.Contains(req.Email, ".") {
		return fmt.Errorf("formato de email inválido")
	}

	if req.Rol == "docente" && req.Especialidad == "" {
		return fmt.Errorf("el campo 'especialidad' es obligatorio para docentes")
	}

	return nil
}

func (s *AdminService) crearRolEspecifico(userID string, req *CrearUsuarioRequest) error {
	switch req.Rol {
	case "estudiante":
		return s.crearEstudiante(userID, req)
	case "docente":
		return s.crearDocente(userID, req)
	case "administrador":
		return s.crearAdministrador(userID)
	}
	return nil
}

func (s *AdminService) crearEstudiante(userID string, req *CrearUsuarioRequest) error {
	cicloActual := req.CicloActual
	if cicloActual == 0 {
		cicloActual = 1
	}

	data := map[string]interface{}{
		"usuario_id":        userID,
		"codigo_estudiante": req.Codigo,
		"ciclo_actual":      cicloActual,
		"seccion":           req.Seccion,
		"telefono":          req.Telefono,
	}

	return s.usuarioRepo.CreateEstudiante(data)
}

func (s *AdminService) crearDocente(userID string, req *CrearUsuarioRequest) error {
	data := map[string]interface{}{
		"usuario_id":      userID,
		"codigo_docente":  req.Codigo,
		"especialidad":    req.Especialidad,
		"grado_academico": req.GradoAcademico,
		"departamento":    req.Departamento,
		"telefono":        req.Telefono,
	}

	return s.usuarioRepo.CreateDocente(data)
}

func (s *AdminService) crearAdministrador(userID string) error {
	data := map[string]interface{}{
		"usuario_id":           userID,
		"nivel_permiso":        "admin",
		"puede_crear_usuarios": true,
	}

	return s.usuarioRepo.CreateAdministrador(data)
}

func (s *AdminService) ListarUsuarios() ([]map[string]interface{}, error) {
	respBody, err := s.usuarioRepo.GetAllUsersWithRelations()
	if err != nil {
		return nil, err
	}

	var usuarios []map[string]interface{}
	if err := json.Unmarshal(respBody, &usuarios); err != nil {
		return nil, fmt.Errorf("error al parsear usuarios")
	}

	for i := range usuarios {
		s.normalizarRelacion(&usuarios[i], "estudiantes")
		s.normalizarRelacion(&usuarios[i], "docentes")
		s.normalizarRelacion(&usuarios[i], "administradores")
	}

	return usuarios, nil
}

func (s *AdminService) normalizarRelacion(usuario *map[string]interface{}, key string) {
	if obj, ok := (*usuario)[key].(map[string]interface{}); ok {
		(*usuario)[key] = []interface{}{obj}
	} else if (*usuario)[key] == nil {
		(*usuario)[key] = []interface{}{}
	}
}

func (s *AdminService) ObtenerUsuarioPorID(userID string) (map[string]interface{}, error) {
	respBody, err := s.usuarioRepo.GetUserByIDWithRelations(userID)
	if err != nil {
		return nil, fmt.Errorf("usuario no encontrado")
	}

	var usuarios []map[string]interface{}
	if err := json.Unmarshal(respBody, &usuarios); err != nil {
		return nil, fmt.Errorf("error al parsear usuario")
	}

	if len(usuarios) == 0 {
		return nil, fmt.Errorf("usuario no encontrado")
	}

	usuario := usuarios[0]

	s.normalizarRelacion(&usuario, "estudiantes")
	s.normalizarRelacion(&usuario, "docentes")
	s.normalizarRelacion(&usuario, "administradores")

	return usuario, nil
}

// 🆕 Obtener usuarios relacionados por curso
func (s *AdminService) ObtenerUsuariosRelacionadosPorCurso(userID string, rol string) ([]map[string]interface{}, error) {
	respBody, err := s.usuarioRepo.GetUsuariosRelacionadosPorCurso(userID, rol)
	if err != nil {
		return nil, err
	}

	var usuarios []map[string]interface{}
	if err := json.Unmarshal(respBody, &usuarios); err != nil {
		return nil, fmt.Errorf("error al parsear usuarios relacionados")
	}

	return usuarios, nil
}

func (s *AdminService) EditarUsuario(userID string, updates map[string]interface{}) error {
	// Convertir ciclo si viene (puede ser número o romano)
	if cicloRaw, ok := updates["ciclo"]; ok {
		if cicloStr, isString := cicloRaw.(string); isString && cicloStr != "" {
			if cicloNum, err := strconv.Atoi(cicloStr); err == nil {
				if cicloNum >= 1 && cicloNum <= 10 {
					updates["ciclo_actual"] = cicloNum
				} else {
					return fmt.Errorf("ciclo debe estar entre 1 y 10")
				}
			} else {
				cicloInt, err := RomanoAEntero(strings.ToUpper(cicloStr))
				if err != nil {
					return fmt.Errorf("ciclo inválido: %w", err)
				}
				updates["ciclo_actual"] = cicloInt
			}
			delete(updates, "ciclo")
		} else if cicloFloat, isFloat := cicloRaw.(float64); isFloat {
			updates["ciclo_actual"] = int(cicloFloat)
			delete(updates, "ciclo")
		}
	}

	// Separar campos de usuarios vs estudiantes/docentes
	usuariosData := make(map[string]interface{})
	estudianteData := make(map[string]interface{})
	docenteData := make(map[string]interface{})

	for key, value := range updates {
		switch key {
		case "nombre_completo", "email", "codigo", "rol", "activo":
			usuariosData[key] = value
		case "ciclo_actual", "seccion", "grado", "codigo_estudiante":
			estudianteData[key] = value
		case "especialidad", "grado_academico", "departamento", "codigo_docente", "bio", "foto_url":
			docenteData[key] = value
		case "telefono":
			estudianteData[key] = value
			docenteData[key] = value
		}
	}

	if len(usuariosData) > 0 {
		if err := s.usuarioRepo.UpdateUser(userID, usuariosData); err != nil {
			return fmt.Errorf("error al actualizar usuario: %w", err)
		}
	}

	if len(estudianteData) > 0 {
		if err := s.usuarioRepo.UpdateEstudiante(userID, estudianteData); err != nil {
			fmt.Printf("Advertencia: no se pudo actualizar estudiante: %v\n", err)
		}
	}

	if len(docenteData) > 0 {
		if err := s.usuarioRepo.UpdateDocente(userID, docenteData); err != nil {
			fmt.Printf("Advertencia: no se pudo actualizar docente: %v\n", err)
		}
	}

	return nil
}

func (s *AdminService) EliminarUsuario(userID string) error {
	if err := s.authRepo.DeleteAuthUser(userID); err != nil {
		return fmt.Errorf("error al eliminar usuario: %w", err)
	}
	return nil
}

func (s *AdminService) ObtenerEstadisticas() (map[string]interface{}, error) {
	usuarios, err := s.ListarUsuarios()
	if err != nil {
		return nil, err
	}

	stats := map[string]interface{}{
		"total_estudiantes": 0,
		"total_docentes":    0,
		"total_recetas":     0,
		"total_categorias":  0,
	}

	for _, usuario := range usuarios {
		rol, ok := usuario["rol"].(string)
		if !ok {
			continue
		}

		switch rol {
		case "estudiante":
			stats["total_estudiantes"] = stats["total_estudiantes"].(int) + 1
		case "docente":
			stats["total_docentes"] = stats["total_docentes"].(int) + 1
		}
	}

	return stats, nil
}

// ==================== ✅ OBTENER TODOS LOS DOCENTES ====================

func (s *AdminService) GetDocentes() ([]byte, error) {
	return s.usuarioRepo.GetDocentes()
}

func RomanoAEntero(romano string) (int, error) {
	switch strings.ToUpper(romano) {
	case "I":
		return 1, nil
	case "II":
		return 2, nil
	case "III":
		return 3, nil
	case "IV":
		return 4, nil
	case "V":
		return 5, nil
	case "VI":
		return 6, nil
	case "VII":
		return 7, nil
	case "VIII":
		return 8, nil
	case "IX":
		return 9, nil
	case "X":
		return 10, nil
	default:
		return 0, fmt.Errorf("número romano inválido, debe ser I-X")
	}
}
