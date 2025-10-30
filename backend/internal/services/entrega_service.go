package services

import (
	"context"
	"fmt"
	"time"

	"recetario-backend/internal/models"
	"recetario-backend/internal/repository"

	"github.com/google/uuid"
)

type EntregaService struct {
	entregaRepo    *repository.EntregaRepository
	tareaRepo      *repository.TareaRepository
	storageService *StorageService
}

func NewEntregaService(
	entregaRepo *repository.EntregaRepository,
	tareaRepo *repository.TareaRepository,
	storageService *StorageService,
) *EntregaService {
	return &EntregaService{
		entregaRepo:    entregaRepo,
		tareaRepo:      tareaRepo,
		storageService: storageService,
	}
}

// Crear entrega (estudiante)
func (s *EntregaService) CrearEntrega(ctx context.Context, estudianteID uuid.UUID, req *models.CreateEntregaRequest) (*models.Entrega, error) {
	// ✅ Verificar si ya tiene una entrega para esta tarea
	entregaExistente, err := s.entregaRepo.GetByTareaAndEstudiante(ctx, req.TareaID, estudianteID)
	if err == nil && entregaExistente != nil {
		return nil, fmt.Errorf("ya has entregado esta tarea. Si deseas modificarla, edita tu entrega anterior")
	}

	// Verificar si la tarea existe
	tarea, err := s.tareaRepo.GetByID(ctx, req.TareaID)
	if err != nil {
		return nil, fmt.Errorf("tarea no encontrada: %w", err)
	}

	// Calcular si está tarde
	now := time.Now()
	diasRetraso := 0
	entregaTardia := false
	penalizacion := 0.0

	if now.After(tarea.FechaLimite) {
		entregaTardia = true
		diasRetraso = int(now.Sub(tarea.FechaLimite).Hours() / 24)

		if !tarea.PermiteEntregaTardia || diasRetraso > tarea.DiasTolerancia {
			return nil, fmt.Errorf("la fecha límite ha expirado")
		}

		penalizacion = float64(diasRetraso) * tarea.PenalizacionPorDia
	}

	// Crear entrega
	entrega := &models.Entrega{
		TareaID:              req.TareaID,
		EstudianteID:         estudianteID,
		Titulo:               req.Titulo,
		Descripcion:          req.Descripcion,
		FechaEntrega:         now,
		DiasRetraso:          diasRetraso,
		PenalizacionAplicada: penalizacion,
		Estado:               "pendiente",
		EntregaTardia:        entregaTardia,
	}

	return s.entregaRepo.Create(ctx, entrega)
}

// Agregar archivo a entrega
func (s *EntregaService) AgregarArchivo(ctx context.Context, entregaID uuid.UUID, archivo *models.ArchivoEntrega) error {
	return s.entregaRepo.AddArchivo(ctx, archivo)
}

// Obtener mi entrega (estudiante)
func (s *EntregaService) ObtenerMiEntrega(ctx context.Context, tareaID, estudianteID uuid.UUID) (*models.Entrega, error) {
	entrega, err := s.entregaRepo.GetByTareaAndEstudiante(ctx, tareaID, estudianteID)
	if err != nil {
		return nil, err
	}

	// Cargar archivos
	archivos, err := s.entregaRepo.GetArchivosByEntregaID(ctx, entrega.ID)
	if err != nil {
		return nil, fmt.Errorf("error obteniendo archivos: %w", err)
	}
	entrega.Archivos = archivos

	return entrega, nil
}

// ✅ NUEVO: Obtener entrega por ID
func (s *EntregaService) ObtenerEntregaPorID(ctx context.Context, entregaID uuid.UUID) (*models.Entrega, error) {
	entrega, err := s.entregaRepo.GetByID(ctx, entregaID)
	if err != nil {
		return nil, err
	}

	// Cargar archivos
	archivos, err := s.entregaRepo.GetArchivosByEntregaID(ctx, entrega.ID)
	if err != nil {
		return nil, fmt.Errorf("error obteniendo archivos: %w", err)
	}
	entrega.Archivos = archivos

	return entrega, nil
}

// ✅ NUEVO: Validar que el estudiante sea el propietario de la entrega
func (s *EntregaService) ValidarPropietario(ctx context.Context, entregaID, estudianteID uuid.UUID) error {
	entrega, err := s.entregaRepo.GetByID(ctx, entregaID)
	if err != nil {
		return fmt.Errorf("entrega no encontrada: %w", err)
	}

	if entrega.EstudianteID != estudianteID {
		return fmt.Errorf("no tienes permiso para realizar esta acción")
	}

	return nil
}

