package handlers

import (
	"recetario-backend/internal/models"
	"recetario-backend/internal/services"

	"github.com/gofiber/fiber/v2"
)

type DashboardHandler struct {
	dashboardService *services.DashboardService
}

func NewDashboardHandler(dashboardService *services.DashboardService) *DashboardHandler {
	return &DashboardHandler{
		dashboardService: dashboardService,
	}
}

// ObtenerEstadisticas maneja la obtención de estadísticas del dashboard con filtros
func (h *DashboardHandler) ObtenerEstadisticas(c *fiber.Ctx) error {
	// Obtener parámetros de query (filtros opcionales)
	filtros := models.DashboardFilters{
		CicloID: c.Query("ciclo_id", ""),
		Seccion: c.Query("seccion", ""),
		Estado:  c.Query("estado", "todos"),
	}

	// Obtener estadísticas
	stats, err := h.dashboardService.ObtenerEstadisticasCompletas(filtros)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{
			"error":   "Error al obtener estadísticas del dashboard",
			"details": err.Error(),
		})
	}

	return c.JSON(stats)
}
