package handlers

import (
	"fmt"
	"recetario-backend/internal/models"
	"recetario-backend/internal/services"

	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
)

type PortafolioHandler struct {
	service        *services.PortafolioService
	storageService *services.StorageService
}

func NewPortafolioHandler(service *services.PortafolioService, storageService *services.StorageService) *PortafolioHandler {
	return &PortafolioHandler{
		service:        service,
		storageService: storageService,
	}
}

// ==================== CRUD RECETAS ====================

// Crear receta en portafolio (estudiantes y docentes)
func (h *PortafolioHandler) Crear(c *fiber.Ctx) error {
	fmt.Println("🔍 [Crear] Locals disponibles:", c.Locals("user_id"), c.Locals("user_role"))

	userID := c.Locals("user_id")
	if userID == nil {
		fmt.Println("❌ [Crear] user_id es nil")
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"error": "No autorizado",
		})
	}

	userIDStr, ok := userID.(string)
	if !ok {
		fmt.Println("❌ [Crear] user_id no es string")
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Error obteniendo ID del usuario",
		})
	}

	userUUID, err := uuid.Parse(userIDStr)
	if err != nil {
		fmt.Println("❌ [Crear] Error parseando UUID:", err)
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Error parseando ID del usuario",
		})
	}

	ownerID, rol, err := h.service.ObtenerOwnerIDPorUserID(c.Context(), userUUID)
	if err != nil {
		fmt.Println("❌ [Crear] Usuario no autorizado:", err)
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{
			"error": "Solo estudiantes y docentes pueden crear recetas",
		})
	}

	fmt.Printf("✅ [Crear] Owner ID: %s (rol: %s)\n", ownerID, rol)

	var req models.CrearPortafolioRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": err.Error()})
	}

	receta, err := h.service.Crear(c.Context(), ownerID, req)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}

	return c.Status(fiber.StatusCreated).JSON(receta)
}

// ==================== ✨ NUEVO: ACTUALIZAR RECETA ====================
func (h *PortafolioHandler) Actualizar(c *fiber.Ctx) error {
	fmt.Println("🔍 [Actualizar] Iniciando...")

	idStr := c.Params("id")
	recetaID, err := uuid.Parse(idStr)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "ID inválido"})
	}

	userID := c.Locals("user_id")
	if userID == nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "No autorizado"})
	}

	userIDStr, ok := userID.(string)
	if !ok {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Error obteniendo ID del usuario",
		})
	}

	userUUID, err := uuid.Parse(userIDStr)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Error parseando ID del usuario",
		})
	}

	ownerID, _, err := h.service.ObtenerOwnerIDPorUserID(c.Context(), userUUID)
	if err != nil {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{
			"error": "No autorizado para actualizar esta receta",
		})
	}

	var req models.ActualizarPortafolioRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": err.Error()})
	}

	recetaActualizada, err := h.service.Actualizar(c.Context(), recetaID, ownerID, req)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}

	fmt.Printf("✅ [Actualizar] Receta actualizada: %s\n", recetaID)
	return c.JSON(recetaActualizada)
}

// Obtener mis recetas
func (h *PortafolioHandler) ObtenerMisRecetas(c *fiber.Ctx) error {
	fmt.Println("═══════════════════════════════════")
	fmt.Println("🔍 [ObtenerMisRecetas] Iniciando...")

	userID := c.Locals("user_id")
	if userID == nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "No autorizado"})
	}

	userIDStr, ok := userID.(string)
	if !ok {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Error obteniendo ID del usuario",
		})
	}

	userUUID, err := uuid.Parse(userIDStr)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Error parseando ID del usuario",
		})
	}

	ownerID, rol, err := h.service.ObtenerOwnerIDPorUserID(c.Context(), userUUID)
	if err != nil {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{
			"error": "Solo estudiantes y docentes pueden ver su portafolio",
		})
	}

	fmt.Printf("✅ [ObtenerMisRecetas] Owner ID: %s (rol: %s)\n", ownerID, rol)

	recetas, err := h.service.ObtenerMisRecetas(c.Context(), ownerID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}

	fmt.Printf("✅ [ObtenerMisRecetas] Encontradas %d recetas\n", len(recetas))
	return c.JSON(recetas)
}

// Obtener recetas públicas
func (h *PortafolioHandler) ObtenerPublicas(c *fiber.Ctx) error {
	recetas, err := h.service.ObtenerPublicas(c.Context())
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}

	return c.JSON(recetas)
}

