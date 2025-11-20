package services

import (
	"context"

	"recetario-backend/internal/models"
	"recetario-backend/internal/repository"

	"github.com/google/uuid"
)

type CategoriaService struct {
	repo *repository.CategoriaRepository
}

func NewCategoriaService(repo *repository.CategoriaRepository) *CategoriaService {
	return &CategoriaService{repo: repo}
}

// Crear categoría
func (s *CategoriaService) Crear(ctx context.Context, req models.CrearCategoriaRequest) (*models.Categoria, error) {
	return s.repo.Crear(ctx, req)
}

// Listar categorías activas
func (s *CategoriaService) ListarActivas(ctx context.Context) ([]models.Categoria, error) {
	return s.repo.ListarActivas(ctx)
}

// Obtener categoría por ID
func (s *CategoriaService) ObtenerPorID(ctx context.Context, id uuid.UUID) (*models.Categoria, error) {
	return s.repo.ObtenerPorID(ctx, id)
}
