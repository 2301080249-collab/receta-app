package repository

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"

	"recetario-backend/internal/config"
	"recetario-backend/internal/models"

	"github.com/google/uuid"
)

type CategoriaRepository struct {
	client *SupabaseClient
}

func NewCategoriaRepository(client *SupabaseClient) *CategoriaRepository {
	return &CategoriaRepository{client: client}
}

// Crear categoría
func (r *CategoriaRepository) Crear(ctx context.Context, req models.CrearCategoriaRequest) (*models.Categoria, error) {
	fmt.Println("📝 [CategoriaRepo] Crear - Iniciando...")

	if r.client == nil {
		fmt.Println("❌ [CategoriaRepo] Supabase client es NIL")
		return nil, fmt.Errorf("supabase client is nil")
	}

	categoria := models.Categoria{
		ID:          uuid.New(),
		Nombre:      req.Nombre,
		Descripcion: req.Descripcion,
		Icono:       req.Icono,
		Orden:       req.Orden,
		Activo:      true,
	}

	url := fmt.Sprintf("%s/rest/v1/categorias", config.AppConfig.SupabaseURL)

	responseBody, err := r.client.DoRequest(
		http.MethodPost,
		url,
		categoria,
		r.client.GetAuthHeadersWithPrefer(),
	)

	if err != nil {
		fmt.Println("❌ [CategoriaRepo] Error creando:", err)
		return nil, fmt.Errorf("error al crear categoría: %w", err)
	}

	var result []models.Categoria
	if err := json.Unmarshal(responseBody, &result); err != nil {
		fmt.Println("❌ [CategoriaRepo] Error parseando respuesta:", err)
		return nil, fmt.Errorf("error al parsear respuesta: %w", err)
	}

	if len(result) == 0 {
		fmt.Println("❌ [CategoriaRepo] No se retornó ninguna categoría")
		return nil, fmt.Errorf("error al crear categoría: no se retornó ningún registro")
	}

	fmt.Println("✅ [CategoriaRepo] Categoría creada:", result[0].ID)
	return &result[0], nil
}

// Listar todas las categorías activas
func (r *CategoriaRepository) ListarActivas(ctx context.Context) ([]models.Categoria, error) {
	fmt.Println("📥 [CategoriaRepo] ListarActivas - Iniciando...")

	if r.client == nil {
		fmt.Println("❌ [CategoriaRepo] Supabase client es NIL")
		return nil, fmt.Errorf("supabase client is nil")
	}

	fmt.Println("✅ [CategoriaRepo] Supabase client está inicializado")

	url := fmt.Sprintf("%s/rest/v1/categorias?activo=eq.true&order=orden.asc",
		config.AppConfig.SupabaseURL)

	responseBody, err := r.client.DoRequest(
		http.MethodGet,
		url,
		nil,
		r.client.GetAuthHeaders(),
	)

	if err != nil {
		fmt.Println("❌ [CategoriaRepo] Error listando:", err)
		return nil, fmt.Errorf("error al listar categorías: %w", err)
	}

	var categorias []models.Categoria
	if err := json.Unmarshal(responseBody, &categorias); err != nil {
		fmt.Println("❌ [CategoriaRepo] Error parseando respuesta:", err)
		return nil, fmt.Errorf("error al parsear respuesta: %w", err)
	}

	fmt.Printf("✅ [CategoriaRepo] Encontradas %d categorías\n", len(categorias))

	// ✅ IMPORTANTE: Devolver array vacío en lugar de nil
	if categorias == nil {
		fmt.Println("⚠️ [CategoriaRepo] categorias es nil, devolviendo array vacío")
		categorias = []models.Categoria{}
	}

	return categorias, nil
}

// Obtener categoría por ID
func (r *CategoriaRepository) ObtenerPorID(ctx context.Context, id uuid.UUID) (*models.Categoria, error) {
	fmt.Println("📥 [CategoriaRepo] ObtenerPorID - ID:", id)

	if r.client == nil {
		fmt.Println("❌ [CategoriaRepo] Supabase client es NIL")
		return nil, fmt.Errorf("supabase client is nil")
	}

	url := fmt.Sprintf("%s/rest/v1/categorias?id=eq.%s",
		config.AppConfig.SupabaseURL, id.String())

	responseBody, err := r.client.DoRequest(
		http.MethodGet,
		url,
		nil,
		r.client.GetAuthHeaders(),
	)

	if err != nil {
		fmt.Println("❌ [CategoriaRepo] Error obteniendo categoría:", err)
		return nil, fmt.Errorf("error al obtener categoría: %w", err)
	}

	var categorias []models.Categoria
	if err := json.Unmarshal(responseBody, &categorias); err != nil {
		fmt.Println("❌ [CategoriaRepo] Error parseando respuesta:", err)
		return nil, fmt.Errorf("error al parsear respuesta: %w", err)
	}

	if len(categorias) == 0 {
		fmt.Println("⚠️ [CategoriaRepo] Categoría no encontrada")
		return nil, fmt.Errorf("categoría no encontrada")
	}

	fmt.Println("✅ [CategoriaRepo] Categoría encontrada:", categorias[0].Nombre)
	return &categorias[0], nil
}
