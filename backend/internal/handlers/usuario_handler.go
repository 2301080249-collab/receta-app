package handlers

import (
	"fmt"
	"recetario-backend/internal/services"

	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
)

type UsuarioHandler struct {
	adminService        *services.AdminService
	notificationService *services.NotificationService // ✅ AGREGAR
}

func NewUsuarioHandler(adminService *services.AdminService, notificationService *services.NotificationService) *UsuarioHandler {
	return &UsuarioHandler{
		adminService:        adminService,
		notificationService: notificationService, // ✅ AGREGAR
	}
}

// 🆕 Registrar dispositivo FCM
func (h *UsuarioHandler) RegistrarDispositivo(c *fiber.Ctx) error {
	// Obtener usuario_id del contexto (middleware de auth)
	usuarioID := c.Locals("user_id").(string)

	var req struct {
		FCMToken   string `json:"fcm_token"`
		Plataforma string `json:"plataforma"`
	}

	if err := c.BodyParser(&req); err != nil {
		return c.Status(400).JSON(fiber.Map{
			"error":   true,
			"message": "Datos inválidos",
		})
	}

	// Validar datos
	if req.FCMToken == "" || req.Plataforma == "" {
		return c.Status(400).JSON(fiber.Map{
			"error":   true,
			"message": "fcm_token y plataforma son requeridos",
		})
	}

	uid, err := uuid.Parse(usuarioID)
	if err != nil {
		return c.Status(400).JSON(fiber.Map{
			"error":   true,
			"message": "ID de usuario inválido",
		})
	}

	// Registrar dispositivo
	err = h.notificationService.RegistrarDispositivo(uid, req.FCMToken, req.Plataforma)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{
			"error":   true,
			"message": "Error al registrar dispositivo: " + err.Error(),
		})
	}

	return c.Status(201).JSON(fiber.Map{
		"message": "Dispositivo registrado correctamente",
	})
}

// 🆕 Obtener usuarios para compartir - filtrado por relaciones de curso
func (h *UsuarioHandler) ObtenerUsuariosParaCompartir(c *fiber.Ctx) error {
	// Obtener usuario actual
	usuarioActualID, ok := c.Locals("user_id").(string)
	if !ok || usuarioActualID == "" {
		return c.Status(401).JSON(fiber.Map{
			"error":   true,
			"message": "Usuario no autenticado",
		})
	}

	// Obtener información completa del usuario actual para saber su rol
	usuarioActual, err := h.adminService.ObtenerUsuarioPorID(usuarioActualID)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{
			"error":   true,
			"message": "Error al obtener información del usuario",
		})
	}

	// Extraer rol del usuario
	rol := safeGetString(usuarioActual, "rol")

	// ❌ Si es administrador, no puede compartir con nadie
	if rol == "administrador" {
		return c.JSON([]map[string]interface{}{})
	}

	// ✅ Obtener usuarios relacionados por curso
	usuariosRelacionados, err := h.adminService.ObtenerUsuariosRelacionadosPorCurso(usuarioActualID, rol)
	if err != nil {
		fmt.Printf("Error obteniendo usuarios relacionados: %v\n", err)
		return c.Status(500).JSON(fiber.Map{
			"error":   true,
			"message": "Error al obtener usuarios para compartir",
		})
	}

	// Sanitizar respuesta
	var usuariosFiltrados []map[string]interface{}
	for _, usuario := range usuariosRelacionados {
		usuarioID := safeGetString(usuario, "id")

		// Skip si es el usuario actual
		if usuarioID == usuarioActualID {
			continue
		}

		// Crear objeto limpio
		usuarioLimpio := map[string]interface{}{
			"id":              usuarioID,
			"codigo":          safeGetString(usuario, "codigo"),
			"nombre_completo": safeGetString(usuario, "nombre_completo"),
			"rol":             safeGetString(usuario, "rol"),
			"avatar_url":      safeGetString(usuario, "avatar_url"),
		}

		usuariosFiltrados = append(usuariosFiltrados, usuarioLimpio)
	}

	return c.JSON(usuariosFiltrados)
}

// ✅ Helper seguro para extraer strings sin panic
func safeGetString(m map[string]interface{}, key string) string {
	if val, ok := m[key]; ok && val != nil {
		if str, ok := val.(string); ok {
			return str
		}
	}
	return ""
}
