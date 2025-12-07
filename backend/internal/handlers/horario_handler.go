package handlers

import (
	"recetario-backend/internal/services"

	"github.com/gofiber/fiber/v2"
)

type HorarioHandler struct {
	cursoService *services.CursoService
}

func NewHorarioHandler(cursoService *services.CursoService) *HorarioHandler {
	return &HorarioHandler{
		cursoService: cursoService,
	}
}

// ObtenerHorarioDocente devuelve el horario semanal del docente
func (h *HorarioHandler) ObtenerHorarioDocente(c *fiber.Ctx) error {
	docenteID := c.Params("docente_id")

	if docenteID == "" {
		return c.Status(400).JSON(fiber.Map{
			"error": "ID de docente requerido",
		})
	}

	// Obtener cursos del docente
	cursos, err := h.cursoService.ListarCursosPorDocente(docenteID)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{
			"error": "Error al obtener horario del docente",
		})
	}

	// Construir respuesta con información relevante para el horario
	horario := make([]map[string]interface{}, 0)
	for _, curso := range cursos {
		horarioInfo := map[string]interface{}{
			"curso_id":       curso.ID,
			"nombre":         curso.Nombre,
			"ciclo_id":       curso.CicloID,
			"ciclo_nombre":   curso.Ciclo.Nombre,
			"nivel":          curso.Nivel,
			"seccion":        curso.Seccion,
			"horario":        curso.Horario,
			"activo":         curso.Activo,
			"docente_nombre": nil, // El docente no necesita ver su propio nombre
		}
		horario = append(horario, horarioInfo)
	}

	return c.JSON(horario)
}

// ObtenerHorarioEstudiante devuelve el horario semanal del estudiante
func (h *HorarioHandler) ObtenerHorarioEstudiante(c *fiber.Ctx) error {
	estudianteID := c.Params("estudiante_id")

	if estudianteID == "" {
		return c.Status(400).JSON(fiber.Map{
			"error": "ID de estudiante requerido",
		})
	}

	// Obtener cursos del estudiante a través de sus matrículas
	cursos, err := h.cursoService.ListarCursosPorEstudiante(estudianteID)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{
			"error": "Error al obtener horario del estudiante",
		})
	}

	// Construir respuesta con información relevante para el horario
	horario := make([]map[string]interface{}, 0)
	for _, curso := range cursos {
		// ✅ CORREGIDO: Obtener nombre del docente de forma segura
		var docenteNombre interface{} = nil

		// Verificar si DocenteID no está vacío
		if curso.DocenteID != "" {
			// Verificar si la relación Docente existe
			if curso.Docente != nil {
				// Verificar si el Usuario del Docente tiene nombre completo
				if curso.Docente.Usuario.NombreCompleto != "" {
					docenteNombre = curso.Docente.Usuario.NombreCompleto
				}
			}
		}

		horarioInfo := map[string]interface{}{
			"curso_id":       curso.ID,
			"nombre":         curso.Nombre,
			"ciclo_id":       curso.CicloID,
			"ciclo_nombre":   curso.Ciclo.Nombre,
			"nivel":          curso.Nivel,
			"seccion":        curso.Seccion,
			"horario":        curso.Horario,
			"activo":         curso.Activo,
			"docente_nombre": docenteNombre, // ✅ Nombre del docente o nil
		}
		horario = append(horario, horarioInfo)
	}

	return c.JSON(horario)
}
