package repository

import (
	"encoding/json"
	"fmt"
	"time"

	"recetario-backend/internal/config"
	"recetario-backend/internal/models"

	"github.com/google/uuid"
)

type NotificationRepository struct {
	client *SupabaseClient
}

func NewNotificationRepository(client *SupabaseClient) *NotificationRepository {
	return &NotificationRepository{client: client}
}

// Crear notificación
func (r *NotificationRepository) CrearNotificacion(notif *models.Notificacion) error {
	data := map[string]interface{}{
		"id":         uuid.New().String(),
		"usuario_id": notif.UsuarioID.String(),
		"tipo":       notif.Tipo,
		"titulo":     notif.Titulo,
		"mensaje":    notif.Mensaje,
		"leida":      false,
	}

	if notif.RecetaID != nil {
		data["receta_id"] = notif.RecetaID.String()
	}
	if notif.EnviadoPorID != nil {
		data["enviado_por_id"] = notif.EnviadoPorID.String()
	}

	url := fmt.Sprintf("%s/rest/v1/notificaciones", config.AppConfig.SupabaseURL)
	resp, err := r.client.DoRequest("POST", url, data, r.client.GetAuthHeadersWithPrefer())
	if err != nil {
		return err
	}

	var result []models.Notificacion
	json.Unmarshal(resp, &result)
	if len(result) > 0 {
		*notif = result[0]
	}
	return nil
}

// Obtener notificaciones de un usuario
// Obtener notificaciones de un usuario con información del remitente y receta
func (r *NotificationRepository) ObtenerNotificacionesPorUsuario(usuarioID uuid.UUID) ([]models.NotificacionConInfo, error) {
	// ✅ CORREGIDO: Agregar select con JOIN para traer nombre del remitente y título de receta
	url := fmt.Sprintf(
		"%s/rest/v1/notificaciones?usuario_id=eq.%s&select=*,enviador:usuarios!enviado_por_id(nombre_completo),receta:portafolio!receta_id(titulo)&order=created_at.desc&limit=50",
		config.AppConfig.SupabaseURL,
		usuarioID.String(),
	)

	resp, err := r.client.DoRequest("GET", url, nil, r.client.GetAuthHeaders())
	if err != nil {
		return nil, err
	}

	// ✅ Parsear respuesta con estructura anidada de Supabase
	var rawNotificaciones []struct {
		ID           string                 `json:"id"`
		UsuarioID    string                 `json:"usuario_id"`
		Tipo         string                 `json:"tipo"`
		Titulo       string                 `json:"titulo"`
		Mensaje      string                 `json:"mensaje"`
		RecetaID     *string                `json:"receta_id"`
		EnviadoPorID *string                `json:"enviado_por_id"`
		Leida        bool                   `json:"leida"`
		CreatedAt    string                 `json:"created_at"`
		Enviador     map[string]interface{} `json:"enviador"`
		Receta       map[string]interface{} `json:"receta"`
	}

	if err := json.Unmarshal(resp, &rawNotificaciones); err != nil {
		return nil, fmt.Errorf("error al parsear notificaciones: %v", err)
	}

	// ✅ Transformar a NotificacionConInfo
	notificaciones := make([]models.NotificacionConInfo, 0, len(rawNotificaciones))
	for _, raw := range rawNotificaciones {
		notif := models.NotificacionConInfo{}

		// Parsear ID
		if id, err := uuid.Parse(raw.ID); err == nil {
			notif.ID = id
		}

		// Parsear UsuarioID
		if usuarioID, err := uuid.Parse(raw.UsuarioID); err == nil {
			notif.UsuarioID = usuarioID
		}

		// Campos básicos
		notif.Tipo = raw.Tipo
		notif.Titulo = raw.Titulo
		notif.Mensaje = raw.Mensaje
		notif.Leida = raw.Leida

		// Parsear RecetaID
		if raw.RecetaID != nil {
			if recetaID, err := uuid.Parse(*raw.RecetaID); err == nil {
				notif.RecetaID = &recetaID
			}
		}

		// Parsear EnviadoPorID
		if raw.EnviadoPorID != nil {
			if enviadoPorID, err := uuid.Parse(*raw.EnviadoPorID); err == nil {
				notif.EnviadoPorID = &enviadoPorID
			}
		}

		// Parsear CreatedAt
		if createdAt, err := time.Parse(time.RFC3339, raw.CreatedAt); err == nil {
			notif.CreatedAt = createdAt
		}

		// ✅ Extraer nombre del enviador (desde el JOIN)
		if raw.Enviador != nil {
			if nombreCompleto, ok := raw.Enviador["nombre_completo"].(string); ok && nombreCompleto != "" {
				notif.NombreEnviador = &nombreCompleto
			}
		}

		// ✅ Extraer título de la receta (desde el JOIN)
		if raw.Receta != nil {
			if titulo, ok := raw.Receta["titulo"].(string); ok && titulo != "" {
				notif.TituloReceta = &titulo
			}
		}

		notificaciones = append(notificaciones, notif)
	}

	return notificaciones, nil
}

