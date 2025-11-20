package services

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"strings"

	"recetario-backend/internal/models"
	"recetario-backend/internal/repository"

	"github.com/google/uuid"
)

type NotificationService struct {
	repo            *repository.NotificationRepository
	firebaseService *FirebaseService
	usuarioRepo     repository.UsuarioRepository
	portafolioRepo  *repository.PortafolioRepository
}

func NewNotificationService(
	repo *repository.NotificationRepository,
	firebaseService *FirebaseService,
	usuarioRepo repository.UsuarioRepository,
	portafolioRepo *repository.PortafolioRepository,
) *NotificationService {
	return &NotificationService{
		repo:            repo,
		firebaseService: firebaseService,
		usuarioRepo:     usuarioRepo,
		portafolioRepo:  portafolioRepo,
	}
}

// 🆕 Compartir receta con usuarios - ahora con mensaje personalizado opcional
func (s *NotificationService) CompartirReceta(recetaID uuid.UUID, usuariosIDs []uuid.UUID, enviadoPorID uuid.UUID, mensajePersonalizado string) error {
	ctx := context.Background()

	// Obtener información de la receta
	receta, err := s.portafolioRepo.ObtenerPorID(ctx, recetaID)
	if err != nil {
		return fmt.Errorf("error obteniendo receta: %v", err)
	}

	// Obtener información completa del usuario que comparte
	usuariosRaw, err := s.usuarioRepo.GetUserByIDWithRelations(enviadoPorID.String())
	if err != nil {
		log.Printf("⚠️ Error obteniendo info del usuario: %v", err)
	}

	// Extraer nombre completo del remitente
	nombreRemitente := "Un usuario"
	if usuariosRaw != nil {
		var usuarios []map[string]interface{}
		if err := json.Unmarshal(usuariosRaw, &usuarios); err == nil && len(usuarios) > 0 {
			// Intentar obtener nombre_completo
			if nombreCompleto, ok := usuarios[0]["nombre_completo"].(string); ok && nombreCompleto != "" {
				nombreRemitente = nombreCompleto
			} else {
				// Si no existe nombre_completo, construir desde nombre y apellido
				nombre := ""
				apellido := ""
				if n, ok := usuarios[0]["nombre"].(string); ok {
					nombre = n
				}
				if a, ok := usuarios[0]["apellido"].(string); ok {
					apellido = a
				}
				if nombre != "" || apellido != "" {
					nombreRemitente = strings.TrimSpace(nombre + " " + apellido)
				}
			}
		}
	}

	log.Printf("✅ Compartiendo receta '%s' desde '%s' a %d usuarios", receta.Titulo, nombreRemitente, len(usuariosIDs))

	// Crear notificaciones y enviar push para cada usuario
	for _, usuarioID := range usuariosIDs {
		// 🆕 Construir el mensaje final
		var mensajeFinal string
		if mensajePersonalizado != "" && strings.TrimSpace(mensajePersonalizado) != "" {
			// Si hay mensaje personalizado, usarlo
			mensajeFinal = fmt.Sprintf("%s compartió '%s' contigo: \"%s\"", nombreRemitente, receta.Titulo, strings.TrimSpace(mensajePersonalizado))
		} else {
			// Mensaje por defecto sin mensaje personalizado
			mensajeFinal = fmt.Sprintf("%s compartió '%s' contigo", nombreRemitente, receta.Titulo)
		}

		// Crear notificación en BD
		notif := &models.Notificacion{
			UsuarioID:    usuarioID,
			Tipo:         "receta_compartida",
			Titulo:       "Nueva receta compartida",
			Mensaje:      mensajeFinal, // 🆕 Mensaje con o sin personalización
			RecetaID:     &recetaID,
			EnviadoPorID: &enviadoPorID,
			Leida:        false,
		}

		err := s.repo.CrearNotificacion(notif)
		if err != nil {
			log.Printf("❌ Error creando notificación para usuario %s: %v", usuarioID, err)
			continue
		}

		log.Printf("📬 Notificación creada para usuario %s", usuarioID)

		// Enviar notificación push
		go s.enviarPushNotificacion(usuarioID, notif.Titulo, notif.Mensaje, recetaID.String())
	}

	return nil
}

// Enviar notificación push a un usuario
func (s *NotificationService) enviarPushNotificacion(usuarioID uuid.UUID, titulo, mensaje, recetaID string) {
	// Obtener tokens FCM del usuario
	tokens, err := s.repo.ObtenerTokensFCM(usuarioID)
	if err != nil {
		log.Printf("❌ Error obteniendo tokens FCM: %v", err)
		return
	}

	if len(tokens) == 0 {
		log.Printf("⚠️ Usuario %s no tiene tokens FCM registrados", usuarioID)
		return
	}

	// Datos adicionales para la notificación
	data := map[string]string{
		"receta_id": recetaID,
		"tipo":      "receta_compartida",
	}

	// Enviar notificación
	err = s.firebaseService.EnviarNotificacionMultiple(tokens, titulo, mensaje, data)
	if err != nil {
		log.Printf("❌ Error enviando push notification: %v", err)
	} else {
		log.Printf("✅ Push notification enviada a %d dispositivos", len(tokens))
	}
}

// Obtener notificaciones de un usuario
func (s *NotificationService) ObtenerNotificaciones(usuarioID uuid.UUID) ([]models.NotificacionConInfo, error) {
	return s.repo.ObtenerNotificacionesPorUsuario(usuarioID)
}

// Marcar notificación como leída
func (s *NotificationService) MarcarComoLeida(notificacionID uuid.UUID) error {
	return s.repo.MarcarComoLeida(notificacionID)
}

// Marcar todas como leídas
func (s *NotificationService) MarcarTodasComoLeidas(usuarioID uuid.UUID) error {
	return s.repo.MarcarTodasComoLeidas(usuarioID)
}

// Registrar dispositivo FCM
func (s *NotificationService) RegistrarDispositivo(usuarioID uuid.UUID, fcmToken, plataforma string) error {
	device := &models.UsuarioDevice{
		UsuarioID:  usuarioID,
		FCMToken:   fcmToken,
		Plataforma: plataforma,
		Activo:     true,
	}
	return s.repo.RegistrarDispositivo(device)
}

// Contar notificaciones no leídas
func (s *NotificationService) ContarNoLeidas(usuarioID uuid.UUID) (int, error) {
	return s.repo.ContarNoLeidas(usuarioID)
}
