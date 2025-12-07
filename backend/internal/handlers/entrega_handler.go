package handlers

import (
	"log"
	"recetario-backend/internal/models"
	"recetario-backend/internal/services"

	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
)

type EntregaHandler struct {
	entregaService *services.EntregaService
	tareaService   *services.TareaService
	storageService *services.StorageService
}

func NewEntregaHandler(
	entregaService *services.EntregaService,
	tareaService *services.TareaService,
	storageService *services.StorageService,
) *EntregaHandler {
	return &EntregaHandler{
		entregaService: entregaService,
		tareaService:   tareaService,
		storageService: storageService,
	}
}

// POST /api/entregas (estudiante entrega tarea)
func (h *EntregaHandler) CrearEntrega(c *fiber.Ctx) error {
	var req models.CreateEntregaRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Datos inválidos: " + err.Error()})
	}

	// DEBUG
	userID := c.Locals("user_id")
	log.Printf("✅ Usuario autenticado: %v", userID)
	log.Printf("🔍 DEBUG - tarea_id: %s", req.TareaID)
	log.Printf("🔍 DEBUG - titulo: %s", req.Titulo)

	if userID == nil {
		return c.Status(401).JSON(fiber.Map{"error": "No autenticado - user_id no encontrado"})
	}

	estudianteID, err := uuid.Parse(userID.(string))
	if err != nil {
		log.Printf("❌ ERROR parsing UUID: %v", err)
		return c.Status(400).JSON(fiber.Map{"error": "ID de usuario inválido: " + err.Error()})
	}

	entrega, err := h.entregaService.CrearEntrega(c.Context(), estudianteID, &req)
	if err != nil {
		log.Printf("❌ ERROR creando entrega: %v", err)
		return c.Status(400).JSON(fiber.Map{"error": err.Error()})
	}

	log.Printf("✅ Entrega creada exitosamente: %s", entrega.ID)
	return c.Status(201).JSON(entrega)
}

// POST /api/entregas/:id/archivos
func (h *EntregaHandler) SubirArchivoEntrega(c *fiber.Ctx) error {
	entregaID, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "ID inválido"})
	}

	file, err := c.FormFile("file")
	if err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Archivo no proporcionado"})
	}

	folder := "entregas/" + entregaID.String()

	// Abrir el archivo
	fileContent, err := file.Open()
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Error al abrir archivo"})
	}
	defer fileContent.Close()

	// Subir a Storage (retorna url, tamanoMB, error)
	url, tamanoMB, err := h.storageService.UploadFile(folder, fileContent, file)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}

	// Guardar referencia en BD
	tipoArchivo := file.Header.Get("Content-Type")

	archivo := &models.ArchivoEntrega{
		EntregaID:     entregaID,
		NombreArchivo: file.Filename,
		URLArchivo:    url,
		TipoArchivo:   &tipoArchivo,
		TamanoMB:      &tamanoMB,
	}

	if err := h.entregaService.AgregarArchivo(c.Context(), entregaID, archivo); err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}

	log.Printf("✅ Archivo subido: %s", file.Filename)
	return c.JSON(archivo)
}

// GET /api/tareas/:id/entregas (docente ve todas las entregas)
func (h *EntregaHandler) ObtenerEntregasDeTarea(c *fiber.Ctx) error {
	tareaID, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "ID inválido"})
	}

	entregas, err := h.tareaService.ObtenerEntregasDeTarea(c.Context(), tareaID)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}

	return c.JSON(entregas)
}

// ✅ NUEVO: Exportar entregas de una tarea a Excel
func (h *EntregaHandler) ExportarEntregasExcel(c *fiber.Ctx) error {
	tareaID, err := uuid.Parse(c.Params("tarea_id"))
	if err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "ID de tarea inválido"})
	}

	// Generar el archivo Excel
	excelBuffer, nombreTarea, err := h.tareaService.ExportarEntregasExcel(c.Context(), tareaID)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}

	// Configurar headers para descarga
	filename := "Entregas_" + nombreTarea + ".xlsx"
	c.Set("Content-Type", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
	c.Set("Content-Disposition", "attachment; filename="+filename)
	c.Set("Content-Length", string(rune(len(excelBuffer.Bytes()))))

	return c.Send(excelBuffer.Bytes())
}

// GET /api/tareas/:id/mi-entrega (estudiante ve su entrega)
func (h *EntregaHandler) ObtenerMiEntrega(c *fiber.Ctx) error {
	tareaID, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "ID inválido"})
	}

	estudianteID, _ := uuid.Parse(c.Locals("user_id").(string))

	entrega, err := h.entregaService.ObtenerMiEntrega(c.Context(), tareaID, estudianteID)
	if err != nil {
		return c.Status(404).JSON(fiber.Map{"error": "No has entregado esta tarea"})
	}

	return c.JSON(entrega)
}

