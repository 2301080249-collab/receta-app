package services

import (
	"encoding/json"
	"fmt"
	"recetario-backend/internal/models"
	"recetario-backend/internal/repository"
	"time"
)

// ✅ MatriculaService con dependency injection
type MatriculaService struct {
	matriculaRepo repository.MatriculaRepository
	usuarioRepo   repository.UsuarioRepository
	cursoRepo     repository.CursoRepository
	cicloRepo     repository.CicloRepository
}

// ✅ Constructor actualizado
func NewMatriculaService(
	matriculaRepo repository.MatriculaRepository,
	usuarioRepo repository.UsuarioRepository,
	cursoRepo repository.CursoRepository,
	cicloRepo repository.CicloRepository,
) *MatriculaService {
	return &MatriculaService{
		matriculaRepo: matriculaRepo,
		usuarioRepo:   usuarioRepo,
		cursoRepo:     cursoRepo,
		cicloRepo:     cicloRepo,
	}
}

func (s *MatriculaService) CrearMatricula(req *models.CrearMatriculaRequest) (*models.Matricula, error) {
	// Validar que el estudiante existe
	if _, err := s.usuarioRepo.GetUserByID(req.EstudianteID); err != nil {
		return nil, fmt.Errorf("estudiante no encontrado")
	}

	// Validar que el curso existe
	if _, err := s.cursoRepo.GetCursoByID(req.CursoID); err != nil {
		return nil, fmt.Errorf("curso no encontrado")
	}

	// Validar que el ciclo existe
	if _, err := s.cicloRepo.GetCicloByID(req.CicloID); err != nil {
		return nil, fmt.Errorf("ciclo no encontrado")
	}

	// Verificar si ya está matriculado
	existeResp, err := s.matriculaRepo.CheckMatriculaExists(req.EstudianteID, req.CursoID, req.CicloID)
	if err == nil {
		var existentes []models.Matricula
		if err := json.Unmarshal(existeResp, &existentes); err == nil && len(existentes) > 0 {
			return nil, fmt.Errorf("el estudiante ya está matriculado en este curso")
		}
	}

	// ✅ Crear la matrícula con los nuevos campos
	matriculaData := map[string]interface{}{
		"estudiante_id":   req.EstudianteID,
		"curso_id":        req.CursoID,
		"ciclo_id":        req.CicloID,
		"estado":          "activo",   // Por defecto
		"fecha_matricula": time.Now(), // ✅ NUEVO: Fecha actual
	}

	// ✅ NUEVO: Agregar estado personalizado si viene en el request
	if req.Estado != nil && *req.Estado != "" {
		matriculaData["estado"] = *req.Estado
	}

	// ✅ NUEVO: Agregar observaciones si vienen en el request
	if req.Observaciones != nil && *req.Observaciones != "" {
		matriculaData["observaciones"] = *req.Observaciones
	}

	respBody, err := s.matriculaRepo.CreateMatricula(matriculaData)
	if err != nil {
		return nil, fmt.Errorf("error al crear matrícula: %w", err)
	}

	var matriculas []models.Matricula
	if err := json.Unmarshal(respBody, &matriculas); err != nil || len(matriculas) == 0 {
		return nil, fmt.Errorf("error al parsear respuesta")
	}

	return &matriculas[0], nil
}

func (s *MatriculaService) CrearMatriculaMasiva(req *models.MatriculaMasivaRequest) ([]models.Matricula, []string, error) {
	var matriculas []models.Matricula
	var errores []string

	// ✅ MODIFICADO: Pasar estado y observaciones a cada matrícula individual
	for _, estudianteID := range req.EstudiantesIDs {
		createReq := &models.CrearMatriculaRequest{
			EstudianteID:  estudianteID,
			CursoID:       req.CursoID,
			CicloID:       req.CicloID,
			Estado:        req.Estado,        // ✅ NUEVO: Pasar estado si existe
			Observaciones: req.Observaciones, // ✅ NUEVO: Pasar observaciones si existen
		}

		matricula, err := s.CrearMatricula(createReq)
		if err != nil {
			errores = append(errores, fmt.Sprintf("Error con estudiante %s: %v", estudianteID, err))
			continue
		}

		if matricula != nil {
			matriculas = append(matriculas, *matricula)
		}
	}

	var finalErr error
	if len(errores) > 0 {
		finalErr = fmt.Errorf("algunos estudiantes no pudieron ser matriculados")
	}

	return matriculas, errores, finalErr
}

