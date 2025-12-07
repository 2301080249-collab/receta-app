package services

import (
	"bytes"
	"context"
	"fmt"

	"recetario-backend/internal/models"
	"recetario-backend/internal/repository"

	"github.com/google/uuid"
	"github.com/xuri/excelize/v2"
)

type TareaService struct {
	tareaRepo   *repository.TareaRepository
	entregaRepo *repository.EntregaRepository
}

func NewTareaService(
	tareaRepo *repository.TareaRepository,
	entregaRepo *repository.EntregaRepository,
) *TareaService {
	return &TareaService{
		tareaRepo:   tareaRepo,
		entregaRepo: entregaRepo,
	}
}

// Crear tarea
func (s *TareaService) CrearTarea(ctx context.Context, req *models.CreateTareaRequest) (*models.Tarea, error) {
	return s.tareaRepo.Create(ctx, req)
}

// Obtener entregas de una tarea (para docente)
func (s *TareaService) ObtenerEntregasDeTarea(ctx context.Context, tareaID uuid.UUID) ([]models.Entrega, error) {
	entregas, err := s.entregaRepo.GetByTareaID(ctx, tareaID)
	if err != nil {
		return nil, fmt.Errorf("error obteniendo entregas: %w", err)
	}

	// Para cada entrega, cargar archivos
	for i := range entregas {
		archivos, err := s.entregaRepo.GetArchivosByEntregaID(ctx, entregas[i].ID)
		if err != nil {
			return nil, fmt.Errorf("error obteniendo archivos: %w", err)
		}
		entregas[i].Archivos = archivos
	}

	return entregas, nil
}

// Calificar entrega
func (s *TareaService) CalificarEntrega(ctx context.Context, entregaID uuid.UUID, req *models.CalificarEntregaRequest) error {
	return s.entregaRepo.Calificar(ctx, entregaID, req.Calificacion, req.ComentarioDocente)
}

// ========================================
// NUEVOS MÉTODOS QUE FALTABAN
// ========================================

// Obtener tareas por tema ID
func (s *TareaService) GetTareasByTemaID(ctx context.Context, temaID uuid.UUID) ([]models.Tarea, error) {
	tareas, err := s.tareaRepo.GetByTemaID(ctx, temaID)
	if err != nil {
		return nil, fmt.Errorf("error obteniendo tareas: %w", err)
	}
	return tareas, nil
}

// Obtener tarea por ID
func (s *TareaService) GetTareaByID(ctx context.Context, tareaID uuid.UUID) (*models.Tarea, error) {
	tarea, err := s.tareaRepo.GetByID(ctx, tareaID)
	if err != nil {
		return nil, fmt.Errorf("tarea no encontrada: %w", err)
	}
	return tarea, nil
}

// Actualizar tarea
func (s *TareaService) UpdateTarea(ctx context.Context, tareaID uuid.UUID, req *models.CreateTareaRequest) error {
	// Verificar que la tarea existe
	_, err := s.tareaRepo.GetByID(ctx, tareaID)
	if err != nil {
		return fmt.Errorf("tarea no encontrada: %w", err)
	}

	// Actualizar
	if err := s.tareaRepo.Update(ctx, tareaID, req); err != nil {
		return fmt.Errorf("error actualizando tarea: %w", err)
	}

	return nil
}

// Eliminar tarea
func (s *TareaService) DeleteTarea(ctx context.Context, tareaID uuid.UUID) error {
	// Verificar que la tarea existe
	_, err := s.tareaRepo.GetByID(ctx, tareaID)
	if err != nil {
		return fmt.Errorf("tarea no encontrada: %w", err)
	}

	// Eliminar
	if err := s.tareaRepo.Delete(ctx, tareaID); err != nil {
		return fmt.Errorf("error eliminando tarea: %w", err)
	}

	return nil
}

// ✅ AGREGAR AL FINAL DEL ARCHIVO:

// ========================================
// EXPORTAR ENTREGAS A EXCEL
// ========================================

