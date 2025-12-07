package services

import (
	"context"
	"encoding/json"
	"fmt"
	"recetario-backend/internal/models"
	"recetario-backend/internal/repository"

	"github.com/google/uuid"
)

type TemaService struct {
	temaRepo    *repository.TemaRepository
	tareaRepo   *repository.TareaRepository
	entregaRepo *repository.EntregaRepository
}

func NewTemaService(
	temaRepo *repository.TemaRepository,
	tareaRepo *repository.TareaRepository,
	entregaRepo *repository.EntregaRepository,
) *TemaService {
	return &TemaService{
		temaRepo:    temaRepo,
		tareaRepo:   tareaRepo,
		entregaRepo: entregaRepo,
	}
}

// Obtener temas de un curso CON estadísticas de tareas Y mi_entrega para estudiantes
func (s *TemaService) GetTemasByCursoID(cursoID string, userID interface{}) ([]models.Tema, error) {
	ctx := context.Background()
	cursoUUID, err := uuid.Parse(cursoID)
	if err != nil {
		return nil, fmt.Errorf("ID de curso inválido: %w", err)
	}

	// Obtener temas básicos
	respBody, err := s.temaRepo.GetTemasByCursoID(cursoID)
	if err != nil {
		return nil, fmt.Errorf("error al obtener temas: %w", err)
	}

	var temas []models.Tema
	if err := json.Unmarshal(respBody, &temas); err != nil {
		return nil, fmt.Errorf("error al parsear temas: %w", err)
	}

	// ✅ Parsear estudianteID desde userID
	var estudianteID *uuid.UUID
	if userID != nil {
		if uid, ok := userID.(uuid.UUID); ok {
			estudianteID = &uid
		} else if uidStr, ok := userID.(string); ok {
			if parsed, err := uuid.Parse(uidStr); err == nil {
				estudianteID = &parsed
			}
		}
	}

	// Para cada tema, cargar sus tareas con estadísticas Y mi_entrega
	for i := range temas {
		// Obtener tareas del tema
		tareas, err := s.tareaRepo.GetByTemaID(ctx, temas[i].ID)
		if err != nil {
			continue // Si falla, continuar sin tareas
		}

		// Para cada tarea, calcular estadísticas Y cargar mi_entrega
		for j := range tareas {
			// Estadísticas (para todos)
			stats, err := s.entregaRepo.GetEstadisticasByTareaID(ctx, tareas[j].ID, cursoUUID)
			if err == nil {
				tareas[j].TotalEntregas = stats["total_entregas"]
				tareas[j].EntregasSinCalificar = stats["entregas_sin_calificar"]
				tareas[j].EntregasCalificadas = stats["entregas_calificadas"]
				tareas[j].EntregasPendientes = stats["entregas_pendientes"]
			}

			// ✅ MI_ENTREGA (solo para estudiantes)
			if estudianteID != nil {
				miEntrega, err := s.entregaRepo.GetMiEntrega(ctx, tareas[j].ID, *estudianteID)
				if err == nil && miEntrega != nil {
					// Cargar archivos de la entrega
					archivos, err := s.entregaRepo.GetArchivosByEntregaID(ctx, miEntrega.ID)
					if err == nil {
						miEntrega.Archivos = archivos
					}
					tareas[j].MiEntrega = miEntrega
				}
			}
		}

		temas[i].Tareas = tareas

		// También cargar materiales
		materiales, err := s.temaRepo.GetMaterialesByTemaID(temas[i].ID.String())
		if err == nil {
			var mats []models.Material
			if err := json.Unmarshal(materiales, &mats); err == nil {
				temas[i].Materiales = mats
			}
		}
	}

	return temas, nil
}

// Crear tema
func (s *TemaService) CrearTema(data map[string]interface{}) (interface{}, error) {
	respBody, err := s.temaRepo.CreateTema(data)
	if err != nil {
		return nil, fmt.Errorf("error al crear tema: %w", err)
	}

	var tema interface{}
	if err := json.Unmarshal(respBody, &tema); err != nil {
		return nil, fmt.Errorf("error al parsear tema: %w", err)
	}

	return tema, nil
}

// Actualizar tema
func (s *TemaService) ActualizarTema(temaID string, data map[string]interface{}) error {
	if err := s.temaRepo.UpdateTema(temaID, data); err != nil {
		return fmt.Errorf("error al actualizar tema: %w", err)
	}
	return nil
}

// Eliminar tema
func (s *TemaService) EliminarTema(temaID string) error {
	if err := s.temaRepo.DeleteTema(temaID); err != nil {
		return fmt.Errorf("error al eliminar tema: %w", err)
	}
	return nil
}

// Obtener tema por ID con materiales y tareas CON estadísticas
func (s *TemaService) GetTemaByID(temaID string) (models.Tema, error) {
	ctx := context.Background()

	temaUUID, err := uuid.Parse(temaID)
	if err != nil {
		return models.Tema{}, fmt.Errorf("ID de tema inválido: %w", err)
	}

	// Obtener tema básico
	query := "?id=eq." + temaID + "&select=*,curso:cursos(id)"
	respBody, err := s.temaRepo.GetTemaByIDWithRelations(temaID, query)
	if err != nil {
		return models.Tema{}, fmt.Errorf("error al obtener tema: %w", err)
	}

	var temas []models.Tema
	if err := json.Unmarshal(respBody, &temas); err != nil {
		return models.Tema{}, fmt.Errorf("error al parsear tema: %w", err)
	}

	if len(temas) == 0 {
		return models.Tema{}, fmt.Errorf("tema no encontrado")
	}

	tema := temas[0]

	// Obtener tareas con estadísticas
	tareas, err := s.tareaRepo.GetByTemaID(ctx, temaUUID)
	if err == nil {
		for j := range tareas {
			stats, err := s.entregaRepo.GetEstadisticasByTareaID(ctx, tareas[j].ID, tema.CursoID)
			if err == nil {
				tareas[j].TotalEntregas = stats["total_entregas"]
				tareas[j].EntregasSinCalificar = stats["entregas_sin_calificar"]
				tareas[j].EntregasCalificadas = stats["entregas_calificadas"]
				tareas[j].EntregasPendientes = stats["entregas_pendientes"]
			}
		}
		tema.Tareas = tareas
	}

	// Obtener materiales
	materiales, err := s.temaRepo.GetMaterialesByTemaID(temaID)
	if err == nil {
		var mats []models.Material
		if err := json.Unmarshal(materiales, &mats); err == nil {
			tema.Materiales = mats
		}
	}

	return tema, nil
}
