package handlers

import (
	"fmt"
	"recetario-backend/internal/models"
	"recetario-backend/internal/services"

	"github.com/gofiber/fiber/v2"
)

// ✅ AuthHandler con dependency injection
type AuthHandler struct {
	authService *services.AuthService
}

// ✅ Constructor
func NewAuthHandler(authService *services.AuthService) *AuthHandler {
	return &AuthHandler{
		authService: authService,
	}
}

// ✅ Método público (con mayúscula)
func (h *AuthHandler) Login(c *fiber.Ctx) error {
	req := new(models.LoginRequest)

	if err := c.BodyParser(req); err != nil {
		return c.Status(400).JSON(fiber.Map{
			"error": "Datos inválidos",
		})
	}

	response, err := h.authService.Login(req.Email, req.Password)
	if err != nil {
		return c.Status(401).JSON(fiber.Map{
			"error": err.Error(),
		})
	}

	return c.JSON(response)
}

func (h *AuthHandler) ChangePassword(c *fiber.Ctx) error {
	req := new(models.ChangePasswordRequest)

	if err := c.BodyParser(req); err != nil {
		fmt.Println("❌ Error parseando body:", err)
		return c.Status(400).JSON(fiber.Map{
			"error": "Datos inválidos",
		})
	}

	fmt.Println("✅ UserID recibido:", req.UserID)
	fmt.Println("✅ Nueva contraseña length:", len(req.NewPassword))

	if err := h.authService.ChangePassword(req.UserID, req.NewPassword); err != nil {
		fmt.Println("❌ Error en service:", err)
		return c.Status(400).JSON(fiber.Map{
			"error": err.Error(),
		})
	}

	return c.JSON(fiber.Map{
		"message": "Contraseña actualizada exitosamente",
		"success": true,
	})
}

func (h *AuthHandler) OmitirCambioPassword(c *fiber.Ctx) error {
	req := new(struct {
		UserID string `json:"user_id"`
	})

	if err := c.BodyParser(req); err != nil {
		return c.Status(400).JSON(fiber.Map{
			"error": "JSON inválido",
		})
	}

	if req.UserID == "" {
		return c.Status(400).JSON(fiber.Map{
			"error": "user_id es requerido",
		})
	}

	if err := h.authService.OmitirCambioPassword(req.UserID); err != nil {
		return c.Status(500).JSON(fiber.Map{
			"error": err.Error(),
		})
	}

	return c.JSON(fiber.Map{
		"message": "Cambio de contraseña omitido exitosamente",
		"success": true,
	})
}

// ==================== AGREGAR ESTOS MÉTODOS A internal/handlers/auth_handler.go ====================

// GetDocentePerfil obtiene el perfil completo del docente autenticado
func (h *AuthHandler) GetDocentePerfil(c *fiber.Ctx) error {
	// Obtener userID del token (ya validado por middleware)
	userID, ok := c.Locals("user_id").(string)
	if !ok || userID == "" {
		return c.Status(401).JSON(fiber.Map{
			"error": "Usuario no autenticado",
		})
	}

	// Obtener datos del docente
	docente, err := h.authService.GetDocentePerfil(userID)
	if err != nil {
		return c.Status(404).JSON(fiber.Map{
			"error": err.Error(),
		})
	}

	return c.JSON(docente)
}

// GetEstudiantePerfil obtiene el perfil completo del estudiante autenticado
func (h *AuthHandler) GetEstudiantePerfil(c *fiber.Ctx) error {
	// Obtener userID del token (ya validado por middleware)
	userID, ok := c.Locals("user_id").(string)
	if !ok || userID == "" {
		return c.Status(401).JSON(fiber.Map{
			"error": "Usuario no autenticado",
		})
	}

	// Obtener datos del estudiante
	estudiante, err := h.authService.GetEstudiantePerfil(userID)
	if err != nil {
		return c.Status(404).JSON(fiber.Map{
			"error": err.Error(),
		})
	}

	return c.JSON(estudiante)
}

// GetAdministradorPerfil obtiene el perfil completo del administrador autenticado
func (h *AuthHandler) GetAdministradorPerfil(c *fiber.Ctx) error {
	// Obtener userID del token (ya validado por middleware)
	userID, ok := c.Locals("user_id").(string)
	if !ok || userID == "" {
		return c.Status(401).JSON(fiber.Map{
			"error": "Usuario no autenticado",
		})
	}

	// Obtener datos del administrador
	admin, err := h.authService.GetAdministradorPerfil(userID)
	if err != nil {
		return c.Status(404).JSON(fiber.Map{
			"error": err.Error(),
		})
	}

	return c.JSON(admin)
}