// Obtener detalle de una receta
func (h *PortafolioHandler) ObtenerPorID(c *fiber.Ctx) error {
	idStr := c.Params("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "ID inválido"})
	}

	receta, err := h.service.ObtenerPorID(c.Context(), id)
	if err != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": err.Error()})
	}

	return c.JSON(receta)
}

// ==================== ✨ MODIFICADO: ELIMINAR CON LIMPIEZA DE STORAGE ====================
func (h *PortafolioHandler) Eliminar(c *fiber.Ctx) error {
	idStr := c.Params("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "ID inválido"})
	}

	userID := c.Locals("user_id")
	if userID == nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "No autorizado"})
	}

	userIDStr, ok := userID.(string)
	if !ok {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Error obteniendo ID del usuario",
		})
	}

	userUUID, err := uuid.Parse(userIDStr)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Error parseando ID del usuario",
		})
	}

	ownerID, _, err := h.service.ObtenerOwnerIDPorUserID(c.Context(), userUUID)
	if err != nil {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{
			"error": "No autorizado para eliminar esta receta",
		})
	}

	err = h.service.EliminarConStorage(c.Context(), id, ownerID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}

	return c.JSON(fiber.Map{"message": "Receta eliminada exitosamente"})
}

// ==================== SUBIR IMAGEN ====================

func (h *PortafolioHandler) SubirImagen(c *fiber.Ctx) error {
	file, err := c.FormFile("file")
	if err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Archivo no proporcionado"})
	}

	userID := c.Locals("user_id")
	if userID == nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "No autorizado"})
	}

	userIDStr, ok := userID.(string)
	if !ok {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Error obteniendo ID del usuario",
		})
	}

	folder := "portafolio/" + userIDStr

	fileContent, err := file.Open()
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Error al abrir archivo"})
	}
	defer fileContent.Close()

	url, sizeMB, err := h.storageService.UploadFile(folder, fileContent, file)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}

	return c.JSON(fiber.Map{
		"url":     url,
		"size_mb": sizeMB,
	})
}

// ==================== LIKES ====================

func (h *PortafolioHandler) ToggleLike(c *fiber.Ctx) error {
	idStr := c.Params("id")
	portafolioID, err := uuid.Parse(idStr)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "ID inválido"})
	}

	userID := c.Locals("user_id")
	if userID == nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "No autorizado"})
	}

	userIDStr, ok := userID.(string)
	if !ok {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Error obteniendo ID del usuario",
		})
	}

	usuarioUUID, err := uuid.Parse(userIDStr)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Error parseando ID del usuario",
		})
	}

	liked, err := h.service.ToggleLike(c.Context(), portafolioID, usuarioUUID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}

	message := "Like removido"
	if liked {
		message = "Like agregado"
	}

	return c.JSON(fiber.Map{
		"liked":   liked,
		"message": message,
	})
}

func (h *PortafolioHandler) YaDioLike(c *fiber.Ctx) error {
	idStr := c.Params("id")
	portafolioID, err := uuid.Parse(idStr)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "ID inválido"})
	}

	userID := c.Locals("user_id")
	if userID == nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "No autorizado"})
	}

	userIDStr, ok := userID.(string)
	if !ok {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Error obteniendo ID del usuario",
		})
	}

	usuarioUUID, err := uuid.Parse(userIDStr)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Error parseando ID del usuario",
		})
	}

	yaDioLike, err := h.service.YaDioLike(c.Context(), portafolioID, usuarioUUID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}

	return c.JSON(fiber.Map{"ya_dio_like": yaDioLike})
}

// ==================== COMENTARIOS ====================

func (h *PortafolioHandler) CrearComentario(c *fiber.Ctx) error {
	idStr := c.Params("id")
	portafolioID, err := uuid.Parse(idStr)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "ID inválido"})
	}

	userID := c.Locals("user_id")
	if userID == nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "No autorizado"})
	}

	userIDStr, ok := userID.(string)
	if !ok {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Error obteniendo ID del usuario",
		})
	}

	usuarioUUID, err := uuid.Parse(userIDStr)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Error parseando ID del usuario",
		})
	}

	var req models.CrearComentarioRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": err.Error()})
	}

	comentario, err := h.service.CrearComentario(c.Context(), portafolioID, usuarioUUID, req)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}

	return c.Status(fiber.StatusCreated).JSON(comentario)
}

func (h *PortafolioHandler) ObtenerComentarios(c *fiber.Ctx) error {
	idStr := c.Params("id")
	portafolioID, err := uuid.Parse(idStr)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "ID inválido"})
	}

	comentarios, err := h.service.ObtenerComentarios(c.Context(), portafolioID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}

	return c.JSON(comentarios)
}
