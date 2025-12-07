package services

import (
	"context"
	"fmt"
	"log"
	"os"

	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/messaging"
	"google.golang.org/api/option"
)

type FirebaseService struct {
	client *messaging.Client
}

func NewFirebaseService() (*FirebaseService, error) {
	ctx := context.Background()

	var opt option.ClientOption

	// ✅ Intentar cargar desde variable de entorno (PRODUCCIÓN)
	if credJSON := os.Getenv("FIREBASE_CREDENTIALS"); credJSON != "" {
		opt = option.WithCredentialsJSON([]byte(credJSON))
		log.Println("✅ Firebase: Usando credenciales desde variable de entorno")
	} else if _, err := os.Stat("./firebase-adminsdk.json"); err == nil {
		// Desarrollo: archivo local
		opt = option.WithCredentialsFile("./firebase-adminsdk.json")
		log.Println("✅ Firebase: Usando archivo local")
	} else {
		return nil, fmt.Errorf("no se encontraron credenciales de Firebase")
	}

	config := &firebase.Config{
		ProjectID: "cenfotec-8c7b1",
	}

	app, err := firebase.NewApp(ctx, config, opt)
	if err != nil {
		return nil, fmt.Errorf("error inicializando Firebase: %v", err)
	}

	client, err := app.Messaging(ctx)
	if err != nil {
		return nil, fmt.Errorf("error obteniendo cliente de messaging: %v", err)
	}

	log.Println("✅ Firebase Service inicializado correctamente")
	return &FirebaseService{client: client}, nil
}

// Enviar notificación push a un token
func (s *FirebaseService) EnviarNotificacion(token, titulo, mensaje string, data map[string]string) error {
	ctx := context.Background()

	// Construir el mensaje
	message := &messaging.Message{
		Token: token,
		Notification: &messaging.Notification{
			Title: titulo,
			Body:  mensaje,
		},
		Data: data,
		Android: &messaging.AndroidConfig{
			Priority: "high",
			Notification: &messaging.AndroidNotification{
				Sound:        "default",
				ChannelID:    "recetas_compartidas",
				Priority:     messaging.PriorityHigh,
				DefaultSound: true,
			},
		},
		APNS: &messaging.APNSConfig{
			Headers: map[string]string{
				"apns-priority": "10",
			},
			Payload: &messaging.APNSPayload{
				Aps: &messaging.Aps{
					Sound: "default",
					Badge: nil,
				},
			},
		},
	}

	// Enviar mensaje
	response, err := s.client.Send(ctx, message)
	if err != nil {
		return fmt.Errorf("error enviando notificación: %v", err)
	}

	log.Printf("✅ Notificación enviada exitosamente: %s", response)
	return nil
}

// Enviar notificación a múltiples tokens
func (s *FirebaseService) EnviarNotificacionMultiple(tokens []string, titulo, mensaje string, data map[string]string) error {
	ctx := context.Background()

	if len(tokens) == 0 {
		return fmt.Errorf("no hay tokens para enviar")
	}

	// ✅ CAMBIO: Enviar uno por uno en lugar de multicast
	successCount := 0
	failureCount := 0

	for _, token := range tokens {
		message := &messaging.Message{
			Token: token,
			Notification: &messaging.Notification{
				Title: titulo,
				Body:  mensaje,
			},
			Data: data,
			Android: &messaging.AndroidConfig{
				Priority: "high",
				Notification: &messaging.AndroidNotification{
					Sound:        "default",
					ChannelID:    "recetas_compartidas",
					Priority:     messaging.PriorityHigh,
					DefaultSound: true,
				},
			},
			APNS: &messaging.APNSConfig{
				Headers: map[string]string{
					"apns-priority": "10",
				},
				Payload: &messaging.APNSPayload{
					Aps: &messaging.Aps{
						Sound: "default",
					},
				},
			},
		}

		_, err := s.client.Send(ctx, message)
		if err != nil {
			log.Printf("⚠️ Error enviando a token %s: %v", token[:20]+"...", err)
			failureCount++
		} else {
			successCount++
		}
	}

	log.Printf("✅ Notificaciones enviadas: %d exitosas, %d fallidas", successCount, failureCount)

	if successCount == 0 {
		return fmt.Errorf("todas las notificaciones fallaron")
	}

	return nil
}

// Suscribir token a un topic
func (s *FirebaseService) SuscribirATopic(tokens []string, topic string) error {
	ctx := context.Background()
	response, err := s.client.SubscribeToTopic(ctx, tokens, topic)
	if err != nil {
		return fmt.Errorf("error suscribiendo a topic: %v", err)
	}

	log.Printf("✅ Suscrito a topic '%s': %d exitosos, %d fallidos",
		topic, response.SuccessCount, response.FailureCount)
	return nil
}

// Desuscribir token de un topic
func (s *FirebaseService) DesuscribirDeTopic(tokens []string, topic string) error {
	ctx := context.Background()
	response, err := s.client.UnsubscribeFromTopic(ctx, tokens, topic)
	if err != nil {
		return fmt.Errorf("error desuscribiendo de topic: %v", err)
	}

	log.Printf("✅ Desuscrito de topic '%s': %d exitosos, %d fallidos",
		topic, response.SuccessCount, response.FailureCount)
	return nil
}
