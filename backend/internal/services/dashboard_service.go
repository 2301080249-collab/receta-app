package services

import (
	"encoding/json"
	"fmt"
	"math"
	"recetario-backend/internal/models"
	"recetario-backend/internal/repository"
	"sort"
	"time"
)

type DashboardService struct {
	dashboardRepo *repository.DashboardRepository
}

func NewDashboardService(dashboardRepo *repository.DashboardRepository) *DashboardService {
	return &DashboardService{
		dashboardRepo: dashboardRepo,
	}
}

// ObtenerEstadisticasCompletas obtiene todas las estadísticas del dashboard
func (s *DashboardService) ObtenerEstadisticasCompletas(filtros models.DashboardFilters) (*models.DashboardStats, error) {
	stats := &models.DashboardStats{}

	// 1. Métricas principales - ✅ CORREGIDO: Ahora pasan cicloID
	totalEst, err := s.dashboardRepo.GetTotalEstudiantes(filtros.CicloID, filtros.Estado)
	if err != nil {
		return nil, fmt.Errorf("error obteniendo total estudiantes: %w", err)
	}
	stats.TotalEstudiantes = totalEst

	totalDoc, err := s.dashboardRepo.GetTotalDocentes(filtros.CicloID, filtros.Estado)
	if err != nil {
		return nil, fmt.Errorf("error obteniendo total docentes: %w", err)
	}
	stats.TotalDocentes = totalDoc

	totalCur, err := s.dashboardRepo.GetTotalCursos(filtros.CicloID, filtros.Estado)
	if err != nil {
		return nil, fmt.Errorf("error obteniendo total cursos: %w", err)
	}
	stats.TotalCursos = totalCur

	totalMat, err := s.dashboardRepo.GetTotalMatriculas(filtros.CicloID)
	if err != nil {
		return nil, fmt.Errorf("error obteniendo total matrículas: %w", err)
	}
	stats.TotalMatriculas = totalMat

	totalCiclos, err := s.dashboardRepo.GetTotalCiclos()
	if err != nil {
		return nil, fmt.Errorf("error obteniendo total ciclos: %w", err)
	}
	stats.TotalCiclos = totalCiclos

	// Cursos activos
	cursosActivos, _ := s.dashboardRepo.GetTotalCursos(filtros.CicloID, "activo")
	stats.CursosActivos = cursosActivos

	// Estudiantes nuevos (últimos 7 días)
	estudiantesNuevos, _ := s.dashboardRepo.GetEstudiantesNuevos()
	stats.EstudiantesNuevos = estudiantesNuevos

	// Docentes activos - ✅ CORREGIDO: Ahora pasa cicloID
	docentesActivos, _ := s.dashboardRepo.GetTotalDocentes(filtros.CicloID, "activo")
	stats.DocentesActivos = docentesActivos

	// 2. Ciclo actual
	cicloActual, err := s.obtenerCicloActual()
	if err == nil {
		stats.CicloActual = cicloActual
	}

	// 3. Distribuciones (✅ CORREGIDO: Ahora pasan cicloID)
	estudiantesPorCiclo, err := s.obtenerEstudiantesPorCiclo(filtros.CicloID)
	if err == nil {
		stats.EstudiantesPorCiclo = estudiantesPorCiclo
	}

	docentesPorEsp, err := s.obtenerDocentesPorEspecialidad(filtros.CicloID, 10)
	if err == nil {
		stats.DocentesPorEspecialidad = docentesPorEsp
	}

	estudiantesPorSeccion, err := s.obtenerEstudiantesPorSeccion(filtros.CicloID)
	if err == nil {
		stats.EstudiantesPorSeccion = estudiantesPorSeccion
	}

	matriculasPorCurso, err := s.obtenerMatriculasPorCurso(filtros.CicloID, 10)
	if err == nil {
		stats.MatriculasPorCurso = matriculasPorCurso
	}

	// 4. Evolución y timeline
	evolucion, err := s.obtenerEvolucionMatriculas(6)
	if err == nil {
		stats.EvolucionMatriculas = evolucion
	}

	timeline, err := s.obtenerTimelineCiclos()
	if err == nil {
		stats.TimelineCiclos = timeline
	}

	// ✅ NUEVO: Cursos por ciclo
	cursosPorCiclo, err := s.obtenerCursosPorCiclo(filtros.CicloID)
	if err == nil {
		stats.CursosPorCiclo = cursosPorCiclo
	}

	// 5. Calcular ocupación promedio
	if len(stats.MatriculasPorCurso) > 0 {
		totalPorcentaje := 0.0
		for _, curso := range stats.MatriculasPorCurso {
			totalPorcentaje += curso.Porcentaje
		}
		stats.MatriculasOcupacion = totalPorcentaje / float64(len(stats.MatriculasPorCurso))
	}

	// ✅ NUEVO: Docentes con más cursos
	docentesCursos, err := s.obtenerDocentesCursos(filtros.CicloID)
	if err == nil {
		stats.DocentesCursos = docentesCursos
	}

	return stats, nil
}

