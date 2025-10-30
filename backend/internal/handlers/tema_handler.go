package handlers

import (
	"recetario-backend/internal/services"

	"github.com/gofiber/fiber/v2"
)

type TemaHandler struct {
	temaService *services.TemaService
}

func NewTemaHandler(temaService *services.TemaService) *TemaHandler {
	return &TemaHandler{temaService: temaService}
}

// GET /api/cursos/:id/temas
// GET /api/cursos/:id/temas
func (h *TemaHandler) ListarTemasPorCurso(c *fiber.Ctx) error {
	cursoID := c.Params("id")

	if cursoID == "" {
		return c.Status(400).JSON(fiber.Map{"error": "ID de curso requerido"})
	}

	temas, err := h.temaService.GetTemasByCursoID(cursoID)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}

	return c.JSON(temas)
}

// POST /api/temas
func (h *TemaHandler) CrearTema(c *fiber.Ctx) error {
	var data map[string]interface{}
	if err := c.BodyParser(&data); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Datos inválidos"})
	}

	tema, err := h.temaService.CrearTema(data)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}

	return c.Status(201).JSON(tema)
}

// PATCH /api/temas/:id
func (h *TemaHandler) ActualizarTema(c *fiber.Ctx) error {
	temaID := c.Params("id")

	if temaID == "" {
		return c.Status(400).JSON(fiber.Map{"error": "ID requerido"})
	}

	var data map[string]interface{}
	if err := c.BodyParser(&data); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Datos inválidos"})
	}

	if err := h.temaService.ActualizarTema(temaID, data); err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}

	return c.JSON(fiber.Map{"message": "Tema actualizado exitosamente"})
}

// DELETE /api/temas/:id
func (h *TemaHandler) EliminarTema(c *fiber.Ctx) error {
	temaID := c.Params("id")

	if temaID == "" {
		return c.Status(400).JSON(fiber.Map{"error": "ID requerido"})
	}

	if err := h.temaService.EliminarTema(temaID); err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}

	return c.JSON(fiber.Map{"message": "Tema eliminado exitosamente"})
}

// GET /api/temas/:id - Obtener detalle de un tema con materiales y tareas
// GET /api/temas/:id - Obtener detalle de un tema con materiales y tareas
func (h *TemaHandler) ObtenerTema(c *fiber.Ctx) error {
	temaID := c.Params("id")

	if temaID == "" {
		return c.Status(400).JSON(fiber.Map{"error": "ID de tema requerido"})
	}

	tema, err := h.temaService.GetTemaByID(temaID)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}

	return c.JSON(tema)
}
