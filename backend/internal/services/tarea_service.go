package services

import (
	"context"
	"fmt"

	"recetario-backend/internal/models"
	"recetario-backend/internal/repository"

	"github.com/google/uuid"
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
