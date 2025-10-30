package repository

import (
	"context"
	"encoding/json"
	"fmt"
	"recetario-backend/internal/config"
	"recetario-backend/internal/models"

	"github.com/google/uuid"
)

type MaterialRepository struct {
	client *SupabaseClient
}

func NewMaterialRepository(client *SupabaseClient) *MaterialRepository {
	return &MaterialRepository{client: client}
}

// Crear material
func (r *MaterialRepository) Create(ctx context.Context, req *models.CreateMaterialRequest) (*models.Material, error) {
	url := fmt.Sprintf("%s/rest/v1/materiales", config.AppConfig.SupabaseURL)

	respBody, err := r.client.DoRequest("POST", url, req, r.client.GetAuthHeadersWithPrefer())
	if err != nil {
		return nil, fmt.Errorf("error al crear material: %w", err)
	}

	var materiales []models.Material
	if err := json.Unmarshal(respBody, &materiales); err != nil {
		return nil, err
	}

	if len(materiales) == 0 {
		return nil, fmt.Errorf("no se pudo crear el material")
	}

	return &materiales[0], nil
}

// ✅ NUEVO: Obtener material por ID
func (r *MaterialRepository) GetByID(ctx context.Context, materialID uuid.UUID) (*models.Material, error) {
	url := fmt.Sprintf("%s/rest/v1/materiales?id=eq.%s",
		config.AppConfig.SupabaseURL, materialID.String())

	respBody, err := r.client.DoRequest("GET", url, nil, r.client.GetAuthHeaders())
	if err != nil {
		return nil, fmt.Errorf("error al obtener material: %w", err)
	}

	var materiales []models.Material
	if err := json.Unmarshal(respBody, &materiales); err != nil {
		return nil, err
	}

	if len(materiales) == 0 {
		return nil, fmt.Errorf("material no encontrado")
	}

	return &materiales[0], nil
}

// ✅ NUEVO: Actualizar material
func (r *MaterialRepository) Update(ctx context.Context, materialID uuid.UUID, req *models.UpdateMaterialRequest) (*models.Material, error) {
	url := fmt.Sprintf("%s/rest/v1/materiales?id=eq.%s",
		config.AppConfig.SupabaseURL, materialID.String())

	respBody, err := r.client.DoRequest("PATCH", url, req, r.client.GetAuthHeadersWithPrefer())
	if err != nil {
		return nil, fmt.Errorf("error al actualizar material: %w", err)
	}

	var materiales []models.Material
	if err := json.Unmarshal(respBody, &materiales); err != nil {
		return nil, err
	}

	if len(materiales) == 0 {
		return nil, fmt.Errorf("no se pudo actualizar el material")
	}

	return &materiales[0], nil
}

// Listar materiales por tema
func (r *MaterialRepository) GetByTemaID(ctx context.Context, temaID uuid.UUID) ([]models.Material, error) {
	url := fmt.Sprintf("%s/rest/v1/materiales?tema_id=eq.%s&order=orden.asc",
		config.AppConfig.SupabaseURL, temaID.String())

	respBody, err := r.client.DoRequest("GET", url, nil, r.client.GetAuthHeaders())
	if err != nil {
		return nil, fmt.Errorf("error al obtener materiales: %w", err)
	}

	var materiales []models.Material
	if err := json.Unmarshal(respBody, &materiales); err != nil {
		return nil, err
	}

	return materiales, nil
}

// Marcar material como visto
func (r *MaterialRepository) MarcarComoVisto(ctx context.Context, materialID, estudianteID uuid.UUID) error {
	url := fmt.Sprintf("%s/rest/v1/material_visto", config.AppConfig.SupabaseURL)

	data := map[string]interface{}{
		"material_id":   materialID,
		"estudiante_id": estudianteID,
	}

	_, err := r.client.DoRequest("POST", url, data, r.client.GetAuthHeaders())
	if err != nil {
		return fmt.Errorf("error al marcar material como visto: %w", err)
	}

	return nil
}

// Eliminar material
func (r *MaterialRepository) Delete(ctx context.Context, materialID uuid.UUID) error {
	url := fmt.Sprintf("%s/rest/v1/materiales?id=eq.%s",
		config.AppConfig.SupabaseURL, materialID.String())

	_, err := r.client.DoRequest("DELETE", url, nil, r.client.GetAuthHeaders())
	if err != nil {
		return fmt.Errorf("error al eliminar material: %w", err)
	}

	return nil
}
