package handlers

import (
	"recetario-backend/internal/models"
	"recetario-backend/internal/services"

	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
)

type TareaHandler struct {
	tareaService   *services.TareaService
	entregaService *services.EntregaService
}

func NewTareaHandler(tareaService *services.TareaService, entregaService *services.EntregaService) *TareaHandler {
	return &TareaHandler{
		tareaService:   tareaService,
		entregaService: entregaService,
	}
}

// POST /api/tareas
func (h *TareaHandler) CrearTarea(c *fiber.Ctx) error {
	var req models.CreateTareaRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": err.Error()})
	}

	tarea, err := h.tareaService.CrearTarea(c.Context(), &req)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}

	return c.Status(201).JSON(tarea)
}

// GET /api/temas/:id/tareas
func (h *TareaHandler) ListarTareasPorTema(c *fiber.Ctx) error {
	temaID := c.Params("id")
	if temaID == "" {
		return c.Status(400).JSON(fiber.Map{"error": "ID de tema requerido"})
	}

	temaUUID, err := uuid.Parse(temaID)
	if err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "ID de tema inválido"})
	}

	tareas, err := h.tareaService.GetTareasByTemaID(c.Context(), temaUUID)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}

	return c.JSON(tareas)
}

// GET /api/tareas/:id/entregas - NUEVO ENDPOINT
func (h *TareaHandler) GetEntregasPorTarea(c *fiber.Ctx) error {
	tareaID := c.Params("id")
	if tareaID == "" {
		return c.Status(400).JSON(fiber.Map{"error": "ID de tarea requerido"})
	}

	tareaUUID, err := uuid.Parse(tareaID)
	if err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "ID de tarea inválido"})
	}

	entregas, err := h.entregaService.GetEntregasConEstudiante(c.Context(), tareaUUID)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}

	return c.JSON(entregas)
}

// GET /api/tareas/:id
func (h *TareaHandler) ObtenerTarea(c *fiber.Ctx) error {
	tareaID := c.Params("id")
	if tareaID == "" {
		return c.Status(400).JSON(fiber.Map{"error": "ID de tarea requerido"})
	}

	tareaUUID, err := uuid.Parse(tareaID)
	if err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "ID de tarea inválido"})
	}

	tarea, err := h.tareaService.GetTareaByID(c.Context(), tareaUUID)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}

	return c.JSON(tarea)
}

// PUT /api/tareas/:id
func (h *TareaHandler) ActualizarTarea(c *fiber.Ctx) error {
	tareaID := c.Params("id")
	if tareaID == "" {
		return c.Status(400).JSON(fiber.Map{"error": "ID requerido"})
	}

	tareaUUID, err := uuid.Parse(tareaID)
	if err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "ID inválido"})
	}

	var req models.CreateTareaRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": err.Error()})
	}

	if err := h.tareaService.UpdateTarea(c.Context(), tareaUUID, &req); err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}

	return c.JSON(fiber.Map{"message": "Tarea actualizada exitosamente"})
}

// DELETE /api/tareas/:id
func (h *TareaHandler) EliminarTarea(c *fiber.Ctx) error {
	tareaID := c.Params("id")
	if tareaID == "" {
		return c.Status(400).JSON(fiber.Map{"error": "ID requerido"})
	}

	tareaUUID, err := uuid.Parse(tareaID)
	if err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "ID inválido"})
	}

	if err := h.tareaService.DeleteTarea(c.Context(), tareaUUID); err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}

	return c.Status(204).Send(nil)
}
