package handlers

import (
	"recetario-backend/internal/models"
	"recetario-backend/internal/services"

	"github.com/gofiber/fiber/v2"
)

// ✅ CursoHandler con dependency injection
type CursoHandler struct {
	cursoService *services.CursoService
}

// ✅ Constructor
func NewCursoHandler(cursoService *services.CursoService) *CursoHandler {
	return &CursoHandler{
		cursoService: cursoService,
	}
}

// ✅ Métodos públicos (con mayúscula)

func (h *CursoHandler) CrearCurso(c *fiber.Ctx) error {
	req := new(models.CrearCursoRequest)

	if err := c.BodyParser(req); err != nil {
		return c.Status(400).JSON(fiber.Map{
			"error": "Datos inválidos",
		})
	}

	cursoID, err := h.cursoService.CrearCurso(req)
	if err != nil {
		return c.Status(400).JSON(fiber.Map{
			"error": err.Error(),
		})
	}

	return c.Status(201).JSON(fiber.Map{
		"message":  "Curso creado exitosamente",
		"curso_id": cursoID,
	})
}

func (h *CursoHandler) ListarCursos(c *fiber.Ctx) error {
	// Filtros opcionales
	cicloID := c.Query("ciclo_id")
	docenteID := c.Query("docente_id")

	var cursos []models.Curso
	var err error

	if cicloID != "" {
		cursos, err = h.cursoService.ListarCursosPorCiclo(cicloID)
	} else if docenteID != "" {
		cursos, err = h.cursoService.ListarCursosPorDocente(docenteID)
	} else {
		cursos, err = h.cursoService.ListarCursos()
	}

	if err != nil {
		return c.Status(500).JSON(fiber.Map{
			"error": "Error al obtener cursos",
		})
	}

	return c.JSON(cursos)
}

func (h *CursoHandler) ObtenerCursoPorID(c *fiber.Ctx) error {
	cursoID := c.Params("id")

	if cursoID == "" {
		return c.Status(400).JSON(fiber.Map{
			"error": "ID de curso requerido",
		})
	}

	curso, err := h.cursoService.ObtenerCursoPorID(cursoID)
	if err != nil {
		return c.Status(404).JSON(fiber.Map{
			"error": err.Error(),
		})
	}

	return c.JSON(curso)
}

func (h *CursoHandler) ActualizarCurso(c *fiber.Ctx) error {
	cursoID := c.Params("id")

	if cursoID == "" {
		return c.Status(400).JSON(fiber.Map{
			"error": "ID de curso requerido",
		})
	}

	req := new(models.ActualizarCursoRequest)

	if err := c.BodyParser(req); err != nil {
		return c.Status(400).JSON(fiber.Map{
			"error": "Datos inválidos",
		})
	}

	if err := h.cursoService.ActualizarCurso(cursoID, req); err != nil {
		return c.Status(400).JSON(fiber.Map{
			"error": err.Error(),
		})
	}

	return c.JSON(fiber.Map{
		"message": "Curso actualizado exitosamente",
	})
}

func (h *CursoHandler) EliminarCurso(c *fiber.Ctx) error {
	cursoID := c.Params("id")

	if cursoID == "" {
		return c.Status(400).JSON(fiber.Map{
			"error": "ID de curso requerido",
		})
	}

	if err := h.cursoService.EliminarCurso(cursoID); err != nil {
		return c.Status(500).JSON(fiber.Map{
			"error": err.Error(),
		})
	}

	return c.JSON(fiber.Map{
		"message": "Curso eliminado exitosamente",
	})
}

func (h *CursoHandler) ActivarCurso(c *fiber.Ctx) error {
	cursoID := c.Params("id")

	if cursoID == "" {
		return c.Status(400).JSON(fiber.Map{
			"error": "ID de curso requerido",
		})
	}

	if err := h.cursoService.ActivarCurso(cursoID); err != nil {
		return c.Status(400).JSON(fiber.Map{
			"error": err.Error(),
		})
	}

	return c.JSON(fiber.Map{
		"message": "Curso activado exitosamente",
	})
}

func (h *CursoHandler) DesactivarCurso(c *fiber.Ctx) error {
	cursoID := c.Params("id")

	if cursoID == "" {
		return c.Status(400).JSON(fiber.Map{
			"error": "ID de curso requerido",
		})
	}

	if err := h.cursoService.DesactivarCurso(cursoID); err != nil {
		return c.Status(400).JSON(fiber.Map{
			"error": err.Error(),
		})
	}

	return c.JSON(fiber.Map{
		"message": "Curso desactivado exitosamente",
	})
}

// ✅ NUEVO: Obtener cursos del estudiante
func (h *CursoHandler) ListarCursosPorEstudiante(c *fiber.Ctx) error {
	estudianteID := c.Params("estudiante_id")

	if estudianteID == "" {
		return c.Status(400).JSON(fiber.Map{
			"error": "ID de estudiante requerido",
		})
	}

	cursos, err := h.cursoService.ListarCursosPorEstudiante(estudianteID)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{
			"error": "Error al obtener cursos del estudiante",
		})
	}

	return c.JSON(cursos)
}
