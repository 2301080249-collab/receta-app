package repository

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"recetario-backend/internal/config"
	"recetario-backend/internal/models"

	"github.com/google/uuid"
)

type EntregaRepository struct {
	client *SupabaseClient
}

func NewEntregaRepository(client *SupabaseClient) *EntregaRepository {
	return &EntregaRepository{client: client}
}

// Crear entrega - CORREGIDO ✅
func (r *EntregaRepository) Create(ctx context.Context, entrega *models.Entrega) (*models.Entrega, error) {
	url := fmt.Sprintf("%s/rest/v1/entregas", config.AppConfig.SupabaseURL)

	// ✅ NO enviar el campo 'id', dejar que Supabase lo genere automáticamente
	insertData := map[string]interface{}{
		"tarea_id":              entrega.TareaID,
		"estudiante_id":         entrega.EstudianteID,
		"titulo":                entrega.Titulo,
		"descripcion":           entrega.Descripcion,
		"fecha_entrega":         entrega.FechaEntrega,
		"entrega_tardia":        entrega.EntregaTardia,
		"dias_retraso":          entrega.DiasRetraso,
		"penalizacion_aplicada": entrega.PenalizacionAplicada,
		"estado":                "entregada",
	}

	log.Printf("🔍 DEBUG - Insertando entrega SIN campo 'id'")

	respBody, err := r.client.DoRequest("POST", url, insertData, r.client.GetAuthHeadersWithPrefer())
	if err != nil {
		return nil, fmt.Errorf("error al crear entrega: %w", err)
	}

	var entregas []models.Entrega
	if err := json.Unmarshal(respBody, &entregas); err != nil {
		return nil, err
	}

	if len(entregas) == 0 {
		return nil, fmt.Errorf("no se pudo crear la entrega")
	}

	log.Printf("✅ Entrega creada exitosamente con ID: %s", entregas[0].ID)

	return &entregas[0], nil
}

// Obtener entrega por ID
func (r *EntregaRepository) GetByID(ctx context.Context, entregaID uuid.UUID) (*models.Entrega, error) {
	url := fmt.Sprintf("%s/rest/v1/entregas?id=eq.%s",
		config.AppConfig.SupabaseURL, entregaID.String())

	respBody, err := r.client.DoRequest("GET", url, nil, r.client.GetAuthHeaders())
	if err != nil {
		return nil, fmt.Errorf("error al obtener entrega: %w", err)
	}

	var entregas []models.Entrega
	if err := json.Unmarshal(respBody, &entregas); err != nil {
		return nil, err
	}

	if len(entregas) == 0 {
		return nil, fmt.Errorf("entrega no encontrada")
	}

	return &entregas[0], nil
}

// Obtener entregas por tarea
func (r *EntregaRepository) GetByTareaID(ctx context.Context, tareaID uuid.UUID) ([]models.Entrega, error) {
	url := fmt.Sprintf("%s/rest/v1/entregas?tarea_id=eq.%s&order=fecha_entrega.desc",
		config.AppConfig.SupabaseURL, tareaID.String())

	respBody, err := r.client.DoRequest("GET", url, nil, r.client.GetAuthHeaders())
	if err != nil {
		return nil, fmt.Errorf("error al obtener entregas: %w", err)
	}

	var entregas []models.Entrega
	if err := json.Unmarshal(respBody, &entregas); err != nil {
		return nil, err
	}

	return entregas, nil
}

// Obtener entrega por tarea y estudiante
func (r *EntregaRepository) GetByTareaAndEstudiante(ctx context.Context, tareaID, estudianteID uuid.UUID) (*models.Entrega, error) {
	url := fmt.Sprintf("%s/rest/v1/entregas?tarea_id=eq.%s&estudiante_id=eq.%s&select=*,estudiante:estudiantes!estudiante_id(usuario_id,codigo_estudiante,seccion,usuario:usuarios!usuario_id(nombre_completo,email,avatar_url))&order=fecha_entrega.desc",
		config.AppConfig.SupabaseURL, tareaID.String(), estudianteID.String())

	respBody, err := r.client.DoRequest("GET", url, nil, r.client.GetAuthHeaders())
	if err != nil {
		return nil, fmt.Errorf("error al obtener entrega: %w", err)
	}

	var entregas []models.Entrega
	if err := json.Unmarshal(respBody, &entregas); err != nil {
		return nil, err
	}

	if len(entregas) == 0 {
		return nil, nil // ✅ Devolver nil si no existe (no es error)
	}

	return &entregas[0], nil
}