// PUT /api/entregas/:id/calificar (docente califica)
func (h *EntregaHandler) CalificarEntrega(c *fiber.Ctx) error {
	entregaID, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "ID inválido"})
	}

	var req models.CalificarEntregaRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": err.Error()})
	}

	if err := h.tareaService.CalificarEntrega(c.Context(), entregaID, &req); err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}

	return c.JSON(fiber.Map{"message": "Entrega calificada exitosamente"})
}

// GET /api/entregas/:id
func (h *EntregaHandler) ObtenerEntregaPorID(c *fiber.Ctx) error {
	entregaID, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "ID inválido"})
	}

	entrega, err := h.entregaService.ObtenerEntregaPorID(c.Context(), entregaID)
	if err != nil {
		return c.Status(404).JSON(fiber.Map{"error": "Entrega no encontrada"})
	}

	return c.JSON(entrega)
}

// PUT /api/entregas/:id (editar entrega)
func (h *EntregaHandler) EditarEntrega(c *fiber.Ctx) error {
	entregaID, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "ID inválido"})
	}

	userID := c.Locals("user_id")
	if userID == nil {
		return c.Status(401).JSON(fiber.Map{"error": "No autenticado"})
	}

	var req models.CreateEntregaRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": err.Error()})
	}

	// Validar que sea el dueño de la entrega
	estudianteID, _ := uuid.Parse(userID.(string))
	if err := h.entregaService.ValidarPropietario(c.Context(), entregaID, estudianteID); err != nil {
		return c.Status(403).JSON(fiber.Map{"error": "No tienes permiso para editar esta entrega"})
	}

	if err := h.entregaService.EditarEntrega(c.Context(), entregaID, &req); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": err.Error()})
	}

	log.Printf("✅ Entrega editada: %s", entregaID)
	return c.JSON(fiber.Map{"message": "Entrega actualizada exitosamente"})
}

// DELETE /api/entregas/:id (eliminar entrega completa)
func (h *EntregaHandler) EliminarEntrega(c *fiber.Ctx) error {
	entregaID, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "ID inválido"})
	}

	userID := c.Locals("user_id")
	if userID == nil {
		return c.Status(401).JSON(fiber.Map{"error": "No autenticado"})
	}

	estudianteID, _ := uuid.Parse(userID.(string))

	log.Printf("🗑️ Eliminando entrega: %s por usuario: %s", entregaID, estudianteID)

	// Validar que sea el dueño
	if err := h.entregaService.ValidarPropietario(c.Context(), entregaID, estudianteID); err != nil {
		return c.Status(403).JSON(fiber.Map{"error": "No tienes permiso para eliminar esta entrega"})
	}

	// ✅ MEJORADO: Obtener archivos ANTES de eliminar la entrega
	archivos, err := h.entregaService.ObtenerArchivosPorEntregaID(c.Context(), entregaID)
	if err != nil {
		log.Printf("⚠️ No se pudieron obtener archivos: %v", err)
	}

	// ✅ Eliminar archivos del Storage
	for _, archivo := range archivos {
		if err := h.storageService.DeleteFile(archivo.URLArchivo); err != nil {
			log.Printf("⚠️ No se pudo eliminar archivo del Storage: %s - %v", archivo.NombreArchivo, err)
		} else {
			log.Printf("✅ Archivo eliminado del Storage: %s", archivo.NombreArchivo)
		}
	}

	// Eliminar entrega (esto eliminará en cascada los registros de archivos)
	if err := h.entregaService.EliminarEntrega(c.Context(), entregaID); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": err.Error()})
	}

	log.Printf("✅ Entrega eliminada exitosamente: %s", entregaID)
	return c.Status(204).JSON(fiber.Map{"message": "Entrega eliminada exitosamente"})
}

// ✅ NUEVO: DELETE /api/entregas/archivos/:archivoId (eliminar archivo individual)
func (h *EntregaHandler) EliminarArchivoEntrega(c *fiber.Ctx) error {
	archivoID, err := uuid.Parse(c.Params("archivoId"))
	if err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "ID inválido"})
	}

	log.Printf("🗑️ Eliminando archivo individual: %s", archivoID)

	// Obtener info del archivo
	archivo, err := h.entregaService.ObtenerArchivoPorID(c.Context(), archivoID)
	if err != nil {
		log.Printf("❌ Error al obtener archivo: %v", err)
		return c.Status(404).JSON(fiber.Map{"error": "Archivo no encontrado"})
	}

	// Eliminar del Storage
	if err := h.storageService.DeleteFile(archivo.URLArchivo); err != nil {
		log.Printf("⚠️ Advertencia: No se pudo eliminar del Storage: %v", err)
		// Continuar aunque falle el Storage
	} else {
		log.Printf("✅ Archivo eliminado del Storage: %s", archivo.NombreArchivo)
	}

	// Eliminar registro de la base de datos
	if err := h.entregaService.EliminarArchivo(c.Context(), archivoID); err != nil {
		log.Printf("❌ Error al eliminar registro: %v", err)
		return c.Status(500).JSON(fiber.Map{"error": "Error al eliminar archivo"})
	}

	log.Printf("✅ Archivo eliminado exitosamente: %s", archivoID)
	return c.Status(204).SendString("")
}
