package services

import (
	"context"
	"fmt"

	"recetario-backend/internal/models"
	"recetario-backend/internal/repository"

	"github.com/google/uuid"
)

type PortafolioService struct {
	repo           *repository.PortafolioRepository
	storageService *StorageService
}

func NewPortafolioService(repo *repository.PortafolioRepository, storageService *StorageService) *PortafolioService {
	return &PortafolioService{
		repo:           repo,
		storageService: storageService,
	}
}

func (s *PortafolioService) ObtenerOwnerIDPorUserID(ctx context.Context, userID uuid.UUID) (uuid.UUID, string, error) {
	fmt.Println("🔍 [Service] Buscando owner_id para user_id:", userID)

	ownerID, rol, err := s.repo.ObtenerOwnerIDPorUserID(ctx, userID)
	if err != nil {
		fmt.Println("❌ [Service] Error obteniendo owner_id:", err)
		return uuid.Nil, "", fmt.Errorf("usuario no autorizado para portafolio: %w", err)
	}

	fmt.Printf("✅ [Service] Owner ID encontrado: %s (rol: %s)\n", ownerID, rol)
	return ownerID, rol, nil
}

func (s *PortafolioService) ObtenerEstudianteIDPorUserID(ctx context.Context, userID uuid.UUID) (uuid.UUID, error) {
	ownerID, _, err := s.ObtenerOwnerIDPorUserID(ctx, userID)
	return ownerID, err
}

func (s *PortafolioService) Crear(ctx context.Context, ownerID uuid.UUID, req models.CrearPortafolioRequest) (*models.Portafolio, error) {
	return s.repo.Crear(ctx, ownerID, req)
}

// ==================== ✨ NUEVO: ACTUALIZAR RECETA ====================
func (s *PortafolioService) Actualizar(ctx context.Context, recetaID, ownerID uuid.UUID, req models.ActualizarPortafolioRequest) (*models.Portafolio, error) {
	// Verificar que la receta exista y pertenezca al owner
	recetaExistente, err := s.repo.ObtenerPorID(ctx, recetaID)
	if err != nil {
		return nil, fmt.Errorf("receta no encontrada: %w", err)
	}

	if recetaExistente.EstudianteID != ownerID {
		return nil, fmt.Errorf("no tienes permiso para actualizar esta receta")
	}

	// Actualizar en el repository
	return s.repo.Actualizar(ctx, recetaID, ownerID, req)
}

func (s *PortafolioService) ObtenerMisRecetas(ctx context.Context, ownerID uuid.UUID) ([]models.Portafolio, error) {
	return s.repo.ObtenerPorOwner(ctx, ownerID)
}

func (s *PortafolioService) ObtenerPublicas(ctx context.Context) ([]models.PortafolioConEstudiante, error) {
	return s.repo.ObtenerPublicas(ctx)
}

func (s *PortafolioService) ObtenerPorID(ctx context.Context, id uuid.UUID) (*models.PortafolioConEstudiante, error) {
	return s.repo.ObtenerPorID(ctx, id)
}

// ==================== ✨ NUEVO: ELIMINAR CON LIMPIEZA DE STORAGE ====================
func (s *PortafolioService) EliminarConStorage(ctx context.Context, id uuid.UUID, ownerID uuid.UUID) error {
	// 1. Obtener la receta para verificar permisos y obtener URLs de fotos
	receta, err := s.repo.ObtenerPorID(ctx, id)
	if err != nil {
		return fmt.Errorf("receta no encontrada: %w", err)
	}

	if receta.EstudianteID != ownerID {
		return fmt.Errorf("no tienes permiso para eliminar esta receta")
	}

	// 2. Eliminar fotos del Storage
	if len(receta.Fotos) > 0 {
		fmt.Printf("🗑️ [Service] Eliminando %d fotos del Storage...\n", len(receta.Fotos))

		for _, fotoURL := range receta.Fotos {
			if err := s.storageService.DeleteFile(fotoURL); err != nil {
				fmt.Printf("⚠️ [Service] Error eliminando foto %s: %v\n", fotoURL, err)
				// No retornar error, continuar con la eliminación
			} else {
				fmt.Printf("✅ [Service] Foto eliminada: %s\n", fotoURL)
			}
		}
	}

	// 3. Eliminar de la base de datos
	return s.repo.Eliminar(ctx, id, ownerID)
}

// ✅ MANTENER: Por compatibilidad
func (s *PortafolioService) Eliminar(ctx context.Context, id uuid.UUID, ownerID uuid.UUID) error {
	return s.repo.Eliminar(ctx, id, ownerID)
}

// ==================== LIKES ====================

func (s *PortafolioService) ToggleLike(ctx context.Context, portafolioID, usuarioID uuid.UUID) (bool, error) {
	yaDioLike, err := s.repo.YaDioLike(ctx, portafolioID, usuarioID)
	if err != nil {
		return false, fmt.Errorf("error verificando like: %w", err)
	}

	if yaDioLike {
		err = s.repo.QuitarLike(ctx, portafolioID, usuarioID)
		if err != nil {
			return false, fmt.Errorf("error quitando like: %w", err)
		}
		return false, nil
	} else {
		err = s.repo.DarLike(ctx, portafolioID, usuarioID)
		if err != nil {
			return false, fmt.Errorf("error dando like: %w", err)
		}
		return true, nil
	}
}

func (s *PortafolioService) YaDioLike(ctx context.Context, portafolioID, usuarioID uuid.UUID) (bool, error) {
	return s.repo.YaDioLike(ctx, portafolioID, usuarioID)
}

// ==================== COMENTARIOS ====================

func (s *PortafolioService) CrearComentario(ctx context.Context, portafolioID, usuarioID uuid.UUID, req models.CrearComentarioRequest) (*models.ComentarioPortafolio, error) {
	if req.Comentario == "" {
		return nil, fmt.Errorf("el comentario no puede estar vacío")
	}

	return s.repo.CrearComentario(ctx, portafolioID, usuarioID, req.Comentario)
}

func (s *PortafolioService) ObtenerComentarios(ctx context.Context, portafolioID uuid.UUID) ([]models.ComentarioConUsuario, error) {
	return s.repo.ObtenerComentarios(ctx, portafolioID)
}
