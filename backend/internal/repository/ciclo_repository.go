package repository

import (
	"recetario-backend/internal/config"
)

type cicloRepository struct {
	client *SupabaseClient
}

func NewCicloRepository(client *SupabaseClient) CicloRepository {
	return &cicloRepository{client: client}
}

// ==================== CICLOS ====================

func (r *cicloRepository) CreateCiclo(data map[string]interface{}) ([]byte, error) {
	url := config.AppConfig.SupabaseURL + "/rest/v1/ciclos"

	headers := r.client.GetAuthHeadersWithPrefer()

	return r.client.DoRequest("POST", url, data, headers)
}

func (r *cicloRepository) GetAllCiclos() ([]byte, error) {
	url := config.AppConfig.SupabaseURL + "/rest/v1/ciclos?order=created_at.desc"

	headers := r.client.GetAuthHeaders()

	return r.client.DoRequest("GET", url, nil, headers)
}

func (r *cicloRepository) GetCicloByID(cicloID string) ([]byte, error) {
	url := config.AppConfig.SupabaseURL + "/rest/v1/ciclos?id=eq." + cicloID

	headers := r.client.GetAuthHeaders()

	return r.client.DoRequest("GET", url, nil, headers)
}

func (r *cicloRepository) UpdateCiclo(cicloID string, data map[string]interface{}) error {
	url := config.AppConfig.SupabaseURL + "/rest/v1/ciclos?id=eq." + cicloID

	headers := r.client.GetAuthHeadersWithPrefer()

	_, err := r.client.DoRequest("PATCH", url, data, headers)
	return err
}

func (r *cicloRepository) DeleteCiclo(cicloID string) error {
	url := config.AppConfig.SupabaseURL + "/rest/v1/ciclos?id=eq." + cicloID

	headers := r.client.GetAuthHeaders()

	_, err := r.client.DoRequest("DELETE", url, nil, headers)
	return err
}

func (r *cicloRepository) GetCicloActivo() ([]byte, error) {
	url := config.AppConfig.SupabaseURL + "/rest/v1/ciclos?activo=eq.true"

	headers := r.client.GetAuthHeaders()

	return r.client.DoRequest("GET", url, nil, headers)
}

// ==================== VALIDACIONES ====================

// ✅ NUEVO: Verificar si un ciclo tiene cursos
func (r *cicloRepository) CicloTieneCursos(cicloID string) (bool, error) {
	url := config.AppConfig.SupabaseURL + "/rest/v1/cursos?ciclo_id=eq." + cicloID + "&select=id&limit=1"

	headers := r.client.GetAuthHeaders()

	result, err := r.client.DoRequest("GET", url, nil, headers)
	if err != nil {
		return false, err
	}

	// Si la respuesta es "[]" significa que no hay cursos
	// Si hay algo más, significa que sí hay cursos
	return string(result) != "[]", nil
}
