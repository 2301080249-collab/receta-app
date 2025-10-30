package services

import (
	"encoding/json"
	"fmt"
	"recetario-backend/internal/models"
	"recetario-backend/internal/repository"
)

type AuthService struct {
	authRepo    repository.AuthRepository
	usuarioRepo repository.UsuarioRepository
}

func NewAuthService(authRepo repository.AuthRepository, usuarioRepo repository.UsuarioRepository) *AuthService {
	return &AuthService{
		authRepo:    authRepo,
		usuarioRepo: usuarioRepo,
	}
}

func (s *AuthService) Login(email, password string) (*models.LoginResponse, error) {
	// 1. Autenticar
	token, userID, err := s.authRepo.Authenticate(email, password)
	if err != nil {
		return nil, err
	}

	// 2. Obtener datos del usuario
	userBody, err := s.usuarioRepo.GetUserByID(userID)
	if err != nil {
		return nil, fmt.Errorf("usuario no encontrado")
	}

	var usuarios []models.Usuario
	if err := json.Unmarshal(userBody, &usuarios); err != nil {
		return nil, fmt.Errorf("error al parsear usuario")
	}

	if len(usuarios) == 0 {
		return nil, fmt.Errorf("usuario no encontrado")
	}

	usuario := usuarios[0]

	if !usuario.Activo {
		return nil, fmt.Errorf("usuario desactivado")
	}

	return &models.LoginResponse{
		User:       usuario,
		Token:      token,
		PrimeraVez: usuario.PrimeraVez,
	}, nil
}

func (s *AuthService) ChangePassword(userID, newPassword string) error {
	// Validar contraseña
	if len(newPassword) < 8 {
		return fmt.Errorf("la contraseña debe tener al menos 8 caracteres")
	}

	// 1. Cambiar contraseña en Auth
	if err := s.authRepo.UpdatePassword(userID, newPassword); err != nil {
		return fmt.Errorf("error al cambiar contraseña: %w", err)
	}

	// 2. Actualizar primera_vez
	updateData := map[string]interface{}{
		"primera_vez": false,
	}

	if err := s.usuarioRepo.UpdateUser(userID, updateData); err != nil {
		return fmt.Errorf("error al actualizar usuario: %w", err)
	}

	return nil
}

func (s *AuthService) OmitirCambioPassword(userID string) error {
	updateData := map[string]interface{}{
		"primera_vez": false,
	}

	if err := s.usuarioRepo.UpdateUser(userID, updateData); err != nil {
		return fmt.Errorf("error al actualizar usuario: %w", err)
	}

	return nil
}

// ==================== AGREGAR ESTOS MÉTODOS A internal/services/auth_service.go ====================

// GetDocentePerfil obtiene los datos completos del docente autenticado
func (s *AuthService) GetDocentePerfil(userID string) (*models.Docente, error) {
	docenteBody, err := s.usuarioRepo.GetDocenteByUserID(userID)
	if err != nil {
		return nil, fmt.Errorf("error al obtener docente: %w", err)
	}

	var docentes []models.Docente
	if err := json.Unmarshal(docenteBody, &docentes); err != nil {
		return nil, fmt.Errorf("error al parsear docente: %w", err)
	}

	if len(docentes) == 0 {
		return nil, fmt.Errorf("docente no encontrado")
	}

	return &docentes[0], nil
}

// GetEstudiantePerfil obtiene los datos completos del estudiante autenticado
func (s *AuthService) GetEstudiantePerfil(userID string) (*models.Estudiante, error) {
	estudianteBody, err := s.usuarioRepo.GetEstudianteByUserID(userID)
	if err != nil {
		return nil, fmt.Errorf("error al obtener estudiante: %w", err)
	}

	var estudiantes []models.Estudiante
	if err := json.Unmarshal(estudianteBody, &estudiantes); err != nil {
		return nil, fmt.Errorf("error al parsear estudiante: %w", err)
	}

	if len(estudiantes) == 0 {
		return nil, fmt.Errorf("estudiante no encontrado")
	}

	return &estudiantes[0], nil
}

// GetAdministradorPerfil obtiene los datos completos del administrador autenticado
func (s *AuthService) GetAdministradorPerfil(userID string) (*models.Administrador, error) {
	adminBody, err := s.usuarioRepo.GetAdministradorByUserID(userID)
	if err != nil {
		return nil, fmt.Errorf("error al obtener administrador: %w", err)
	}

	var admins []models.Administrador
	if err := json.Unmarshal(adminBody, &admins); err != nil {
		return nil, fmt.Errorf("error al parsear administrador: %w", err)
	}

	if len(admins) == 0 {
		return nil, fmt.Errorf("administrador no encontrado")
	}

	return &admins[0], nil
}