// ==================== MÉTODOS INTERNOS ====================

func (s *DashboardService) obtenerCicloActual() (*models.CicloActual, error) {
	respBody, err := s.dashboardRepo.GetCicloActivo()
	if err != nil {
		return nil, err
	}

	var ciclos []models.Ciclo
	if err := json.Unmarshal(respBody, &ciclos); err != nil || len(ciclos) == 0 {
		return nil, fmt.Errorf("no hay ciclo activo")
	}

	ciclo := ciclos[0]

	fechaInicio, _ := time.Parse("2006-01-02", ciclo.FechaInicio)
	fechaFin, _ := time.Parse("2006-01-02", ciclo.FechaFin)
	ahora := time.Now()

	diasTranscurridos := int(ahora.Sub(fechaInicio).Hours() / 24)
	semanaActual := (diasTranscurridos / 7) + 1
	if semanaActual > ciclo.DuracionSemanas {
		semanaActual = ciclo.DuracionSemanas
	}

	diasRestantes := int(fechaFin.Sub(ahora).Hours() / 24)
	if diasRestantes < 0 {
		diasRestantes = 0
	}

	porcentajeAvance := (float64(semanaActual) / float64(ciclo.DuracionSemanas)) * 100
	if porcentajeAvance > 100 {
		porcentajeAvance = 100
	}

	return &models.CicloActual{
		ID:               ciclo.ID,
		Nombre:           ciclo.Nombre,
		FechaInicio:      ciclo.FechaInicio,
		FechaFin:         ciclo.FechaFin,
		DuracionSemanas:  ciclo.DuracionSemanas,
		SemanaActual:     semanaActual,
		DiasRestantes:    diasRestantes,
		PorcentajeAvance: math.Round(porcentajeAvance*100) / 100,
	}, nil
}

// ✅ CORREGIDO: Ahora recibe cicloID
func (s *DashboardService) obtenerEstudiantesPorCiclo(cicloID string) ([]models.EstudiantesPorCiclo, error) {
	respBody, err := s.dashboardRepo.GetEstudiantesPorCiclo(cicloID)
	if err != nil {
		return nil, err
	}

	var matriculas []struct {
		EstudianteID string `json:"estudiante_id"`
		Estudiantes  struct {
			CicloActual int `json:"ciclo_actual"`
		} `json:"estudiantes"`
	}
	if err := json.Unmarshal(respBody, &matriculas); err != nil {
		return nil, err
	}

	// Contar por ciclo
	conteo := make(map[int]int)
	total := len(matriculas)

	if total == 0 {
		return []models.EstudiantesPorCiclo{}, nil
	}

	for _, mat := range matriculas {
		conteo[mat.Estudiantes.CicloActual]++
	}

	// Convertir a slice
	resultado := []models.EstudiantesPorCiclo{}
	ciclosRomanos := map[int]string{1: "I", 2: "II", 3: "III", 4: "IV", 5: "V", 6: "VI", 7: "VII", 8: "VIII", 9: "IX", 10: "X"}

	for ciclo := 1; ciclo <= 10; ciclo++ {
		cantidad := conteo[ciclo]
		if cantidad > 0 {
			porcentaje := (float64(cantidad) / float64(total)) * 100
			resultado = append(resultado, models.EstudiantesPorCiclo{
				Ciclo:      ciclo,
				CicloLabel: "Ciclo " + ciclosRomanos[ciclo],
				Cantidad:   cantidad,
				Porcentaje: math.Round(porcentaje*100) / 100,
			})
		}
	}

	return resultado, nil
}

