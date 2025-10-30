package services

import (
	"encoding/json"
	"fmt"
	"recetario-backend/internal/models"
	"recetario-backend/internal/repository"
)

// ✅ CursoService con dependency injection
type CursoService struct {
	cursoRepo   repository.CursoRepository
	cicloRepo   repository.CicloRepository
	usuarioRepo repository.UsuarioRepository
	temaRepo    *repository.TemaRepository // ✅ AGREGADO
}

// ✅ Constructor actualizado con temaRepo
func NewCursoService(
	cursoRepo repository.CursoRepository,
	cicloRepo repository.CicloRepository,
	usuarioRepo repository.UsuarioRepository,
	temaRepo *repository.TemaRepository, // ✅ NUEVO PARÁMETRO
) *CursoService {
	return &CursoService{
		cursoRepo:   cursoRepo,
		cicloRepo:   cicloRepo,
		usuarioRepo: usuarioRepo,
		temaRepo:    temaRepo, // ✅ ASIGNAR
	}
}

func (s *CursoService) CrearCurso(req *models.CrearCursoRequest) (string, error) {
	// Validar datos
	if err := s.validarCurso(req); err != nil {
		return "", err
	}

	// Verificar que el ciclo existe
	if _, err := s.cicloRepo.GetCicloByID(req.CicloID); err != nil {
		return "", fmt.Errorf("el ciclo seleccionado no existe")
	}

	// Verificar que el docente existe
	if _, err := s.usuarioRepo.GetUserByID(req.DocenteID); err != nil {
		return "", fmt.Errorf("el docente seleccionado no existe")
	}

	// Crear curso
	cursoData := map[string]interface{}{
		"nombre":      req.Nombre,
		"descripcion": req.Descripcion,
		"docente_id":  req.DocenteID,
		"ciclo_id":    req.CicloID,
		"nivel":       req.Nivel,
		"seccion":     req.Seccion,
		"creditos":    req.Creditos,
		"horario":     req.Horario,
		"activo":      true,
	}

	respBody, err := s.cursoRepo.CreateCurso(cursoData)
	if err != nil {
		return "", fmt.Errorf("error al crear curso: %w", err)
	}

	// Parsear respuesta para obtener el ID
	var cursos []map[string]interface{}
	if err := json.Unmarshal(respBody, &cursos); err != nil || len(cursos) == 0 {
		return "", fmt.Errorf("error al parsear respuesta")
	}

	cursoID, ok := cursos[0]["id"].(string)
	if !ok {
		return "", fmt.Errorf("no se pudo obtener el ID del curso creado")
	}

	// ✅ NUEVO: Crear los 16 temas automáticamente
	if err := s.crearTemasIniciales(cursoID); err != nil {
		// Log el error pero no falla la creación del curso
		fmt.Printf("⚠️ Error al crear temas iniciales: %v\n", err)
	} else {
		fmt.Printf("✅ Creados 16 temas para el curso %s\n", cursoID)
	}

	return cursoID, nil
}

// ✅ NUEVO: Método para crear los 16 temas iniciales
func (s *CursoService) crearTemasIniciales(cursoID string) error {
	for i := 1; i <= 16; i++ {
		temaData := map[string]interface{}{
			"curso_id":    cursoID,
			"titulo":      fmt.Sprintf("Tema %d", i),
			"descripcion": nil,
			"orden":       i,
			"activo":      true,
		}

		_, err := s.temaRepo.CreateTema(temaData)
		if err != nil {
			return fmt.Errorf("error creando tema %d: %w", i, err)
		}
	}

	return nil
}

func (s *CursoService) ListarCursos() ([]models.Curso, error) {
	respBody, err := s.cursoRepo.GetAllCursos()
	if err != nil {
		return nil, fmt.Errorf("error al obtener cursos: %w", err)
	}

	var cursos []models.Curso
	if err := json.Unmarshal(respBody, &cursos); err != nil {
		return nil, fmt.Errorf("error al parsear cursos")
	}

	return cursos, nil
}

func (s *CursoService) ListarCursosPorCiclo(cicloID string) ([]models.Curso, error) {
	respBody, err := s.cursoRepo.GetCursosByCiclo(cicloID)
	if err != nil {
		return nil, fmt.Errorf("error al obtener cursos: %w", err)
	}

	var cursos []models.Curso
	if err := json.Unmarshal(respBody, &cursos); err != nil {
		return nil, fmt.Errorf("error al parsear cursos")
	}

	return cursos, nil
}

