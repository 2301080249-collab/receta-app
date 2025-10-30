package middleware

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"recetario-backend/internal/config"
	"strings"

	"github.com/gofiber/fiber/v2"
)

// AuthRequired - Middleware que valida el token JWT de Supabase
func AuthRequired(c *fiber.Ctx) error {
	// 1. Obtener Authorization header
	authHeader := c.Get("Authorization")

	if authHeader == "" {
		return c.Status(401).JSON(fiber.Map{
			"error": "No autorizado - Token requerido",
		})
	}

	// 2. Verificar formato "Bearer TOKEN"
	parts := strings.Split(authHeader, " ")
	if len(parts) != 2 || parts[0] != "Bearer" {
		return c.Status(401).JSON(fiber.Map{
			"error": "Formato de token inválido",
		})
	}

	token := parts[1]

	if token == "" {
		return c.Status(401).JSON(fiber.Map{
			"error": "Token vacío",
		})
	}

	// 3. Validar token con Supabase
	userInfo, err := validateSupabaseToken(token)
	if err != nil {
		fmt.Println("❌ Token inválido:", err)
		return c.Status(401).JSON(fiber.Map{
			"error": "Token inválido o expirado",
		})
	}

	// 4. Guardar información del usuario en el contexto ✅ CORREGIDO
	c.Locals("user_id", userInfo.ID)       // ← snake_case
	c.Locals("user_email", userInfo.Email) // ← snake_case
	c.Locals("user_role", userInfo.Role)   // ← snake_case

	fmt.Printf("✅ Usuario autenticado: %s (%s) - ID: %s\n", userInfo.Email, userInfo.Role, userInfo.ID)

	// 5. Continuar con el siguiente handler
	return c.Next()
}

// ==================== VALIDACIÓN DE TOKEN ====================

type UserInfo struct {
	ID    string
	Email string
	Role  string
}

func validateSupabaseToken(token string) (*UserInfo, error) {
	// Llamar al endpoint de Supabase para obtener información del usuario
	url := config.AppConfig.SupabaseURL + "/auth/v1/user"

	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return nil, err
	}

	req.Header.Set("apikey", config.AppConfig.SupabaseKey)
	req.Header.Set("Authorization", "Bearer "+token)

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		body, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("token inválido: %s", string(body))
	}

	body, _ := io.ReadAll(resp.Body)

	var supabaseUser struct {
		ID       string `json:"id"`
		Email    string `json:"email"`
		UserMeta struct {
			Role string `json:"rol"`
		} `json:"user_metadata"`
	}

	if err := json.Unmarshal(body, &supabaseUser); err != nil {
		return nil, err
	}

	// Obtener rol desde la tabla usuarios si no está en metadata
	role := supabaseUser.UserMeta.Role
	if role == "" {
		role = getRoleFromDatabase(supabaseUser.ID)
	}

	return &UserInfo{
		ID:    supabaseUser.ID,
		Email: supabaseUser.Email,
		Role:  role,
	}, nil
}

func getRoleFromDatabase(userID string) string {
	url := config.AppConfig.SupabaseURL + "/rest/v1/usuarios?id=eq." + userID + "&select=rol"

	req, _ := http.NewRequest("GET", url, nil)
	req.Header.Set("apikey", config.AppConfig.SupabaseKey)
	req.Header.Set("Authorization", "Bearer "+config.AppConfig.SupabaseServiceKey)

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return ""
	}
	defer resp.Body.Close()

	body, _ := io.ReadAll(resp.Body)

	var usuarios []struct {
		Rol string `json:"rol"`
	}

	json.Unmarshal(body, &usuarios)

	if len(usuarios) > 0 {
		return usuarios[0].Rol
	}

	return ""
}

// ==================== MIDDLEWARE POR ROL (OPCIONAL) ====================

// RequireRole - Middleware que verifica que el usuario tenga un rol específico
func RequireRole(allowedRoles ...string) fiber.Handler {
	return func(c *fiber.Ctx) error {
		userRole, ok := c.Locals("user_role").(string) // ✅ CORREGIDO
		if !ok {
			return c.Status(403).JSON(fiber.Map{
				"error": "No se pudo determinar el rol del usuario",
			})
		}

		// Verificar si el rol del usuario está en la lista de roles permitidos
		for _, role := range allowedRoles {
			if userRole == role {
				return c.Next()
			}
		}

		return c.Status(403).JSON(fiber.Map{
			"error": "No tienes permisos para acceder a este recurso",
		})
	}
}
