package handlers

import (
	"recetario-backend/internal/services"

	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
)

type NotificationHandler struct {
	service *services.NotificationService
}

func NewNotificationHandler(service *services.NotificationService) *NotificationHandler {
	return &NotificationHandler{service: service}
}

// Compartir receta
type CompartirRecetaRequest struct {
	RecetaID    string   `json:"receta_id"`
	UsuariosIDs []string `json:"usuarios_ids"`
	Mensaje     string   `json:"mensaje,omitempty"` // 🆕 Campo opcional para mensaje personalizado
}

func (h *NotificationHandler) CompartirReceta(c *fiber.Ctx) error {
	var req CompartirRecetaRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(400).JSON(fiber.Map{
			"error": "Datos inválidos",
		})
	}

	// Validaciones
	if req.RecetaID == "" || len(req.UsuariosIDs) == 0 {
		return c.Status(400).JSON(fiber.Map{
			"error": "receta_id y usuarios_ids son requeridos",
		})
	}

	// Convertir recetaID
	recetaID, err := uuid.Parse(req.RecetaID)
	if err != nil {
		return c.Status(400).JSON(fiber.Map{
			"error": "receta_id inválido",
		})
	}

	// Convertir usuariosIDs
	var usuariosUUIDs []uuid.UUID
	for _, id := range req.UsuariosIDs {
		uid, err := uuid.Parse(id)
		if err != nil {
			return c.Status(400).JSON(fiber.Map{
				"error": "ID de usuario inválido: " + id,
			})
		}
		usuariosUUIDs = append(usuariosUUIDs, uid)
	}

	// Obtener usuario actual del contexto
	usuarioID, ok := c.Locals("user_id").(string)
	if !ok || usuarioID == "" {
		return c.Status(401).JSON(fiber.Map{
			"error":   true,
			"message": "Usuario no autenticado",
		})
	}

	enviadoPorID, err := uuid.Parse(usuarioID)
	if err != nil {
		return c.Status(401).JSON(fiber.Map{
			"error": "Usuario no autenticado",
		})
	}

	// 🆕 Compartir receta con mensaje personalizado (opcional)
	err = h.service.CompartirReceta(recetaID, usuariosUUIDs, enviadoPorID, req.Mensaje)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{
			"error": "Error compartiendo receta: " + err.Error(),
		})
	}

	return c.JSON(fiber.Map{
		"message": "Receta compartida exitosamente",
	})
}

// Obtener notificaciones del usuario actual
func (h *NotificationHandler) ObtenerMisNotificaciones(c *fiber.Ctx) error {
	usuarioID, ok := c.Locals("user_id").(string)
	if !ok || usuarioID == "" {
		return c.Status(401).JSON(fiber.Map{
			"error":   true,
			"message": "Usuario no autenticado",
		})
	}

	uid, err := uuid.Parse(usuarioID)
	if err != nil {
		return c.Status(401).JSON(fiber.Map{
			"error": "Usuario no autenticado",
		})
	}

	notificaciones, err := h.service.ObtenerNotificaciones(uid)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{
			"error": "Error obteniendo notificaciones: " + err.Error(),
		})
	}

	return c.JSON(notificaciones)
}

// Marcar notificación como leída
func (h *NotificationHandler) MarcarComoLeida(c *fiber.Ctx) error {
	notificacionID, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return c.Status(400).JSON(fiber.Map{
			"error": "ID de notificación inválido",
		})
	}

	err = h.service.MarcarComoLeida(notificacionID)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{
			"error": "Error marcando notificación: " + err.Error(),
		})
	}

	return c.JSON(fiber.Map{
		"message": "Notificación marcada como leída",
	})
}

// Marcar todas las notificaciones como leídas
func (h *NotificationHandler) MarcarTodasComoLeidas(c *fiber.Ctx) error {
	usuarioID, ok := c.Locals("user_id").(string)
	if !ok || usuarioID == "" {
		return c.Status(401).JSON(fiber.Map{
			"error":   true,
			"message": "Usuario no autenticado",
		})
	}

	uid, err := uuid.Parse(usuarioID)
	if err != nil {
		return c.Status(401).JSON(fiber.Map{
			"error": "Usuario no autenticado",
		})
	}

	err = h.service.MarcarTodasComoLeidas(uid)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{
			"error": "Error marcando notificaciones: " + err.Error(),
		})
	}

	return c.JSON(fiber.Map{
		"message": "Todas las notificaciones marcadas como leídas",
	})
}

// Registrar dispositivo FCM
type RegistrarDispositivoRequest struct {
	FCMToken   string `json:"fcm_token"`
	Plataforma string `json:"plataforma"`
}

func (h *NotificationHandler) RegistrarDispositivo(c *fiber.Ctx) error {
	var req RegistrarDispositivoRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(400).JSON(fiber.Map{
			"error": "Datos inválidos",
		})
	}

	// Validaciones
	if req.FCMToken == "" || req.Plataforma == "" {
		return c.Status(400).JSON(fiber.Map{
			"error": "fcm_token y plataforma son requeridos",
		})
	}

	usuarioID, ok := c.Locals("user_id").(string)
	if !ok || usuarioID == "" {
		return c.Status(401).JSON(fiber.Map{
			"error":   true,
			"message": "Usuario no autenticado",
		})
	}

	uid, err := uuid.Parse(usuarioID)
	if err != nil {
		return c.Status(401).JSON(fiber.Map{
			"error": "Usuario no autenticado",
		})
	}

	// Registrar dispositivo
	err = h.service.RegistrarDispositivo(uid, req.FCMToken, req.Plataforma)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{
			"error": "Error registrando dispositivo: " + err.Error(),
		})
	}

	return c.JSON(fiber.Map{
		"message": "Dispositivo registrado exitosamente",
	})
}

// Contar notificaciones no leídas
func (h *NotificationHandler) ContarNoLeidas(c *fiber.Ctx) error {
	usuarioID, ok := c.Locals("user_id").(string)
	if !ok || usuarioID == "" {
		return c.Status(401).JSON(fiber.Map{
			"error":   true,
			"message": "Usuario no autenticado",
		})
	}

	uid, err := uuid.Parse(usuarioID)
	if err != nil {
		return c.Status(401).JSON(fiber.Map{
			"error": "Usuario no autenticado",
		})
	}

	count, err := h.service.ContarNoLeidas(uid)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{
			"error": "Error contando notificaciones: " + err.Error(),
		})
	}

	return c.JSON(fiber.Map{
		"no_leidas": count,
	})
}