// Exportar entregas de una tarea a Excel
func (s *TareaService) ExportarEntregasExcel(ctx context.Context, tareaID uuid.UUID) (*bytes.Buffer, string, error) {
	// Obtener las entregas con información del estudiante
	entregas, err := s.entregaRepo.GetByTareaIDWithEstudiante(ctx, tareaID)
	if err != nil {
		return nil, "", fmt.Errorf("error al obtener entregas: %w", err)
	}

	if len(entregas) == 0 {
		return nil, "", fmt.Errorf("no hay entregas para esta tarea")
	}

	// Obtener información de la tarea para el nombre del archivo
	tarea, err := s.tareaRepo.GetByID(ctx, tareaID)
	if err != nil {
		return nil, "", fmt.Errorf("error al obtener tarea: %w", err)
	}

	nombreTarea := tarea.Titulo

	// Crear un nuevo archivo Excel
	f := excelize.NewFile()
	defer f.Close()

	// Crear hoja principal
	sheetName := "Entregas"
	index, err := f.NewSheet(sheetName)
	if err != nil {
		return nil, "", fmt.Errorf("error al crear hoja: %w", err)
	}

	// Establecer como hoja activa
	f.SetActiveSheet(index)

	// Eliminar la hoja por defecto
	f.DeleteSheet("Sheet1")

	// Definir estilos
	headerStyle, _ := f.NewStyle(&excelize.Style{
		Font: &excelize.Font{
			Bold:  true,
			Size:  12,
			Color: "#FFFFFF",
		},
		Fill: excelize.Fill{
			Type:    "pattern",
			Color:   []string{"#2E7D32"},
			Pattern: 1,
		},
		Alignment: &excelize.Alignment{
			Horizontal: "center",
			Vertical:   "center",
		},
		Border: []excelize.Border{
			{Type: "left", Color: "#CCCCCC", Style: 1},
			{Type: "right", Color: "#CCCCCC", Style: 1},
			{Type: "top", Color: "#CCCCCC", Style: 1},
			{Type: "bottom", Color: "#CCCCCC", Style: 1},
		},
	})

	cellStyle, _ := f.NewStyle(&excelize.Style{
		Alignment: &excelize.Alignment{
			Vertical: "center",
		},
		Border: []excelize.Border{
			{Type: "left", Color: "#EEEEEE", Style: 1},
			{Type: "right", Color: "#EEEEEE", Style: 1},
			{Type: "top", Color: "#EEEEEE", Style: 1},
			{Type: "bottom", Color: "#EEEEEE", Style: 1},
		},
	})

	// Escribir encabezados
	headers := []string{"Estudiante", "Email", "Título", "Descripción", "Fecha Entrega", "Calificación"}
	for i, header := range headers {
		cell := string(rune('A'+i)) + "1"
		f.SetCellValue(sheetName, cell, header)
		f.SetCellStyle(sheetName, cell, cell, headerStyle)
	}

	// Ajustar anchos de columna
	f.SetColWidth(sheetName, "A", "A", 30) // Estudiante
	f.SetColWidth(sheetName, "B", "B", 30) // Email
	f.SetColWidth(sheetName, "C", "C", 25) // Título
	f.SetColWidth(sheetName, "D", "D", 40) // Descripción
	f.SetColWidth(sheetName, "E", "E", 20) // Fecha Entrega
	f.SetColWidth(sheetName, "F", "F", 15) // Calificación

	// Escribir datos
	// Escribir datos
	for i, entrega := range entregas {
		row := i + 2

		nombreEstudiante := "-"
		emailEstudiante := "-"
		if entrega.Estudiante != nil {
			nombreEstudiante = entrega.Estudiante.Usuario.NombreCompleto // ✅ CORRECTO
			emailEstudiante = entrega.Estudiante.Usuario.Email           // ✅ CORRECTO
		}

		descripcion := entrega.Descripcion
		if descripcion == nil || *descripcion == "" {
			temp := "Sin descripción"
			descripcion = &temp
		}

		fechaEntrega := entrega.FechaEntrega.Format("02/01/2006 15:04")

		calificacionStr := "Pendiente"
		if entrega.Calificacion != nil {
			calificacionStr = fmt.Sprintf("%.0f", *entrega.Calificacion)
		}

		// Escribir celdas
		f.SetCellValue(sheetName, fmt.Sprintf("A%d", row), nombreEstudiante)
		f.SetCellValue(sheetName, fmt.Sprintf("B%d", row), emailEstudiante)
		f.SetCellValue(sheetName, fmt.Sprintf("C%d", row), entrega.Titulo)
		f.SetCellValue(sheetName, fmt.Sprintf("D%d", row), *descripcion)
		f.SetCellValue(sheetName, fmt.Sprintf("E%d", row), fechaEntrega)
		f.SetCellValue(sheetName, fmt.Sprintf("F%d", row), calificacionStr)

		// Aplicar estilo
		for col := 'A'; col <= 'F'; col++ {
			cell := string(col) + fmt.Sprintf("%d", row)
			f.SetCellStyle(sheetName, cell, cell, cellStyle)
		}
	}

	// Convertir a buffer
	var buffer bytes.Buffer
	if err := f.Write(&buffer); err != nil {
		return nil, "", fmt.Errorf("error al escribir archivo: %w", err)
	}

	return &buffer, nombreTarea, nil
}
