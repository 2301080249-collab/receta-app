package repository

import (
	"encoding/json"
	"fmt"
	"recetario-backend/internal/config"
)

type authRepository struct {
	client *SupabaseClient
}

func NewAuthRepository(client *SupabaseClient) AuthRepository {
	return &authRepository{client: client}
}

// ==================== AUTH ====================

func (r *authRepository) Authenticate(email, password string) (accessToken string, userID string, err error) {
	url := config.AppConfig.SupabaseURL + "/auth/v1/token?grant_type=password"

	body := map[string]string{
		"email":    email,
		"password": password,
	}

	respBody, err := r.client.DoRequest("POST", url, body, nil)
	if err != nil {
		return "", "", fmt.Errorf("credenciales incorrectas")
	}

	var authResp struct {
		AccessToken string `json:"access_token"`
		User        struct {
			ID string `json:"id"`
		} `json:"user"`
	}

	if err := json.Unmarshal(respBody, &authResp); err != nil {
		return "", "", fmt.Errorf("error al parsear respuesta de auth")
	}

	return authResp.AccessToken, authResp.User.ID, nil
}

func (r *authRepository) UpdatePassword(userID, newPassword string) error {
	url := config.AppConfig.SupabaseURL + "/auth/v1/admin/users/" + userID

	body := map[string]interface{}{
		"password": newPassword,
	}

	headers := map[string]string{
		"Authorization": "Bearer " + config.AppConfig.SupabaseServiceKey,
	}

	_, err := r.client.DoRequest("PUT", url, body, headers)
	return err
}

func (r *authRepository) CreateAuthUser(email, password, nombreCompleto, rol string) (string, error) {
	url := config.AppConfig.SupabaseURL + "/auth/v1/admin/users"

	body := map[string]interface{}{
		"email":         email,
		"password":      password,
		"email_confirm": true,
		"user_metadata": map[string]interface{}{
			"nombre_completo": nombreCompleto,
			"rol":             rol,
		},
	}

	headers := r.client.GetAuthHeaders()

	respBody, err := r.client.DoRequest("POST", url, body, headers)
	if err != nil {
		return "", err
	}

	var authResponse struct {
		ID string `json:"id"`
	}

	if err := json.Unmarshal(respBody, &authResponse); err != nil {
		return "", fmt.Errorf("error al parsear respuesta de auth")
	}

	return authResponse.ID, nil
}

func (r *authRepository) DeleteAuthUser(userID string) error {
	url := config.AppConfig.SupabaseURL + "/auth/v1/admin/users/" + userID

	headers := r.client.GetAuthHeaders()

	_, err := r.client.DoRequest("DELETE", url, nil, headers)
	return err
}
