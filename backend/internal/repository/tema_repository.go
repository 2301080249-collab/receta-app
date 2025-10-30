package repository

import (
	"fmt"
	"log"
	"recetario-backend/internal/config"
)

type TemaRepository struct {
	client *SupabaseClient
}

func NewTemaRepository(client *SupabaseClient) *TemaRepository {
	return &TemaRepository{client: client}
}

// Obtener temas de un curso con materiales y tareas
func (r *TemaRepository) GetTemasByCursoID(cursoID string) ([]byte, error) {
	// Query con relaciones anidadas: materiales y tareas
	url := config.AppConfig.SupabaseURL +
		"/rest/v1/temas?curso_id=eq." + cursoID +
		"&select=*,materiales(*),tareas(*)" +
		"&order=orden.asc"

	headers := r.client.GetAuthHeaders()

	return r.client.DoRequest("GET", url, nil, headers)
}

// Crear tema
func (r *TemaRepository) CreateTema(data map[string]interface{}) ([]byte, error) {
	url := config.AppConfig.SupabaseURL + "/rest/v1/temas"

	headers := r.client.GetAuthHeadersWithPrefer()

	return r.client.DoRequest("POST", url, data, headers)
}

// Actualizar tema
func (r *TemaRepository) UpdateTema(temaID string, data map[string]interface{}) error {
	// 🔍 DEBUG: Ver qué datos están llegando
	log.Printf("🔍 [REPOSITORY] UpdateTema llamado")
	log.Printf("   TemaID: %s", temaID)
	log.Printf("   Data: %+v", data)

	url := config.AppConfig.SupabaseURL + "/rest/v1/temas?id=eq." + temaID

	log.Printf("   URL: %s", url)

	headers := r.client.GetAuthHeadersWithPrefer()

	respBody, err := r.client.DoRequest("PATCH", url, data, headers)

	if err != nil {
		log.Printf("❌ [REPOSITORY] Error al actualizar: %v", err)
		return err
	}

	log.Printf("✅ [REPOSITORY] Tema actualizado exitosamente")
	log.Printf("   Response: %s", string(respBody))

	return nil
}

// Eliminar tema
func (r *TemaRepository) DeleteTema(temaID string) error {
	url := config.AppConfig.SupabaseURL + "/rest/v1/temas?id=eq." + temaID

	headers := r.client.GetAuthHeaders()

	_, err := r.client.DoRequest("DELETE", url, nil, headers)
	return err
}

// Obtener tema por ID con relaciones (materiales y tareas)
func (r *TemaRepository) GetTemaByIDWithRelations(temaID string, query string) ([]byte, error) {
	// Construir URL completa con el query
	url := fmt.Sprintf("%s/rest/v1/temas%s", config.AppConfig.SupabaseURL, query)

	// Usar el método DoRequest existente
	headers := r.client.GetAuthHeaders()

	return r.client.DoRequest("GET", url, nil, headers)
}

// Obtener materiales de un tema
func (r *TemaRepository) GetMaterialesByTemaID(temaID string) ([]byte, error) {
	url := config.AppConfig.SupabaseURL +
		"/rest/v1/materiales?tema_id=eq." + temaID +
		"&order=orden.asc"

	headers := r.client.GetAuthHeaders()

	return r.client.DoRequest("GET", url, nil, headers)
}