// ✅ CORREGIDO: Ahora recibe cicloID
func (s *DashboardService) obtenerDocentesPorEspecialidad(cicloID string, limit int) ([]models.DocentesPorEspecialidad, error) {
	respBody, err := s.dashboardRepo.GetDocentesPorEspecialidad(cicloID)
	if err != nil {
		return nil, err
	}

	var items []struct {
		DocenteID string `json:"docente_id"`
		Docentes  struct {
			Especialidad string `json:"especialidad"`
		} `json:"docentes"`
	}
	if err := json.Unmarshal(respBody, &items); err != nil {
		return nil, err
	}

	// Contar por especialidad
	conteo := make(map[string]int)
	for _, item := range items {
		if item.Docentes.Especialidad != "" {
			conteo[item.Docentes.Especialidad]++
		}
	}

	// Convertir a slice
	resultado := []models.DocentesPorEspecialidad{}
	for especialidad, cantidad := range conteo {
		resultado = append(resultado, models.DocentesPorEspecialidad{
			Especialidad: especialidad,
			Cantidad:     cantidad,
		})
	}

	// Ordenar por cantidad
	sort.Slice(resultado, func(i, j int) bool {
		return resultado[i].Cantidad > resultado[j].Cantidad
	})

	// Limitar a Top N
	if limit > 0 && len(resultado) > limit {
		resultado = resultado[:limit]
	}

	return resultado, nil
}

func (s *DashboardService) obtenerEstudiantesPorSeccion(cicloID string) ([]models.EstudiantesPorSeccion, error) {
	respBody, err := s.dashboardRepo.GetEstudiantesPorSeccion(cicloID)
	if err != nil {
		return nil, err
	}

	var matriculas []struct {
		EstudianteID string `json:"estudiante_id"`
		Estudiantes  struct {
			CicloActual int    `json:"ciclo_actual"`
			Seccion     string `json:"seccion"`
		} `json:"estudiantes"`
	}
	if err := json.Unmarshal(respBody, &matriculas); err != nil {
		return nil, err
	}

	// ✅ CORREGIDO: Contar estudiantes ÚNICOS por ciclo y sección
	type Key struct {
		Ciclo   int
		Seccion string
	}

	// Usar un map de sets para contar estudiantes únicos
	estudiantesPorKey := make(map[Key]map[string]bool)

	for _, mat := range matriculas {
		seccion := mat.Estudiantes.Seccion
		if seccion == "" {
			seccion = "Sin sección"
		}
		key := Key{Ciclo: mat.Estudiantes.CicloActual, Seccion: seccion}

		// Inicializar el set si no existe
		if estudiantesPorKey[key] == nil {
			estudiantesPorKey[key] = make(map[string]bool)
		}

		// Agregar estudiante al set (evita duplicados)
		estudiantesPorKey[key][mat.EstudianteID] = true
	}

	// Convertir a slice con el conteo de estudiantes únicos
	resultado := []models.EstudiantesPorSeccion{}
	for key, estudiantes := range estudiantesPorKey {
		resultado = append(resultado, models.EstudiantesPorSeccion{
			Ciclo:    key.Ciclo,
			Seccion:  key.Seccion,
			Cantidad: len(estudiantes), // ✅ Contar estudiantes únicos
		})
	}

	return resultado, nil
}