func (s *CursoService) ListarCursosPorDocente(docenteID string) ([]models.Curso, error) {
	respBody, err := s.cursoRepo.GetCursosByDocente(docenteID)
	if err != nil {
		return nil, fmt.Errorf("error al obtener cursos: %w", err)
	}

	var cursos []models.Curso
	if err := json.Unmarshal(respBody, &cursos); err != nil {
		return nil, fmt.Errorf("error al parsear cursos")
	}

	return cursos, nil
}

func (s *CursoService) ObtenerCursoPorID(cursoID string) (*models.Curso, error) {
	respBody, err := s.cursoRepo.GetCursoByID(cursoID)
	if err != nil {
		return nil, fmt.Errorf("curso no encontrado")
	}

	var cursos []models.Curso
	if err := json.Unmarshal(respBody, &cursos); err != nil || len(cursos) == 0 {
		return nil, fmt.Errorf("curso no encontrado")
	}

	return &cursos[0], nil
}

func (s *CursoService) ActualizarCurso(cursoID string, req *models.ActualizarCursoRequest) error {
	// Construir datos a actualizar
	updateData := make(map[string]interface{})

	if req.Nombre != nil {
		updateData["nombre"] = *req.Nombre
	}
	if req.Descripcion != nil {
		updateData["descripcion"] = *req.Descripcion
	}
	if req.DocenteID != nil {
		// Verificar que el docente existe
		if _, err := s.usuarioRepo.GetUserByID(*req.DocenteID); err != nil {
			return fmt.Errorf("el docente seleccionado no existe")
		}
		updateData["docente_id"] = *req.DocenteID
	}
	if req.CicloID != nil {
		// Verificar que el ciclo existe
		if _, err := s.cicloRepo.GetCicloByID(*req.CicloID); err != nil {
			return fmt.Errorf("el ciclo seleccionado no existe")
		}
		updateData["ciclo_id"] = *req.CicloID
	}
	if req.Nivel != nil {
		updateData["nivel"] = *req.Nivel
	}
	if req.Seccion != nil {
		updateData["seccion"] = *req.Seccion
	}
	if req.Creditos != nil {
		updateData["creditos"] = *req.Creditos
	}
	if req.Horario != nil {
		updateData["horario"] = *req.Horario
	}
	if req.Activo != nil {
		updateData["activo"] = *req.Activo
	}

	if len(updateData) == 0 {
		return fmt.Errorf("no hay datos para actualizar")
	}

	if err := s.cursoRepo.UpdateCurso(cursoID, updateData); err != nil {
		return fmt.Errorf("error al actualizar curso: %w", err)
	}

	return nil
}

func (s *CursoService) EliminarCurso(cursoID string) error {
	if err := s.cursoRepo.DeleteCurso(cursoID); err != nil {
		return fmt.Errorf("error al eliminar curso: %w", err)
	}

	return nil
}

func (s *CursoService) ActivarCurso(cursoID string) error {
	updateData := map[string]interface{}{
		"activo": true,
	}

	if err := s.cursoRepo.UpdateCurso(cursoID, updateData); err != nil {
		return fmt.Errorf("error al activar curso: %w", err)
	}

	return nil
}

func (s *CursoService) DesactivarCurso(cursoID string) error {
	updateData := map[string]interface{}{
		"activo": false,
	}

	if err := s.cursoRepo.UpdateCurso(cursoID, updateData); err != nil {
		return fmt.Errorf("error al desactivar curso: %w", err)
	}

	return nil
}

func (s *CursoService) validarCurso(req *models.CrearCursoRequest) error {
	if req.Nombre == "" {
		return fmt.Errorf("el nombre del curso es obligatorio")
	}

	if req.DocenteID == "" {
		return fmt.Errorf("debe asignar un docente al curso")
	}

	if req.CicloID == "" {
		return fmt.Errorf("debe asignar un ciclo al curso")
	}

	if req.Nivel < 1 || req.Nivel > 10 {
		return fmt.Errorf("el nivel debe estar entre 1 y 10")
	}

	if req.Creditos < 1 || req.Creditos > 10 {
		return fmt.Errorf("los créditos deben estar entre 1 y 10")
	}

	return nil
}

// ✅ NUEVO: Listar cursos del estudiante
func (s *CursoService) ListarCursosPorEstudiante(estudianteID string) ([]models.Curso, error) {
	respBody, err := s.cursoRepo.GetCursosByEstudiante(estudianteID)
	if err != nil {
		return nil, fmt.Errorf("error al obtener cursos: %w", err)
	}

	var cursos []models.Curso
	if err := json.Unmarshal(respBody, &cursos); err != nil {
		return nil, fmt.Errorf("error al parsear cursos")
	}

	return cursos, nil
}
