package services

import (
	"bytes"
	"encoding/json"
	"fmt"
	"recetario-backend/internal/models"
	"recetario-backend/internal/repository"
	"time"

	"github.com/xuri/excelize/v2"
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
	// ✅ DESPUÉS: Validar que existe en tabla estudiantes (que es la que tiene FK)
	respBody, err := s.usuarioRepo.GetEstudianteByUserID(req.EstudianteID)
	if err != nil {
		return nil, fmt.Errorf("estudiante no encontrado en el sistema")
	}

	var estudiantes []map[string]interface{}
	if err := json.Unmarshal(respBody, &estudiantes); err != nil || len(estudiantes) == 0 {
		return nil, fmt.Errorf("el usuario no tiene perfil de estudiante activo")
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
		"estado":          "activo",
		"fecha_matricula": time.Now(),
	}

	if req.Estado != nil && *req.Estado != "" {
		matriculaData["estado"] = *req.Estado
	}

	if req.Observaciones != nil && *req.Observaciones != "" {
		matriculaData["observaciones"] = *req.Observaciones
	}

	respBody, err = s.matriculaRepo.CreateMatricula(matriculaData)
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

// ✅ NUEVO: Exportar participantes de un curso a Excel
func (s *MatriculaService) ExportarParticipantesExcel(cursoID string) (*bytes.Buffer, string, error) {
	// Obtener las matrículas del curso
	matriculas, err := s.ListarMatriculasPorCurso(cursoID)
	if err != nil {
		return nil, "", fmt.Errorf("error al obtener participantes: %w", err)
	}

	if len(matriculas) == 0 {
		return nil, "", fmt.Errorf("no hay participantes en este curso")
	}

	// Obtener información del curso para el nombre del archivo
	nombreCurso := "Curso"
	if len(matriculas) > 0 {
		// Parsear el JSON crudo para obtener datos del curso
		respBody, err := s.matriculaRepo.GetMatriculasByCurso(cursoID)
		if err == nil {
			var rawData []map[string]interface{}
			if err := json.Unmarshal(respBody, &rawData); err == nil && len(rawData) > 0 {
				if cursos, ok := rawData[0]["cursos"].(map[string]interface{}); ok {
					if nombre, ok := cursos["nombre"].(string); ok {
						nombreCurso = nombre
					}
				}
			}
		}
	}

	// Crear un nuevo archivo Excel
	f := excelize.NewFile()
	defer f.Close()

	// Crear hoja principal
	sheetName := "Participantes"
	index, err := f.NewSheet(sheetName)
	if err != nil {
		return nil, "", fmt.Errorf("error al crear hoja: %w", err)
	}

	// Establecer como hoja activa
	f.SetActiveSheet(index)

	// Eliminar la hoja por defecto
	f.DeleteSheet("Sheet1")

	// Definir estilos
	headerStyle, _ := f.NewStyle(&excelize.Style{
		Font: &excelize.Font{
			Bold:  true,
			Size:  12,
			Color: "#FFFFFF",
		},
		Fill: excelize.Fill{
			Type:    "pattern",
			Color:   []string{"#2E7D32"},
			Pattern: 1,
		},
		Alignment: &excelize.Alignment{
			Horizontal: "center",
			Vertical:   "center",
		},
		Border: []excelize.Border{
			{Type: "left", Color: "#CCCCCC", Style: 1},
			{Type: "right", Color: "#CCCCCC", Style: 1},
			{Type: "top", Color: "#CCCCCC", Style: 1},
			{Type: "bottom", Color: "#CCCCCC", Style: 1},
		},
	})

	cellStyle, _ := f.NewStyle(&excelize.Style{
		Alignment: &excelize.Alignment{
			Vertical: "center",
		},
		Border: []excelize.Border{
			{Type: "left", Color: "#EEEEEE", Style: 1},
			{Type: "right", Color: "#EEEEEE", Style: 1},
			{Type: "top", Color: "#EEEEEE", Style: 1},
			{Type: "bottom", Color: "#EEEEEE", Style: 1},
		},
	})

	// Escribir encabezados
	headers := []string{"Nombre Completo", "Código", "Email", "Rol", "Último Acceso"}
	for i, header := range headers {
		cell := string(rune('A'+i)) + "1"
		f.SetCellValue(sheetName, cell, header)
		f.SetCellStyle(sheetName, cell, cell, headerStyle)
	}

	// Ajustar anchos de columna
	f.SetColWidth(sheetName, "A", "A", 30) // Nombre
	f.SetColWidth(sheetName, "B", "B", 15) // Código
	f.SetColWidth(sheetName, "C", "C", 30) // Email
	f.SetColWidth(sheetName, "D", "D", 15) // Rol
	f.SetColWidth(sheetName, "E", "E", 20) // Último Acceso

	// Escribir datos
	for i, _ := range matriculas {
		row := i + 2

		// Parsear datos anidados del JSON crudo
		respBody, _ := s.matriculaRepo.GetMatriculasByCurso(cursoID)
		var rawData []map[string]interface{}
		json.Unmarshal(respBody, &rawData)

		nombreEstudiante := "-"
		codigoEstudiante := "-"
		emailEstudiante := "-"
		ultimoAcceso := "-"

		if i < len(rawData) {
			if estudiantes, ok := rawData[i]["estudiantes"].(map[string]interface{}); ok {
				if codigo, ok := estudiantes["codigo_estudiante"].(string); ok {
					codigoEstudiante = codigo
				}

				if usuarios, ok := estudiantes["usuarios"].(map[string]interface{}); ok {
					if nombre, ok := usuarios["nombre_completo"].(string); ok {
						nombreEstudiante = nombre
					}
					if email, ok := usuarios["email"].(string); ok {
						emailEstudiante = email
					}
				}
			}

			if createdAt, ok := rawData[i]["created_at"].(string); ok {
				if t, err := time.Parse(time.RFC3339, createdAt); err == nil {
					diff := time.Since(t)
					days := int(diff.Hours() / 24)
					hours := int(diff.Hours()) % 24

					if days > 0 {
						if hours > 0 {
							ultimoAcceso = fmt.Sprintf("%d días %d horas", days, hours)
						} else {
							ultimoAcceso = fmt.Sprintf("%d días", days)
						}
					} else if int(diff.Hours()) > 0 {
						ultimoAcceso = fmt.Sprintf("%d horas", int(diff.Hours()))
					} else if int(diff.Minutes()) > 0 {
						ultimoAcceso = fmt.Sprintf("%d minutos", int(diff.Minutes()))
					} else {
						ultimoAcceso = "Ahora"
					}
				}
			}
		}

		// Escribir celdas
		f.SetCellValue(sheetName, fmt.Sprintf("A%d", row), nombreEstudiante)
		f.SetCellValue(sheetName, fmt.Sprintf("B%d", row), codigoEstudiante)
		f.SetCellValue(sheetName, fmt.Sprintf("C%d", row), emailEstudiante)
		f.SetCellValue(sheetName, fmt.Sprintf("D%d", row), "Estudiante")
		f.SetCellValue(sheetName, fmt.Sprintf("E%d", row), ultimoAcceso)

		// Aplicar estilo
		for col := 'A'; col <= 'E'; col++ {
			cell := string(col) + fmt.Sprintf("%d", row)
			f.SetCellStyle(sheetName, cell, cell, cellStyle)
		}
	}

	// Convertir a buffer
	var buffer bytes.Buffer
	if err := f.Write(&buffer); err != nil {
		return nil, "", fmt.Errorf("error al escribir archivo: %w", err)
	}

	return &buffer, nombreCurso, nil
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