func (s *DashboardService) obtenerMatriculasPorCurso(cicloID string, limit int) ([]models.MatriculasPorCurso, error) {
	respBody, err := s.dashboardRepo.GetMatriculasPorCurso(cicloID)
	if err != nil {
		return nil, err
	}

	var cursos []struct {
		ID         string                   `json:"id"`
		Nombre     string                   `json:"nombre"`
		Seccion    string                   `json:"seccion"`
		Creditos   int                      `json:"creditos"`
		DocenteID  string                   `json:"docente_id"`
		Docentes   map[string]interface{}   `json:"docentes"`
		Matriculas []map[string]interface{} `json:"matriculas"`
	}
	if err := json.Unmarshal(respBody, &cursos); err != nil {
		return nil, err
	}

	// Procesar cada curso
	resultado := []models.MatriculasPorCurso{}
	for _, curso := range cursos {
		matriculados := len(curso.Matriculas)
		capacidad := 50
		porcentaje := (float64(matriculados) / float64(capacidad)) * 100

		docenteNombre := "Sin docente"
		if usuarios, ok := curso.Docentes["usuarios"].(map[string]interface{}); ok {
			if nombre, ok := usuarios["nombre_completo"].(string); ok {
				docenteNombre = nombre
			}
		}

		resultado = append(resultado, models.MatriculasPorCurso{
			CursoID:       curso.ID,
			CursoNombre:   curso.Nombre,
			Matriculados:  matriculados,
			Capacidad:     capacidad,
			Porcentaje:    math.Round(porcentaje*100) / 100,
			DocenteNombre: docenteNombre,
			Seccion:       curso.Seccion,
		})
	}

	// Ordenar por matriculados
	sort.Slice(resultado, func(i, j int) bool {
		return resultado[i].Matriculados > resultado[j].Matriculados
	})

	// Limitar
	if limit > 0 && len(resultado) > limit {
		resultado = resultado[:limit]
	}

	return resultado, nil
}

func (s *DashboardService) obtenerEvolucionMatriculas(limit int) ([]models.EvolucionMatriculas, error) {
	respBody, err := s.dashboardRepo.GetEvolucionMatriculas(limit)
	if err != nil {
		return nil, err
	}

	var ciclos []struct {
		ID          string                   `json:"id"`
		Nombre      string                   `json:"nombre"`
		FechaInicio string                   `json:"fecha_inicio"`
		Matriculas  []map[string]interface{} `json:"matriculas"`
	}
	if err := json.Unmarshal(respBody, &ciclos); err != nil {
		return nil, err
	}

	resultado := []models.EvolucionMatriculas{}
	for i := len(ciclos) - 1; i >= 0; i-- {
		ciclo := ciclos[i]
		resultado = append(resultado, models.EvolucionMatriculas{
			CicloID:     ciclo.ID,
			CicloNombre: ciclo.Nombre,
			Cantidad:    len(ciclo.Matriculas),
			Fecha:       ciclo.FechaInicio,
		})
	}

	return resultado, nil
}

func (s *DashboardService) obtenerTimelineCiclos() ([]models.TimelineCiclo, error) {
	respBody, err := s.dashboardRepo.GetTimelineCiclos()
	if err != nil {
		return nil, err
	}

	var ciclos []models.Ciclo
	if err := json.Unmarshal(respBody, &ciclos); err != nil {
		return nil, err
	}

	ahora := time.Now()
	resultado := []models.TimelineCiclo{}

	for _, ciclo := range ciclos {
		fechaInicio, _ := time.Parse("2006-01-02", ciclo.FechaInicio)
		fechaFin, _ := time.Parse("2006-01-02", ciclo.FechaFin)

		var estado string
		var porcentaje float64
		diasRestantes := 0

		if ahora.Before(fechaInicio) {
			estado = "proximo"
			porcentaje = 0
		} else if ahora.After(fechaFin) {
			estado = "finalizado"
			porcentaje = 100
		} else {
			estado = "en_curso"
			duracionTotal := fechaFin.Sub(fechaInicio).Hours() / 24
			diasTranscurridos := ahora.Sub(fechaInicio).Hours() / 24
			porcentaje = (diasTranscurridos / duracionTotal) * 100
			diasRestantes = int(fechaFin.Sub(ahora).Hours() / 24)
		}

		resultado = append(resultado, models.TimelineCiclo{
			ID:               ciclo.ID,
			Nombre:           ciclo.Nombre,
			FechaInicio:      ciclo.FechaInicio,
			FechaFin:         ciclo.FechaFin,
			Activo:           ciclo.Activo,
			PorcentajeAvance: math.Round(porcentaje*100) / 100,
			Estado:           estado,
			DiasRestantes:    diasRestantes,
		})
	}

	return resultado, nil
}

