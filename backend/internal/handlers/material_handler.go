package handlers

import (
	"recetario-backend/internal/models"
	"recetario-backend/internal/services"

	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
)

type MaterialHandler struct {
	materialService *services.MaterialService
	storageService  *services.StorageService
}

func NewMaterialHandler(
	materialService *services.MaterialService,
	storageService *services.StorageService,
) *MaterialHandler {
	return &MaterialHandler{
		materialService: materialService,
		storageService:  storageService,
	}
}

// POST /api/materiales
func (h *MaterialHandler) CrearMaterial(c *fiber.Ctx) error {
	var req models.CreateMaterialRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": err.Error()})
	}

	material, err := h.materialService.CrearMaterial(c.Context(), &req)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}

	return c.Status(201).JSON(material)
}

// ✅ NUEVO: PUT /api/materiales/:id
func (h *MaterialHandler) ActualizarMaterial(c *fiber.Ctx) error {
	id, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "ID inválido"})
	}

	var req models.UpdateMaterialRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": err.Error()})
	}

	material, err := h.materialService.ActualizarMaterial(c.Context(), id, &req)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}

	return c.JSON(fiber.Map{
		"data": material,
	})
}

// POST /api/materiales/upload
func (h *MaterialHandler) SubirArchivo(c *fiber.Ctx) error {
	file, err := c.FormFile("file")
	if err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Archivo no proporcionado"})
	}

	temaID := c.FormValue("tema_id")
	folder := "materiales/" + temaID

	// Abrir el archivo
	fileContent, err := file.Open()
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Error al abrir archivo"})
	}
	defer fileContent.Close()

	// ✅ CORREGIDO: UploadFile retorna (url, tamanoMB, error)
	url, sizeMB, err := h.storageService.UploadFile(folder, fileContent, file)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}

	return c.JSON(fiber.Map{
		"data": fiber.Map{
			"url":     url,
			"size_mb": sizeMB, // Ya viene calculado
		},
	})
}

// POST /api/materiales/:id/marcar-visto
func (h *MaterialHandler) MarcarComoVisto(c *fiber.Ctx) error {
	materialID, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "ID inválido"})
	}

	estudianteID, _ := uuid.Parse(c.Locals("user_id").(string))

	if err := h.materialService.MarcarComoVisto(c.Context(), materialID, estudianteID); err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}

	return c.JSON(fiber.Map{"message": "Material marcado como visto"})
}

// GET /api/temas/:id/materiales
func (h *MaterialHandler) ListarMaterialesPorTema(c *fiber.Ctx) error {
	temaID := c.Params("id")
	if temaID == "" {
		return c.Status(400).JSON(fiber.Map{"error": "ID de tema requerido"})
	}

	// TODO: Implementar método en MaterialService
	return c.JSON(fiber.Map{"message": "Función por implementar"})
}

// DELETE /api/materiales/:id
func (h *MaterialHandler) EliminarMaterial(c *fiber.Ctx) error {
	id, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "ID inválido"})
	}

	if err := h.materialService.EliminarMaterial(c.Context(), id); err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}

	return c.JSON(fiber.Map{"message": "Material eliminado"})
}
