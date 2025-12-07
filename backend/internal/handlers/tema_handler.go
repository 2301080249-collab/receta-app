package handlers

import (
	"fmt" // ✅ AGREGAR ESTA LÍNEA
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

	fmt.Printf("🔍 BACKEND: ListarTemasPorCurso - cursoID: %s\n", cursoID)

	if cursoID == "" {
		fmt.Println("❌ BACKEND: cursoID vacío")
		return c.Status(400).JSON(fiber.Map{"error": "ID de curso requerido"})
	}

	// ✅ EXTRAER USER_ID DEL MIDDLEWARE DE AUTENTICACIÓN
	userID := c.Locals("user_id") // Esto viene del middleware auth

	fmt.Printf("🔍 BACKEND: user_id del contexto: %v\n", userID)

	temas, err := h.temaService.GetTemasByCursoID(cursoID, userID)
	if err != nil {
		fmt.Printf("❌ BACKEND: Error: %v\n", err)
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}

	fmt.Printf("✅ BACKEND: Devolviendo %d temas\n", len(temas))

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

// GET /api/temas/:id
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
