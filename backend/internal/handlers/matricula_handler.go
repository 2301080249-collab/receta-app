package handlers

import (
	"recetario-backend/internal/models"
	"recetario-backend/internal/services"

	"github.com/gofiber/fiber/v2"
)

// ✅ MatriculaHandler con dependency injection
type MatriculaHandler struct {
	matriculaService *services.MatriculaService
}

// ✅ Constructor
func NewMatriculaHandler(matriculaService *services.MatriculaService) *MatriculaHandler {
	return &MatriculaHandler{
		matriculaService: matriculaService,
	}
}

// ✅ Métodos públicos (con mayúscula)

func (h *MatriculaHandler) CrearMatricula(c *fiber.Ctx) error {
	req := new(models.CrearMatriculaRequest)

	if err := c.BodyParser(req); err != nil {
		return c.Status(400).JSON(fiber.Map{
			"error": "Datos inválidos en el formato JSON",
		})
	}

	matricula, err := h.matriculaService.CrearMatricula(req)
	if err != nil {
		return c.Status(400).JSON(fiber.Map{
			"error": err.Error(),
		})
	}

	return c.Status(201).JSON(fiber.Map{
		"message":   "Matrícula creada exitosamente",
		"matricula": matricula,
	})
}

func (h *MatriculaHandler) CrearMatriculaMasiva(c *fiber.Ctx) error {
	req := new(models.MatriculaMasivaRequest)

	if err := c.BodyParser(req); err != nil {
		return c.Status(400).JSON(fiber.Map{
			"error": "Datos inválidos en el formato JSON",
		})
	}

	if len(req.EstudiantesIDs) == 0 {
		return c.Status(400).JSON(fiber.Map{
			"error": "Debe seleccionar al menos un estudiante",
		})
	}

	matriculas, errores, err := h.matriculaService.CrearMatriculaMasiva(req)

	if err != nil {
		return c.Status(207).JSON(fiber.Map{
			"message":    "Proceso completado con advertencias",
			"matriculas": matriculas,
			"exitosos":   len(matriculas),
			"fallidos":   len(errores),
			"errores":    errores,
		})
	}

	return c.Status(201).JSON(fiber.Map{
		"message":    "Todos los estudiantes fueron matriculados exitosamente",
		"matriculas": matriculas,
		"total":      len(matriculas),
	})
}

func (h *MatriculaHandler) ListarMatriculasPorCurso(c *fiber.Ctx) error {
	cursoID := c.Params("curso_id")

	if cursoID == "" {
		return c.Status(400).JSON(fiber.Map{
			"error": "ID del curso requerido",
		})
	}

	matriculas, err := h.matriculaService.ListarMatriculasPorCurso(cursoID)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{
			"error": err.Error(),
		})
	}

	return c.JSON(matriculas)
}

// ✅ NUEVO: Exportar participantes de un curso a Excel
func (h *MatriculaHandler) ExportarParticipantesExcel(c *fiber.Ctx) error {
	cursoID := c.Params("curso_id")

	if cursoID == "" {
		return c.Status(400).JSON(fiber.Map{
			"error": "ID del curso requerido",
		})
	}

	// Generar el archivo Excel
	excelBuffer, nombreCurso, err := h.matriculaService.ExportarParticipantesExcel(cursoID)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{
			"error": err.Error(),
		})
	}

	// Configurar headers para descarga
	filename := "Participantes_" + nombreCurso + ".xlsx"
	c.Set("Content-Type", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
	c.Set("Content-Disposition", "attachment; filename="+filename)
	c.Set("Content-Length", string(rune(len(excelBuffer.Bytes()))))

	return c.Send(excelBuffer.Bytes())
}

func (h *MatriculaHandler) ListarMatriculasPorEstudiante(c *fiber.Ctx) error {
	estudianteID := c.Params("estudiante_id")

	if estudianteID == "" {
		return c.Status(400).JSON(fiber.Map{
			"error": "ID del estudiante requerido",
		})
	}

	matriculas, err := h.matriculaService.ListarMatriculasPorEstudiante(estudianteID)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{
			"error": err.Error(),
		})
	}

	return c.JSON(matriculas)
}

func (h *MatriculaHandler) ListarEstudiantesDisponibles(c *fiber.Ctx) error {
	cursoID := c.Query("curso_id")
	cicloID := c.Query("ciclo_id")

	if cursoID == "" || cicloID == "" {
		return c.Status(400).JSON(fiber.Map{
			"error": "Se requiere curso_id y ciclo_id como parámetros",
		})
	}

	estudiantes, err := h.matriculaService.ListarEstudiantesDisponibles(cursoID, cicloID)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{
			"error": err.Error(),
		})
	}

	return c.JSON(estudiantes)
}

func (h *MatriculaHandler) ActualizarMatricula(c *fiber.Ctx) error {
	matriculaID := c.Params("id")

	if matriculaID == "" {
		return c.Status(400).JSON(fiber.Map{
			"error": "ID de matrícula requerido",
		})
	}

	req := new(models.ActualizarMatriculaRequest)
	if err := c.BodyParser(req); err != nil {
		return c.Status(400).JSON(fiber.Map{
			"error": "Datos inválidos",
		})
	}

	if err := h.matriculaService.ActualizarMatricula(matriculaID, req); err != nil {
		return c.Status(400).JSON(fiber.Map{
			"error": err.Error(),
		})
	}

	return c.JSON(fiber.Map{
		"message": "Matrícula actualizada exitosamente",
	})
}

func (h *MatriculaHandler) EliminarMatricula(c *fiber.Ctx) error {
	matriculaID := c.Params("id")

	if matriculaID == "" {
		return c.Status(400).JSON(fiber.Map{
			"error": "ID de matrícula requerido",
		})
	}

	if err := h.matriculaService.EliminarMatricula(matriculaID); err != nil {
		return c.Status(500).JSON(fiber.Map{
			"error": err.Error(),
		})
	}

	return c.JSON(fiber.Map{
		"message": "Matrícula eliminada exitosamente",
	})
}

func (h *MatriculaHandler) ListarTodasLasMatriculas(c *fiber.Ctx) error {
	matriculas, err := h.matriculaService.ListarTodasLasMatriculas()
	if err != nil {
		return c.Status(500).JSON(fiber.Map{
			"error": err.Error(),
		})
	}

	// ✅ Enviar el JSON crudo directamente
	c.Set("Content-Type", "application/json")
	return c.Send(matriculas)
}