// Marcar notificación como leída
func (r *NotificationRepository) MarcarComoLeida(notificacionID uuid.UUID) error {
	url := fmt.Sprintf("%s/rest/v1/notificaciones?id=eq.%s",
		config.AppConfig.SupabaseURL, notificacionID.String())

	data := map[string]interface{}{"leida": true}
	_, err := r.client.DoRequest("PATCH", url, data, r.client.GetAuthHeaders())
	return err
}

// Marcar todas las notificaciones de un usuario como leídas
func (r *NotificationRepository) MarcarTodasComoLeidas(usuarioID uuid.UUID) error {
	url := fmt.Sprintf("%s/rest/v1/notificaciones?usuario_id=eq.%s&leida=eq.false",
		config.AppConfig.SupabaseURL, usuarioID.String())

	data := map[string]interface{}{"leida": true}
	_, err := r.client.DoRequest("PATCH", url, data, r.client.GetAuthHeaders())
	return err
}

// Contar notificaciones no leídas
func (r *NotificationRepository) ContarNoLeidas(usuarioID uuid.UUID) (int, error) {
	url := fmt.Sprintf("%s/rest/v1/notificaciones?usuario_id=eq.%s&leida=eq.false&select=id",
		config.AppConfig.SupabaseURL, usuarioID.String())

	resp, err := r.client.DoRequest("GET", url, nil, r.client.GetAuthHeaders())
	if err != nil {
		return 0, err
	}

	var items []map[string]interface{}
	json.Unmarshal(resp, &items)
	return len(items), nil
}

// Registrar o actualizar dispositivo FCM
func (r *NotificationRepository) RegistrarDispositivo(device *models.UsuarioDevice) error {
	// Primero desactivar otros devices del mismo usuario
	urlUpdate := fmt.Sprintf("%s/rest/v1/usuario_devices?usuario_id=eq.%s&plataforma=eq.%s&fcm_token=neq.%s",
		config.AppConfig.SupabaseURL, device.UsuarioID.String(), device.Plataforma, device.FCMToken)

	dataUpdate := map[string]interface{}{"activo": false}
	r.client.DoRequest("PATCH", urlUpdate, dataUpdate, r.client.GetAuthHeaders())

	// Insertar o actualizar el dispositivo actual (usando upsert)
	data := map[string]interface{}{
		"id":         uuid.New().String(),
		"usuario_id": device.UsuarioID.String(),
		"fcm_token":  device.FCMToken,
		"plataforma": device.Plataforma,
		"activo":     true,
		"created_at": time.Now(),
		"updated_at": time.Now(),
	}

	url := fmt.Sprintf("%s/rest/v1/usuario_devices", config.AppConfig.SupabaseURL)
	headers := r.client.GetAuthHeaders()
	headers["Prefer"] = "resolution=merge-duplicates"

	resp, err := r.client.DoRequest("POST", url, data, headers)
	if err != nil {
		return err
	}

	var result []models.UsuarioDevice
	json.Unmarshal(resp, &result)
	if len(result) > 0 {
		*device = result[0]
	}
	return nil
}

// Obtener tokens FCM activos de un usuario
func (r *NotificationRepository) ObtenerTokensFCM(usuarioID uuid.UUID) ([]string, error) {
	url := fmt.Sprintf("%s/rest/v1/usuario_devices?usuario_id=eq.%s&activo=eq.true&select=fcm_token",
		config.AppConfig.SupabaseURL, usuarioID.String())

	resp, err := r.client.DoRequest("GET", url, nil, r.client.GetAuthHeaders())
	if err != nil {
		return nil, err
	}

	var devices []struct {
		FCMToken string `json:"fcm_token"`
	}
	json.Unmarshal(resp, &devices)

	tokens := make([]string, len(devices))
	for i, d := range devices {
		tokens[i] = d.FCMToken
	}
	return tokens, nil
}

// Desactivar dispositivo por token
func (r *NotificationRepository) DesactivarDispositivo(fcmToken string) error {
	url := fmt.Sprintf("%s/rest/v1/usuario_devices?fcm_token=eq.%s",
		config.AppConfig.SupabaseURL, fcmToken)

	data := map[string]interface{}{"activo": false}
	_, err := r.client.DoRequest("PATCH", url, data, r.client.GetAuthHeaders())
	return err
}