// Agregar archivo a entrega
func (r *EntregaRepository) AddArchivo(ctx context.Context, archivo *models.ArchivoEntrega) error {
	url := fmt.Sprintf("%s/rest/v1/archivos_entrega", config.AppConfig.SupabaseURL)

	// ✅ NO enviar 'id' para archivos tampoco
	archivoData := map[string]interface{}{
		"entrega_id":     archivo.EntregaID,
		"nombre_archivo": archivo.NombreArchivo,
		"url_archivo":    archivo.URLArchivo,
		"tipo_archivo":   archivo.TipoArchivo,
		"tamano_mb":      archivo.TamanoMB,
	}

	_, err := r.client.DoRequest("POST", url, archivoData, r.client.GetAuthHeaders())
	if err != nil {
		return fmt.Errorf("error al agregar archivo: %w", err)
	}

	return nil
}

// Obtener archivos de una entrega
func (r *EntregaRepository) GetArchivosByEntregaID(ctx context.Context, entregaID uuid.UUID) ([]models.ArchivoEntrega, error) {
	url := fmt.Sprintf("%s/rest/v1/archivos_entrega?entrega_id=eq.%s",
		config.AppConfig.SupabaseURL, entregaID.String())

	respBody, err := r.client.DoRequest("GET", url, nil, r.client.GetAuthHeaders())
	if err != nil {
		return nil, fmt.Errorf("error al obtener archivos: %w", err)
	}

	var archivos []models.ArchivoEntrega
	if err := json.Unmarshal(respBody, &archivos); err != nil {
		return nil, err
	}

	return archivos, nil
}

// ✅ NUEVO: Obtener archivo por ID
func (r *EntregaRepository) GetArchivoByID(ctx context.Context, archivoID uuid.UUID) (*models.ArchivoEntrega, error) {
	url := fmt.Sprintf("%s/rest/v1/archivos_entrega?id=eq.%s",
		config.AppConfig.SupabaseURL, archivoID.String())

	respBody, err := r.client.DoRequest("GET", url, nil, r.client.GetAuthHeaders())
	if err != nil {
		return nil, fmt.Errorf("error al obtener archivo: %w", err)
	}

	var archivos []models.ArchivoEntrega
	if err := json.Unmarshal(respBody, &archivos); err != nil {
		return nil, err
	}

	if len(archivos) == 0 {
		return nil, fmt.Errorf("archivo no encontrado")
	}

	return &archivos[0], nil
}

// ✅ NUEVO: Eliminar archivo por ID
func (r *EntregaRepository) DeleteArchivo(ctx context.Context, archivoID uuid.UUID) error {
	url := fmt.Sprintf("%s/rest/v1/archivos_entrega?id=eq.%s",
		config.AppConfig.SupabaseURL, archivoID.String())

	_, err := r.client.DoRequest("DELETE", url, nil, r.client.GetAuthHeaders())
	if err != nil {
		return fmt.Errorf("error al eliminar archivo: %w", err)
	}

	log.Printf("✅ Registro de archivo eliminado de la BD: %s", archivoID)
	return nil
}

// Calificar entrega
func (r *EntregaRepository) Calificar(ctx context.Context, entregaID uuid.UUID, calificacion float64, comentario string) error {
	url := fmt.Sprintf("%s/rest/v1/entregas?id=eq.%s",
		config.AppConfig.SupabaseURL, entregaID.String())

	data := map[string]interface{}{
		"calificacion":       calificacion,
		"comentario_docente": comentario,
		"estado":             "evaluada",
	}

	_, err := r.client.DoRequest("PATCH", url, data, r.client.GetAuthHeaders())
	if err != nil {
		return fmt.Errorf("error al calificar entrega: %w", err)
	}

	return nil
}

