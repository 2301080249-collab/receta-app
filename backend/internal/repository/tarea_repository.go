package repository

import (
	"context"
	"encoding/json"
	"fmt"
	"recetario-backend/internal/config"
	"recetario-backend/internal/models"

	"github.com/google/uuid"
)

type TareaRepository struct {
	client *SupabaseClient
}

func NewTareaRepository(client *SupabaseClient) *TareaRepository {
	return &TareaRepository{client: client}
}

// Crear tarea
func (r *TareaRepository) Create(ctx context.Context, req *models.CreateTareaRequest) (*models.Tarea, error) {
	url := fmt.Sprintf("%s/rest/v1/tareas", config.AppConfig.SupabaseURL)

	respBody, err := r.client.DoRequest("POST", url, req, r.client.GetAuthHeadersWithPrefer())
	if err != nil {
		return nil, fmt.Errorf("error al crear tarea: %w", err)
	}

	var tareas []models.Tarea
	if err := json.Unmarshal(respBody, &tareas); err != nil {
		return nil, err
	}

	if len(tareas) == 0 {
		return nil, fmt.Errorf("no se pudo crear la tarea")
	}

	return &tareas[0], nil
}

// Obtener tarea por ID
func (r *TareaRepository) GetByID(ctx context.Context, tareaID uuid.UUID) (*models.Tarea, error) {
	url := fmt.Sprintf("%s/rest/v1/tareas?id=eq.%s",
		config.AppConfig.SupabaseURL, tareaID.String())

	respBody, err := r.client.DoRequest("GET", url, nil, r.client.GetAuthHeaders())
	if err != nil {
		return nil, fmt.Errorf("error al obtener tarea: %w", err)
	}

	var tareas []models.Tarea
	if err := json.Unmarshal(respBody, &tareas); err != nil {
		return nil, err
	}

	if len(tareas) == 0 {
		return nil, fmt.Errorf("tarea no encontrada")
	}

	return &tareas[0], nil
}

// Listar tareas por tema
func (r *TareaRepository) GetByTemaID(ctx context.Context, temaID uuid.UUID) ([]models.Tarea, error) {
	url := fmt.Sprintf("%s/rest/v1/tareas?tema_id=eq.%s&order=fecha_limite.asc",
		config.AppConfig.SupabaseURL, temaID.String())

	respBody, err := r.client.DoRequest("GET", url, nil, r.client.GetAuthHeaders())
	if err != nil {
		return nil, fmt.Errorf("error al obtener tareas: %w", err)
	}

	var tareas []models.Tarea
	if err := json.Unmarshal(respBody, &tareas); err != nil {
		return nil, err
	}

	return tareas, nil
}

// Actualizar tarea
func (r *TareaRepository) Update(ctx context.Context, tareaID uuid.UUID, req *models.CreateTareaRequest) error {
	url := fmt.Sprintf("%s/rest/v1/tareas?id=eq.%s",
		config.AppConfig.SupabaseURL, tareaID.String())

	_, err := r.client.DoRequest("PATCH", url, req, r.client.GetAuthHeaders())
	if err != nil {
		return fmt.Errorf("error al actualizar tarea: %w", err)
	}

	return nil
}

// Eliminar tarea
func (r *TareaRepository) Delete(ctx context.Context, tareaID uuid.UUID) error {
	url := fmt.Sprintf("%s/rest/v1/tareas?id=eq.%s",
		config.AppConfig.SupabaseURL, tareaID.String())

	_, err := r.client.DoRequest("DELETE", url, nil, r.client.GetAuthHeaders())
	if err != nil {
		return fmt.Errorf("error al eliminar tarea: %w", err)
	}

	return nil
}
