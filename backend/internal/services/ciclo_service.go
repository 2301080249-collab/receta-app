package services

import (
	"encoding/json"
	"fmt"
	"recetario-backend/internal/models"
	"recetario-backend/internal/repository"
	"time"
)

// ✅ CicloService con dependency injection
type CicloService struct {
	cicloRepo repository.CicloRepository
}

// ✅ Constructor actualizado
func NewCicloService(cicloRepo repository.CicloRepository) *CicloService {
	return &CicloService{
		cicloRepo: cicloRepo,
	}
}

func (s *CicloService) CrearCiclo(req *models.CrearCicloRequest) (string, error) {
	// Validar datos
	if err := s.validarCiclo(req.Nombre, req.FechaInicio, req.FechaFin, req.DuracionSemanas); err != nil {
		return "", err
	}

	// Crear ciclo
	cicloData := map[string]interface{}{
		"nombre":           req.Nombre,
		"fecha_inicio":     req.FechaInicio,
		"fecha_fin":        req.FechaFin,
		"duracion_semanas": req.DuracionSemanas,
		"activo":           false,
	}

	respBody, err := s.cicloRepo.CreateCiclo(cicloData)
	if err != nil {
		return "", fmt.Errorf("error al crear ciclo: %w", err)
	}

	// Parsear respuesta para obtener el ID
	var ciclos []map[string]interface{}
	if err := json.Unmarshal(respBody, &ciclos); err != nil || len(ciclos) == 0 {
		return "", fmt.Errorf("error al parsear respuesta")
	}

	cicloID, ok := ciclos[0]["id"].(string)
	if !ok {
		return "", fmt.Errorf("no se pudo obtener el ID del ciclo creado")
	}

	return cicloID, nil
}

func (s *CicloService) ListarCiclos() ([]models.Ciclo, error) {
	respBody, err := s.cicloRepo.GetAllCiclos()
	if err != nil {
		return nil, fmt.Errorf("error al obtener ciclos: %w", err)
	}

	var ciclos []models.Ciclo
	if err := json.Unmarshal(respBody, &ciclos); err != nil {
		return nil, fmt.Errorf("error al parsear ciclos")
	}

	return ciclos, nil
}

func (s *CicloService) ObtenerCicloPorID(cicloID string) (*models.Ciclo, error) {
	respBody, err := s.cicloRepo.GetCicloByID(cicloID)
	if err != nil {
		return nil, fmt.Errorf("ciclo no encontrado")
	}

	var ciclos []models.Ciclo
	if err := json.Unmarshal(respBody, &ciclos); err != nil || len(ciclos) == 0 {
		return nil, fmt.Errorf("ciclo no encontrado")
	}

	return &ciclos[0], nil
}

func (s *CicloService) ActualizarCiclo(cicloID string, req *models.ActualizarCicloRequest) error {
	// Construir datos a actualizar
	updateData := make(map[string]interface{})

	if req.Nombre != nil {
		updateData["nombre"] = *req.Nombre
	}
	if req.FechaInicio != nil {
		updateData["fecha_inicio"] = *req.FechaInicio
	}
	if req.FechaFin != nil {
		updateData["fecha_fin"] = *req.FechaFin
	}
	if req.DuracionSemanas != nil {
		updateData["duracion_semanas"] = *req.DuracionSemanas
	}
	if req.Activo != nil {
		if *req.Activo {
			if err := s.desactivarTodosCiclos(); err != nil {
				return fmt.Errorf("error al desactivar otros ciclos: %w", err)
			}
		}
		updateData["activo"] = *req.Activo
	}

	if len(updateData) == 0 {
		return fmt.Errorf("no hay datos para actualizar")
	}

	if err := s.cicloRepo.UpdateCiclo(cicloID, updateData); err != nil {
		return fmt.Errorf("error al actualizar ciclo: %w", err)
	}

	return nil
}

func (s *CicloService) EliminarCiclo(cicloID string) error {
	// ✅ VALIDACIÓN: Verificar si tiene cursos
	tieneCursos, err := s.cicloRepo.CicloTieneCursos(cicloID)
	if err != nil {
		return fmt.Errorf("error al verificar cursos: %w", err)
	}

	if tieneCursos {
		return fmt.Errorf("No se puede eliminar el ciclo porque tiene cursos registrados")
	}

	// Si no tiene cursos, proceder con la eliminación
	if err := s.cicloRepo.DeleteCiclo(cicloID); err != nil {
		return fmt.Errorf("error al eliminar ciclo: %w", err)
	}

	return nil
}

func (s *CicloService) ActivarCiclo(cicloID string) error {
	// Desactivar todos los ciclos
	if err := s.desactivarTodosCiclos(); err != nil {
		return err
	}

	// Activar el ciclo seleccionado
	updateData := map[string]interface{}{
		"activo": true,
	}

	if err := s.cicloRepo.UpdateCiclo(cicloID, updateData); err != nil {
		return fmt.Errorf("error al activar ciclo: %w", err)
	}

	return nil
}

func (s *CicloService) DesactivarCiclo(cicloID string) error {
	updateData := map[string]interface{}{
		"activo": false,
	}

	if err := s.cicloRepo.UpdateCiclo(cicloID, updateData); err != nil {
		return fmt.Errorf("error al desactivar ciclo: %w", err)
	}

	return nil
}

func (s *CicloService) ObtenerCicloActivo() (*models.Ciclo, error) {
	respBody, err := s.cicloRepo.GetCicloActivo()
	if err != nil {
		return nil, fmt.Errorf("no hay ciclo activo")
	}

	var ciclos []models.Ciclo
	if err := json.Unmarshal(respBody, &ciclos); err != nil || len(ciclos) == 0 {
		return nil, fmt.Errorf("no hay ciclo activo")
	}

	return &ciclos[0], nil
}

func (s *CicloService) desactivarTodosCiclos() error {
	ciclos, err := s.ListarCiclos()
	if err != nil {
		return err
	}

	for _, ciclo := range ciclos {
		if ciclo.Activo {
			updateData := map[string]interface{}{
				"activo": false,
			}
			if err := s.cicloRepo.UpdateCiclo(ciclo.ID, updateData); err != nil {
				return err
			}
		}
	}

	return nil
}

func (s *CicloService) validarCiclo(nombre, fechaInicio, fechaFin string, duracion int) error {
	if nombre == "" {
		return fmt.Errorf("el nombre del ciclo es obligatorio")
	}

	if fechaInicio == "" || fechaFin == "" {
		return fmt.Errorf("las fechas de inicio y fin son obligatorias")
	}

	inicio, err := time.Parse("2006-01-02", fechaInicio)
	if err != nil {
		return fmt.Errorf("formato de fecha de inicio inválido (usar YYYY-MM-DD)")
	}

	fin, err := time.Parse("2006-01-02", fechaFin)
	if err != nil {
		return fmt.Errorf("formato de fecha de fin inválido (usar YYYY-MM-DD)")
	}

	if !fin.After(inicio) {
		return fmt.Errorf("la fecha de fin debe ser posterior a la fecha de inicio")
	}

	if duracion < 1 || duracion > 52 {
		return fmt.Errorf("la duración debe estar entre 1 y 52 semanas")
	}

	return nil
}
