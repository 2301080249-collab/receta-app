package handlers

import (
	"recetario-backend/internal/services"

	"github.com/gofiber/fiber/v2"
)

// ✅ AdminHandler con dependency injection
type AdminHandler struct {
	adminService *services.AdminService
}

// ✅ Constructor
func NewAdminHandler(adminService *services.AdminService) *AdminHandler {
	return &AdminHandler{
		adminService: adminService,
	}
}

// ✅ Métodos públicos (con mayúscula)

func (h *AdminHandler) CrearUsuario(c *fiber.Ctx) error {
	req := new(services.CrearUsuarioRequest)

	if err := c.BodyParser(req); err != nil {
		return c.Status(400).JSON(fiber.Map{
			"error": "Datos inválidos en el formato JSON",
		})
	}

	userID, err := h.adminService.CrearUsuario(req)
	if err != nil {
		return c.Status(400).JSON(fiber.Map{
			"error": err.Error(),
		})
	}

	return c.Status(201).JSON(fiber.Map{
		"message":           "Usuario creado exitosamente",
		"user_id":           userID,
		"email":             req.Email,
		"rol":               req.Rol,
		"password_temporal": req.Codigo, // ✅ Contraseña = código del usuario
	})
}

func (h *AdminHandler) ListarUsuarios(c *fiber.Ctx) error {
	usuarios, err := h.adminService.ListarUsuarios()
	if err != nil {
		return c.Status(500).JSON(fiber.Map{
			"error": "Error al obtener la lista de usuarios",
		})
	}

	return c.JSON(usuarios)
}

func (h *AdminHandler) ObtenerUsuarioPorID(c *fiber.Ctx) error {
	userID := c.Params("id")

	if userID == "" {
		return c.Status(400).JSON(fiber.Map{
			"error": "ID de usuario requerido",
		})
	}

	usuario, err := h.adminService.ObtenerUsuarioPorID(userID)
	if err != nil {
		return c.Status(404).JSON(fiber.Map{
			"error": err.Error(),
		})
	}

	return c.JSON(usuario)
}

func (h *AdminHandler) EditarUsuario(c *fiber.Ctx) error {
	userID := c.Params("id")

	if userID == "" {
		return c.Status(400).JSON(fiber.Map{
			"error": "ID de usuario requerido",
		})
	}

	var updates map[string]interface{}
	if err := c.BodyParser(&updates); err != nil {
		return c.Status(400).JSON(fiber.Map{
			"error": "Datos inválidos",
		})
	}

	if err := h.adminService.EditarUsuario(userID, updates); err != nil {
		return c.Status(400).JSON(fiber.Map{
			"error": err.Error(),
		})
	}

	return c.JSON(fiber.Map{
		"message": "Usuario actualizado exitosamente",
	})
}

func (h *AdminHandler) EliminarUsuario(c *fiber.Ctx) error {
	userID := c.Params("id")

	if userID == "" {
		return c.Status(400).JSON(fiber.Map{
			"error": "ID de usuario requerido",
		})
	}

	if err := h.adminService.EliminarUsuario(userID); err != nil {
		return c.Status(500).JSON(fiber.Map{
			"error": err.Error(),
		})
	}

	return c.JSON(fiber.Map{
		"message": "Usuario eliminado exitosamente",
	})
}

func (h *AdminHandler) ObtenerEstadisticas(c *fiber.Ctx) error {
	stats, err := h.adminService.ObtenerEstadisticas()
	if err != nil {
		return c.Status(500).JSON(fiber.Map{
			"error": "Error al obtener estadísticas",
		})
	}

	return c.JSON(stats)
}
