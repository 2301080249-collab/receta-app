package repository

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"recetario-backend/internal/config"
	"time"
)

// SupabaseClient encapsula el cliente HTTP y métodos compartidos
type SupabaseClient struct {
	client *http.Client
}

// NewSupabaseClient crea una nueva instancia del cliente
func NewSupabaseClient() *SupabaseClient {
	return &SupabaseClient{
		client: &http.Client{
			Timeout: 30 * time.Second,
		},
	}
}

// DoRequest ejecuta una petición HTTP genérica a Supabase
func (c *SupabaseClient) DoRequest(method, url string, body interface{}, headers map[string]string) ([]byte, error) {
	var reqBody io.Reader
	if body != nil {
		jsonData, err := json.Marshal(body)
		if err != nil {
			return nil, fmt.Errorf("error al serializar body: %w", err)
		}
		reqBody = bytes.NewBuffer(jsonData)
	}

	req, err := http.NewRequest(method, url, reqBody)
	if err != nil {
		return nil, fmt.Errorf("error al crear request: %w", err)
	}

	// Headers por defecto
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("apikey", config.AppConfig.SupabaseKey)

	// Headers adicionales
	for key, value := range headers {
		req.Header.Set(key, value)
	}

	resp, err := c.client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("error en petición HTTP: %w", err)
	}
	defer resp.Body.Close()

	responseBody, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("error al leer respuesta: %w", err)
	}

	if resp.StatusCode >= 400 {
		return nil, fmt.Errorf("error HTTP %d: %s", resp.StatusCode, string(responseBody))
	}

	return responseBody, nil
}

// GetAuthHeaders devuelve headers con service key para operaciones admin
func (c *SupabaseClient) GetAuthHeaders() map[string]string {
	return map[string]string{
		"Authorization": "Bearer " + config.AppConfig.SupabaseServiceKey,
	}
}

// GetAuthHeadersWithPrefer devuelve headers con service key + Prefer
func (c *SupabaseClient) GetAuthHeadersWithPrefer() map[string]string {
	return map[string]string{
		"Authorization": "Bearer " + config.AppConfig.SupabaseServiceKey,
		"Prefer":        "return=representation",
	}
}