func (s *DashboardService) obtenerCursosPorCiclo(cicloID string) ([]models.CursosPorCiclo, error) {
	respBody, err := s.dashboardRepo.GetCursosPorCiclo(cicloID)
	if err != nil {
		return nil, err
	}

	var cursos []struct {
		ID         string                   `json:"id"`
		Nombre     string                   `json:"nombre"`
		Nivel      int                      `json:"nivel"`
		Seccion    string                   `json:"seccion"`
		DocenteID  string                   `json:"docente_id"`
		Docentes   map[string]interface{}   `json:"docentes"`
		Matriculas []map[string]interface{} `json:"matriculas"`
	}
	if err := json.Unmarshal(respBody, &cursos); err != nil {
		return nil, err
	}

	// Agrupar por ciclo
	gruposPorCiclo := make(map[int][]models.CursoInfoDashboard)
	totalesPorCiclo := make(map[int]int)

	ciclosRomanos := map[int]string{
		1: "I", 2: "II", 3: "III", 4: "IV", 5: "V",
		6: "VI", 7: "VII", 8: "VIII", 9: "IX", 10: "X",
	}

	for _, curso := range cursos {
		nivel := curso.Nivel
		if nivel < 1 || nivel > 10 {
			continue
		}

		alumnos := len(curso.Matriculas)
		totalesPorCiclo[nivel] += alumnos

		docenteNombre := "Sin docente"
		if usuarios, ok := curso.Docentes["usuarios"].(map[string]interface{}); ok {
			if nombre, ok := usuarios["nombre_completo"].(string); ok {
				docenteNombre = nombre
			}
		}

		gruposPorCiclo[nivel] = append(gruposPorCiclo[nivel], models.CursoInfoDashboard{
			ID:            curso.ID,
			Nombre:        curso.Nombre,
			Alumnos:       alumnos,
			DocenteNombre: docenteNombre,
			Seccion:       curso.Seccion,
		})
	}

	// Convertir a slice ordenado
	resultado := []models.CursosPorCiclo{}
	for ciclo := 1; ciclo <= 10; ciclo++ {
		if cursosCiclo, existe := gruposPorCiclo[ciclo]; existe {
			resultado = append(resultado, models.CursosPorCiclo{
				Ciclo:        ciclo,
				CicloLabel:   "Ciclo " + ciclosRomanos[ciclo],
				TotalCursos:  len(cursosCiclo),
				TotalAlumnos: totalesPorCiclo[ciclo],
				Cursos:       cursosCiclo,
			})
		}
	}

	return resultado, nil
}
func (s *DashboardService) obtenerDocentesCursos(cicloID string) ([]models.DocenteCursos, error) {
	respBody, err := s.dashboardRepo.GetDocentesCursos(cicloID)
	if err != nil {
		return nil, err
	}

	var cursos []struct {
		DocenteID  string                   `json:"docente_id"`
		Docentes   map[string]interface{}   `json:"docentes"`
		Matriculas []map[string]interface{} `json:"matriculas"`
	}
	if err := json.Unmarshal(respBody, &cursos); err != nil {
		return nil, err
	}

	// Agrupar por docente
	type DocenteData struct {
		Nombre           string
		TotalCursos      int
		TotalEstudiantes int
	}
	docentes := make(map[string]*DocenteData)

	for _, curso := range cursos {
		if curso.DocenteID == "" {
			continue
		}

		// Obtener nombre del docente
		nombre := "Sin nombre"
		if usuarios, ok := curso.Docentes["usuarios"].(map[string]interface{}); ok {
			if nombreCompleto, ok := usuarios["nombre_completo"].(string); ok {
				nombre = nombreCompleto
			}
		}

		// Inicializar si no existe
		if _, existe := docentes[curso.DocenteID]; !existe {
			docentes[curso.DocenteID] = &DocenteData{
				Nombre:           nombre,
				TotalCursos:      0,
				TotalEstudiantes: 0,
			}
		}

		// Incrementar contadores
		docentes[curso.DocenteID].TotalCursos++
		docentes[curso.DocenteID].TotalEstudiantes += len(curso.Matriculas)
	}

	// Convertir a slice
	resultado := []models.DocenteCursos{}
	for docenteID, data := range docentes {
		resultado = append(resultado, models.DocenteCursos{
			DocenteID:        docenteID,
			DocenteNombre:    data.Nombre,
			TotalCursos:      data.TotalCursos,
			TotalEstudiantes: data.TotalEstudiantes,
		})
	}

	// Ordenar por total de cursos (descendente)
	sort.Slice(resultado, func(i, j int) bool {
		return resultado[i].TotalCursos > resultado[j].TotalCursos
	})

	return resultado, nil
}