func (s *MatriculaService) ListarMatriculasPorCurso(cursoID string) ([]models.Matricula, error) {
	respBody, err := s.matriculaRepo.GetMatriculasByCurso(cursoID)
	if err != nil {
		return nil, fmt.Errorf("error al obtener matrículas: %w", err)
	}

	var matriculas []models.Matricula
	if err := json.Unmarshal(respBody, &matriculas); err != nil {
		fmt.Println("Error al parsear matrículas por curso:", err)
		fmt.Println("Respuesta:", string(respBody))
		return nil, fmt.Errorf("error al parsear matrículas")
	}

	return matriculas, nil
}

func (s *MatriculaService) ListarMatriculasPorEstudiante(estudianteID string) ([]models.Matricula, error) {
	respBody, err := s.matriculaRepo.GetMatriculasByEstudiante(estudianteID)
	if err != nil {
		return nil, fmt.Errorf("error al obtener matrículas: %w", err)
	}

	var matriculas []models.Matricula
	if err := json.Unmarshal(respBody, &matriculas); err != nil {
		fmt.Println("Error al parsear matrículas por estudiante:", err)
		fmt.Println("Respuesta:", string(respBody))
		return nil, fmt.Errorf("error al parsear matrículas")
	}

	return matriculas, nil
}

func (s *MatriculaService) ListarEstudiantesDisponibles(cursoID, cicloID string) ([]models.Usuario, error) {
	// Obtener todos los estudiantes
	respBody, err := s.usuarioRepo.GetEstudiantesDisponibles(cursoID, cicloID)
	if err != nil {
		return nil, fmt.Errorf("error al obtener estudiantes: %w", err)
	}

	var todosEstudiantes []models.Usuario
	if err := json.Unmarshal(respBody, &todosEstudiantes); err != nil {
		return nil, fmt.Errorf("error al parsear estudiantes")
	}

	// Obtener matrículas existentes del curso
	matriculasResp, err := s.matriculaRepo.GetMatriculasByCurso(cursoID)
	if err != nil {
		return todosEstudiantes, nil
	}

	var matriculas []models.Matricula
	json.Unmarshal(matriculasResp, &matriculas)

	// Filtrar estudiantes ya matriculados
	matriculadosMap := make(map[string]bool)
	for _, m := range matriculas {
		if m.CicloID == cicloID {
			matriculadosMap[m.EstudianteID] = true
		}
	}

	var disponibles []models.Usuario
	for _, est := range todosEstudiantes {
		if !matriculadosMap[est.ID] {
			disponibles = append(disponibles, est)
		}
	}

	return disponibles, nil
}

func (s *MatriculaService) ActualizarMatricula(matriculaID string, req *models.ActualizarMatriculaRequest) error {
	updateData := make(map[string]interface{})

	if req.Estado != nil {
		updateData["estado"] = *req.Estado
	}

	if req.NotaFinal != nil {
		updateData["nota_final"] = *req.NotaFinal
	}

	// ✅ NUEVO: Agregar observaciones si vienen en el request
	if req.Observaciones != nil {
		updateData["observaciones"] = *req.Observaciones
	}

	if len(updateData) == 0 {
		return fmt.Errorf("no hay datos para actualizar")
	}

	if err := s.matriculaRepo.UpdateMatricula(matriculaID, updateData); err != nil {
		return fmt.Errorf("error al actualizar matrícula: %w", err)
	}

	return nil
}

func (s *MatriculaService) EliminarMatricula(matriculaID string) error {
	if err := s.matriculaRepo.DeleteMatricula(matriculaID); err != nil {
		return fmt.Errorf("error al eliminar matrícula: %w", err)
	}

	return nil
}

func (s *MatriculaService) ListarTodasLasMatriculas() (json.RawMessage, error) {
	respBody, err := s.matriculaRepo.GetAllMatriculas()
	if err != nil {
		return nil, fmt.Errorf("error al obtener matrículas: %w", err)
	}

	return json.RawMessage(respBody), nil
}
