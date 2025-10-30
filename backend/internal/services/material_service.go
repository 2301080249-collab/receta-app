package services

import (
	"context"
	"fmt"

	"recetario-backend/internal/models"
	"recetario-backend/internal/repository"

	"github.com/google/uuid"
)

type MaterialService struct {
	materialRepo   *repository.MaterialRepository
	storageService *StorageService
}

func NewMaterialService(
	materialRepo *repository.MaterialRepository,
	storageService *StorageService,
) *MaterialService {
	return &MaterialService{
		materialRepo:   materialRepo,
		storageService: storageService,
	}
}

// Crear material
func (s *MaterialService) CrearMaterial(ctx context.Context, req *models.CreateMaterialRequest) (*models.Material, error) {
	return s.materialRepo.Create(ctx, req)
}

// ✅ ACTUALIZADO: Actualizar material (elimina archivo viejo si se cambia)
func (s *MaterialService) ActualizarMaterial(ctx context.Context, materialID uuid.UUID, req *models.UpdateMaterialRequest) (*models.Material, error) {
	// Si se está actualizando la URL del archivo, eliminar el archivo viejo
	if req.URLArchivo != nil && *req.URLArchivo != "" {
		// Obtener el material actual para saber el archivo viejo
		materialActual, err := s.materialRepo.GetByID(ctx, materialID)
		if err != nil {
			return nil, fmt.Errorf("error al obtener material actual: %w", err)
		}

		// Si el archivo viejo existe y es diferente al nuevo, eliminarlo
		if materialActual.URLArchivo != "" && materialActual.URLArchivo != *req.URLArchivo {
			// Eliminar archivo viejo del Storage usando el método existente
			if err := s.storageService.DeleteFile(materialActual.URLArchivo); err != nil {
				// Log del error pero no fallar la actualización
				fmt.Printf("Warning: No se pudo eliminar archivo viejo del Storage: %v\n", err)
			}
		}
	}

	// Actualizar el material en la BD
	return s.materialRepo.Update(ctx, materialID, req)
}

// Marcar material como visto por estudiante
func (s *MaterialService) MarcarComoVisto(ctx context.Context, materialID, estudianteID uuid.UUID) error {
	return s.materialRepo.MarcarComoVisto(ctx, materialID, estudianteID)
}

// ✅ ACTUALIZADO: Eliminar material (y su archivo del storage)
func (s *MaterialService) EliminarMaterial(ctx context.Context, materialID uuid.UUID) error {
	// 1. Obtener el material para saber la URL del archivo
	material, err := s.materialRepo.GetByID(ctx, materialID)
	if err != nil {
		return fmt.Errorf("error al obtener material: %w", err)
	}

	// 2. Eliminar el archivo del Storage si existe
	if material.URLArchivo != "" {
		if err := s.storageService.DeleteFile(material.URLArchivo); err != nil {
			// Log del error pero continuar con la eliminación del registro
			fmt.Printf("Warning: No se pudo eliminar archivo del Storage: %v\n", err)
		}
	}

	// 3. Eliminar el registro de la BD
	return s.materialRepo.Delete(ctx, materialID)
}