// Editar entrega (solo si no está calificada)
func (s *EntregaService) EditarEntrega(ctx context.Context, entregaID uuid.UUID, req *models.CreateEntregaRequest) error {
	// Verificar que no esté calificada
	entrega, err := s.entregaRepo.GetByID(ctx, entregaID)
	if err != nil {
		return err
	}

	if entrega.Calificacion != nil {
		return fmt.Errorf("no se puede editar una entrega ya calificada")
	}

	return s.entregaRepo.Update(ctx, entregaID, req)
}

// Eliminar entrega (solo si no está calificada)
func (s *EntregaService) EliminarEntrega(ctx context.Context, entregaID uuid.UUID) error {
	entrega, err := s.entregaRepo.GetByID(ctx, entregaID)
	if err != nil {
		return err
	}

	if entrega.Calificacion != nil {
		return fmt.Errorf("no se puede eliminar una entrega ya calificada")
	}

	return s.entregaRepo.Delete(ctx, entregaID)
}

// ✅ NUEVO: Obtener archivos por entrega ID
func (s *EntregaService) ObtenerArchivosPorEntregaID(ctx context.Context, entregaID uuid.UUID) ([]models.ArchivoEntrega, error) {
	return s.entregaRepo.GetArchivosByEntregaID(ctx, entregaID)
}

// ✅ NUEVO: Obtener archivo por ID
func (s *EntregaService) ObtenerArchivoPorID(ctx context.Context, archivoID uuid.UUID) (*models.ArchivoEntrega, error) {
	return s.entregaRepo.GetArchivoByID(ctx, archivoID)
}

// ✅ NUEVO: Eliminar archivo individual
func (s *EntregaService) EliminarArchivo(ctx context.Context, archivoID uuid.UUID) error {
	return s.entregaRepo.DeleteArchivo(ctx, archivoID)
}

// ========================================
// MÉTODOS PARA DOCENTES
// ========================================

// Obtener entregas con información del estudiante (DOCENTE)
func (s *EntregaService) GetEntregasConEstudiante(ctx context.Context, tareaID uuid.UUID) ([]models.Entrega, error) {
	return s.entregaRepo.GetByTareaIDWithEstudiante(ctx, tareaID)
}

// Obtener estadísticas de entregas (DOCENTE)
func (s *EntregaService) GetEstadisticas(ctx context.Context, tareaID, cursoID uuid.UUID) (map[string]int, error) {
	return s.entregaRepo.GetEstadisticasByTareaID(ctx, tareaID, cursoID)
}

// Calificar entrega (DOCENTE)
func (s *EntregaService) CalificarEntrega(ctx context.Context, entregaID uuid.UUID, calificacion float64, comentario string) error {
	// Validar calificación
	if calificacion < 0 {
		return fmt.Errorf("la calificación no puede ser negativa")
	}

	// Obtener la entrega para validar
	entrega, err := s.entregaRepo.GetByID(ctx, entregaID)
	if err != nil {
		return fmt.Errorf("entrega no encontrada: %w", err)
	}

	// Obtener la tarea para validar el puntaje máximo
	tarea, err := s.tareaRepo.GetByID(ctx, entrega.TareaID)
	if err != nil {
		return fmt.Errorf("tarea no encontrada: %w", err)
	}

	if calificacion > tarea.PuntajeMaximo {
		return fmt.Errorf("la calificación no puede ser mayor al puntaje máximo de %.2f", tarea.PuntajeMaximo)
	}

	// Aplicar penalización si hay
	calificacionFinal := calificacion - entrega.PenalizacionAplicada
	if calificacionFinal < 0 {
		calificacionFinal = 0
	}

	return s.entregaRepo.Calificar(ctx, entregaID, calificacionFinal, comentario)
}

// Obtener entrega por ID con todos los detalles (DOCENTE)
func (s *EntregaService) GetEntregaDetalle(ctx context.Context, entregaID uuid.UUID) (*models.Entrega, error) {
	entrega, err := s.entregaRepo.GetByID(ctx, entregaID)
	if err != nil {
		return nil, err
	}

	// Cargar archivos
	archivos, err := s.entregaRepo.GetArchivosByEntregaID(ctx, entrega.ID)
	if err != nil {
		return nil, fmt.Errorf("error obteniendo archivos: %w", err)
	}
	entrega.Archivos = archivos

	// Cargar información de la tarea
	tarea, err := s.tareaRepo.GetByID(ctx, entrega.TareaID)
	if err != nil {
		return nil, fmt.Errorf("error obteniendo tarea: %w", err)
	}
	entrega.Tarea = tarea

	return entrega, nil
}
