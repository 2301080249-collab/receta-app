package handlers

import (
	"recetario-backend/internal/models"
	"recetario-backend/internal/services"

	"github.com/gofiber/fiber/v2"
)

// ✅ CicloHandler con dependency injection
type CicloHandler struct {
	cicloService *services.CicloService
}

// ✅ Constructor
func NewCicloHandler(cicloService *services.CicloService) *CicloHandler {
	return &CicloHandler{
		cicloService: cicloService,
	}
}

// ✅ Métodos públicos (con mayúscula)

func (h *CicloHandler) CrearCiclo(c *fiber.Ctx) error {
	req := new(models.CrearCicloRequest)

	if err := c.BodyParser(req); err != nil {
		return c.Status(400).JSON(fiber.Map{
			"error": "Datos inválidos",
		})
	}

	cicloID, err := h.cicloService.CrearCiclo(req)
	if err != nil {
		return c.Status(400).JSON(fiber.Map{
			"error": err.Error(),
		})
	}

	return c.Status(201).JSON(fiber.Map{
		"message":  "Ciclo creado exitosamente",
		"ciclo_id": cicloID,
	})
}

func (h *CicloHandler) ListarCiclos(c *fiber.Ctx) error {
	ciclos, err := h.cicloService.ListarCiclos()
	if err != nil {
		return c.Status(500).JSON(fiber.Map{
			"error": "Error al obtener ciclos",
		})
	}

	return c.JSON(ciclos)
}

func (h *CicloHandler) ObtenerCicloPorID(c *fiber.Ctx) error {
	cicloID := c.Params("id")

	if cicloID == "" {
		return c.Status(400).JSON(fiber.Map{
			"error": "ID de ciclo requerido",
		})
	}

	ciclo, err := h.cicloService.ObtenerCicloPorID(cicloID)
	if err != nil {
		return c.Status(404).JSON(fiber.Map{
			"error": err.Error(),
		})
	}

	return c.JSON(ciclo)
}

func (h *CicloHandler) ActualizarCiclo(c *fiber.Ctx) error {
	cicloID := c.Params("id")

	if cicloID == "" {
		return c.Status(400).JSON(fiber.Map{
			"error": "ID de ciclo requerido",
		})
	}

	req := new(models.ActualizarCicloRequest)

	if err := c.BodyParser(req); err != nil {
		return c.Status(400).JSON(fiber.Map{
			"error": "Datos inválidos",
		})
	}

	if err := h.cicloService.ActualizarCiclo(cicloID, req); err != nil {
		return c.Status(400).JSON(fiber.Map{
			"error": err.Error(),
		})
	}

	return c.JSON(fiber.Map{
		"message": "Ciclo actualizado exitosamente",
	})
}

func (h *CicloHandler) EliminarCiclo(c *fiber.Ctx) error {
	cicloID := c.Params("id")

	if cicloID == "" {
		return c.Status(400).JSON(fiber.Map{
			"error": "ID de ciclo requerido",
		})
	}

	if err := h.cicloService.EliminarCiclo(cicloID); err != nil {
		return c.Status(500).JSON(fiber.Map{
			"error": err.Error(),
		})
	}

	return c.JSON(fiber.Map{
		"message": "Ciclo eliminado exitosamente",
	})
}

func (h *CicloHandler) ActivarCiclo(c *fiber.Ctx) error {
	cicloID := c.Params("id")

	if cicloID == "" {
		return c.Status(400).JSON(fiber.Map{
			"error": "ID de ciclo requerido",
		})
	}

	if err := h.cicloService.ActivarCiclo(cicloID); err != nil {
		return c.Status(400).JSON(fiber.Map{
			"error": err.Error(),
		})
	}

	return c.JSON(fiber.Map{
		"message": "Ciclo activado exitosamente",
	})
}

func (h *CicloHandler) DesactivarCiclo(c *fiber.Ctx) error {
	cicloID := c.Params("id")

	if cicloID == "" {
		return c.Status(400).JSON(fiber.Map{
			"error": "ID de ciclo requerido",
		})
	}

	if err := h.cicloService.DesactivarCiclo(cicloID); err != nil {
		return c.Status(400).JSON(fiber.Map{
			"error": err.Error(),
		})
	}

	return c.JSON(fiber.Map{
		"message": "Ciclo desactivado exitosamente",
	})
}

func (h *CicloHandler) ObtenerCicloActivo(c *fiber.Ctx) error {
	ciclo, err := h.cicloService.ObtenerCicloActivo()
	if err != nil {
		return c.Status(404).JSON(fiber.Map{
			"error": "No hay ciclo activo",
		})
	}

	return c.JSON(ciclo)
}