// Actualizar entrega
func (r *EntregaRepository) Update(ctx context.Context, entregaID uuid.UUID, req *models.CreateEntregaRequest) error {
	url := fmt.Sprintf("%s/rest/v1/entregas?id=eq.%s",
		config.AppConfig.SupabaseURL, entregaID.String())

	data := map[string]interface{}{
		"titulo":      req.Titulo,
		"descripcion": req.Descripcion,
	}

	_, err := r.client.DoRequest("PATCH", url, data, r.client.GetAuthHeaders())
	if err != nil {
		return fmt.Errorf("error al actualizar entrega: %w", err)
	}

	return nil
}

// Eliminar entrega
func (r *EntregaRepository) Delete(ctx context.Context, entregaID uuid.UUID) error {
	url := fmt.Sprintf("%s/rest/v1/entregas?id=eq.%s",
		config.AppConfig.SupabaseURL, entregaID.String())

	_, err := r.client.DoRequest("DELETE", url, nil, r.client.GetAuthHeaders())
	if err != nil {
		return fmt.Errorf("error al eliminar entrega: %w", err)
	}

	return nil
}

// Obtener entregas por tarea CON información del estudiante
func (r *EntregaRepository) GetByTareaIDWithEstudiante(ctx context.Context, tareaID uuid.UUID) ([]models.Entrega, error) {
	// Query con JOIN para traer información del estudiante
	url := fmt.Sprintf("%s/rest/v1/entregas?tarea_id=eq.%s&select=*,estudiante:estudiantes!estudiante_id(usuario_id,codigo_estudiante,seccion,usuario:usuarios!usuario_id(nombre_completo,email,avatar_url))&order=fecha_entrega.desc",
		config.AppConfig.SupabaseURL, tareaID.String())

	respBody, err := r.client.DoRequest("GET", url, nil, r.client.GetAuthHeaders())
	if err != nil {
		return nil, fmt.Errorf("error al obtener entregas: %w", err)
	}

	var entregas []models.Entrega
	if err := json.Unmarshal(respBody, &entregas); err != nil {
		return nil, err
	}

	// Procesar cada entrega para estructurar correctamente los datos del estudiante
	for i := range entregas {
		// También obtener archivos de cada entrega
		archivos, err := r.GetArchivosByEntregaID(ctx, entregas[i].ID)
		if err == nil {
			entregas[i].Archivos = archivos
		}
	}

	return entregas, nil
}

// Obtener estadísticas de entregas por tarea
func (r *EntregaRepository) GetEstadisticasByTareaID(ctx context.Context, tareaID, cursoID uuid.UUID) (map[string]int, error) {
	// Obtener total de estudiantes matriculados
	urlMatriculas := fmt.Sprintf("%s/rest/v1/matriculas?curso_id=eq.%s&estado=eq.activo&select=estudiante_id",
		config.AppConfig.SupabaseURL, cursoID.String())

	respMatriculas, err := r.client.DoRequest("GET", urlMatriculas, nil, r.client.GetAuthHeaders())
	if err != nil {
		return nil, fmt.Errorf("error al obtener matrículas: %w", err)
	}

	var matriculas []struct {
		EstudianteID uuid.UUID `json:"estudiante_id"`
	}
	if err := json.Unmarshal(respMatriculas, &matriculas); err != nil {
		return nil, err
	}
	totalEstudiantes := len(matriculas)

	// Obtener entregas
	entregas, err := r.GetByTareaID(ctx, tareaID)
	if err != nil {
		return nil, err
	}

	// Calcular estadísticas
	totalEntregas := len(entregas)
	sinCalificar := 0
	calificadas := 0

	for _, entrega := range entregas {
		if entrega.Calificacion == nil {
			sinCalificar++
		} else {
			calificadas++
		}
	}

	pendientes := totalEstudiantes - totalEntregas

	stats := map[string]int{
		"total_estudiantes":      totalEstudiantes,
		"total_entregas":         totalEntregas,
		"entregas_sin_calificar": sinCalificar,
		"entregas_calificadas":   calificadas,
		"entregas_pendientes":    pendientes,
	}

	return stats, nil
}

// ✅ NUEVO: Obtener mi entrega (simplificado para usar en tema_service)
func (r *EntregaRepository) GetMiEntrega(ctx context.Context, tareaID, estudianteID uuid.UUID) (*models.Entrega, error) {
	return r.GetByTareaAndEstudiante(ctx, tareaID, estudianteID)
}
