package repository

import (
	"context"
	"encoding/json"
	"fmt"

	"recetario-backend/internal/config"
	"recetario-backend/internal/models"

	"github.com/google/uuid"
)

type PortafolioRepository struct {
	client *SupabaseClient
}

func NewPortafolioRepository(client *SupabaseClient) *PortafolioRepository {
	return &PortafolioRepository{client: client}
}

// ✅ NUEVO: ObtenerOwnerIDPorUserID - Busca estudiante o docente
func (r *PortafolioRepository) ObtenerOwnerIDPorUserID(ctx context.Context, userID uuid.UUID) (uuid.UUID, string, error) {
	// Primero intentar con estudiante
	estudianteID, err := r.ObtenerEstudianteIDPorUserID(ctx, userID)
	if err == nil {
		fmt.Println("✅ [Repo] Usuario es ESTUDIANTE, ID:", estudianteID)
		return estudianteID, "estudiante", nil
	}

	// Si no es estudiante, intentar con docente
	docenteID, err := r.ObtenerDocenteIDPorUserID(ctx, userID)
	if err == nil {
		fmt.Println("✅ [Repo] Usuario es DOCENTE, ID:", docenteID)
		return docenteID, "docente", nil
	}

	return uuid.Nil, "", fmt.Errorf("usuario no es ni estudiante ni docente")
}

// ObtenerEstudianteIDPorUserID obtiene el estudiante_id desde user_id
func (r *PortafolioRepository) ObtenerEstudianteIDPorUserID(ctx context.Context, userID uuid.UUID) (uuid.UUID, error) {
	url := fmt.Sprintf("%s/rest/v1/estudiantes?usuario_id=eq.%s&select=id", config.AppConfig.SupabaseURL, userID.String())

	resp, err := r.client.DoRequest("GET", url, nil, r.client.GetAuthHeaders())
	if err != nil {
		return uuid.Nil, err
	}

	var estudiantes []struct {
		ID uuid.UUID `json:"id"`
	}

	if err := json.Unmarshal(resp, &estudiantes); err != nil {
		return uuid.Nil, err
	}

	if len(estudiantes) == 0 {
		return uuid.Nil, fmt.Errorf("usuario no es estudiante")
	}

	return estudiantes[0].ID, nil
}

// ✅ NUEVO: ObtenerDocenteIDPorUserID obtiene el docente_id desde user_id
func (r *PortafolioRepository) ObtenerDocenteIDPorUserID(ctx context.Context, userID uuid.UUID) (uuid.UUID, error) {
	url := fmt.Sprintf("%s/rest/v1/docentes?usuario_id=eq.%s&select=id", config.AppConfig.SupabaseURL, userID.String())

	resp, err := r.client.DoRequest("GET", url, nil, r.client.GetAuthHeaders())
	if err != nil {
		return uuid.Nil, err
	}

	var docentes []struct {
		ID uuid.UUID `json:"id"`
	}

	if err := json.Unmarshal(resp, &docentes); err != nil {
		return uuid.Nil, err
	}

	if len(docentes) == 0 {
		return uuid.Nil, fmt.Errorf("usuario no es docente")
	}

	return docentes[0].ID, nil
}

// Crear receta (funciona para estudiantes y docentes)
func (r *PortafolioRepository) Crear(ctx context.Context, ownerID uuid.UUID, req models.CrearPortafolioRequest) (*models.Portafolio, error) {
	fmt.Println("🔍 [Repo] Iniciando creación de portafolio...")
	fmt.Printf("🔍 [Repo] Owner ID: %s\n", ownerID.String())

	// Parsear categoria_id
	categoriaID, err := uuid.Parse(req.CategoriaID)
	if err != nil {
		fmt.Printf("❌ [Repo] Error parseando categoria_id: %v\n", err)
		return nil, fmt.Errorf("categoria_id inválido: %w", err)
	}

	// ✅ Crear map (estudiante_id se usa para ambos roles por compatibilidad con BD)
	portafolio := map[string]interface{}{
		"id":             uuid.New().String(),
		"estudiante_id":  ownerID.String(), // ✅ Funciona para estudiantes y docentes
		"titulo":         req.Titulo,
		"ingredientes":   req.Ingredientes,
		"preparacion":    req.Preparacion,
		"fotos":          req.Fotos,
		"categoria_id":   categoriaID.String(),
		"tipo_receta":    req.TipoReceta,
		"visibilidad":    req.Visibilidad,
		"likes":          0,
		"vistas":         0,
		"es_destacada":   false,
		"es_certificada": false,
	}

	// Campos opcionales
	if req.Descripcion != nil && *req.Descripcion != "" {
		portafolio["descripcion"] = *req.Descripcion
	}
	if req.VideoURL != nil && *req.VideoURL != "" {
		portafolio["video_url"] = *req.VideoURL
	}
	if req.FuenteAPIID != nil && *req.FuenteAPIID != "" {
		portafolio["fuente_api_id"] = *req.FuenteAPIID
	}

	// ✅ DEBUG: Ver qué se está enviando
	jsonData, _ := json.MarshalIndent(portafolio, "", "  ")
	fmt.Printf("📤 [Repo] JSON a enviar:\n%s\n", string(jsonData))

	// Hacer el POST
	url := fmt.Sprintf("%s/rest/v1/portafolio", config.AppConfig.SupabaseURL)
	body, err := r.client.DoRequest("POST", url, portafolio, r.client.GetAuthHeadersWithPrefer())
	if err != nil {
		fmt.Printf("❌ [Repo] Error en POST a Supabase: %v\n", err)
		return nil, fmt.Errorf("error creando portafolio en Supabase: %w", err)
	}

	// Parsear respuesta
	var result []models.Portafolio
	if err := json.Unmarshal(body, &result); err != nil {
		fmt.Printf("❌ [Repo] Error parseando resultado: %v\n", err)
		fmt.Printf("📥 [Repo] Body recibido: %s\n", string(body))
		return nil, fmt.Errorf("error parseando respuesta: %w", err)
	}

	if len(result) == 0 {
		fmt.Println("❌ [Repo] No se retornó ningún portafolio")
		return nil, fmt.Errorf("no se retornó ningún registro después del insert")
	}

	fmt.Printf("✅ [Repo] Portafolio creado exitosamente: %s\n", result[0].ID)
	return &result[0], nil
}

// ObtenerPorOwner obtiene recetas del owner (estudiante o docente)
func (r *PortafolioRepository) ObtenerPorOwner(ctx context.Context, ownerID uuid.UUID) ([]models.Portafolio, error) {
	url := fmt.Sprintf("%s/rest/v1/portafolio?estudiante_id=eq.%s&order=created_at.desc",
		config.AppConfig.SupabaseURL, ownerID.String())

	resp, err := r.client.DoRequest("GET", url, nil, r.client.GetAuthHeaders())
	if err != nil {
		return nil, err
	}

	var portafolios []models.Portafolio
	if err := json.Unmarshal(resp, &portafolios); err != nil {
		return nil, err
	}

	return portafolios, nil
}

// ✅ MANTENER: Por compatibilidad (ahora usa ObtenerPorOwner internamente)
func (r *PortafolioRepository) ObtenerPorEstudiante(ctx context.Context, estudianteID uuid.UUID) ([]models.Portafolio, error) {
	return r.ObtenerPorOwner(ctx, estudianteID)
}

// ✅ MODIFICADO: ObtenerPublicas - Incluye recetas de estudiantes Y docentes
func (r *PortafolioRepository) ObtenerPublicas(ctx context.Context) ([]models.PortafolioConEstudiante, error) {
	// Query 1: Obtener todas las recetas públicas
	urlPortafolios := fmt.Sprintf("%s/rest/v1/portafolio?visibilidad=eq.publica&order=created_at.desc",
		config.AppConfig.SupabaseURL)

	respPortafolios, err := r.client.DoRequest("GET", urlPortafolios, nil, r.client.GetAuthHeaders())
	if err != nil {
		return nil, err
	}

	var portafolios []models.Portafolio
	if err := json.Unmarshal(respPortafolios, &portafolios); err != nil {
		return nil, err
	}

	// Query 2: Obtener info de estudiantes
	urlEstudiantes := fmt.Sprintf("%s/rest/v1/estudiantes?select=id,codigo_estudiante,usuarios(nombre_completo,avatar_url)",
		config.AppConfig.SupabaseURL)
	respEstudiantes, err := r.client.DoRequest("GET", urlEstudiantes, nil, r.client.GetAuthHeaders())
	if err != nil {
		return nil, err
	}

	var estudiantes []struct {
		ID               string `json:"id"`
		CodigoEstudiante string `json:"codigo_estudiante"`
		Usuarios         *struct {
			NombreCompleto string `json:"nombre_completo"`
			AvatarURL      string `json:"avatar_url"`
		} `json:"usuarios"`
	}
	json.Unmarshal(respEstudiantes, &estudiantes)

	// Query 3: Obtener info de docentes
	urlDocentes := fmt.Sprintf("%s/rest/v1/docentes?select=id,codigo_docente,usuarios(nombre_completo,avatar_url)",
		config.AppConfig.SupabaseURL)
	respDocentes, err := r.client.DoRequest("GET", urlDocentes, nil, r.client.GetAuthHeaders())
	if err != nil {
		return nil, err
	}

	var docentes []struct {
		ID            string `json:"id"`
		CodigoDocente string `json:"codigo_docente"`
		Usuarios      *struct {
			NombreCompleto string `json:"nombre_completo"`
			AvatarURL      string `json:"avatar_url"`
		} `json:"usuarios"`
	}
	json.Unmarshal(respDocentes, &docentes)

	// Combinar datos: buscar info del owner en estudiantes o docentes
	result := make([]models.PortafolioConEstudiante, 0)
	for _, p := range portafolios {
		item := models.PortafolioConEstudiante{
			Portafolio: p,
		}

		ownerID := p.EstudianteID.String()

		// Buscar primero en estudiantes
		found := false
		for _, est := range estudiantes {
			if est.ID == ownerID && est.Usuarios != nil {
				item.NombreEstudiante = est.Usuarios.NombreCompleto
				item.CodigoEstudiante = est.CodigoEstudiante
				item.AvatarEstudiante = &est.Usuarios.AvatarURL
				found = true
				break
			}
		}

		// Si no se encontró en estudiantes, buscar en docentes
		if !found {
			for _, doc := range docentes {
				if doc.ID == ownerID && doc.Usuarios != nil {
					item.NombreEstudiante = doc.Usuarios.NombreCompleto
					item.CodigoEstudiante = doc.CodigoDocente
					item.AvatarEstudiante = &doc.Usuarios.AvatarURL
					break
				}
			}
		}

		result = append(result, item)
	}

	return result, nil
}

// ObtenerPorID obtiene una receta por ID (funciona para estudiantes y docentes)
func (r *PortafolioRepository) ObtenerPorID(ctx context.Context, id uuid.UUID) (*models.PortafolioConEstudiante, error) {
	// Query 1: Obtener el portafolio
	urlPortafolio := fmt.Sprintf("%s/rest/v1/portafolio?id=eq.%s",
		config.AppConfig.SupabaseURL, id.String())

	respPortafolio, err := r.client.DoRequest("GET", urlPortafolio, nil, r.client.GetAuthHeaders())
	if err != nil {
		return nil, err
	}

	var portafolios []models.Portafolio
	if err := json.Unmarshal(respPortafolio, &portafolios); err != nil {
		return nil, err
	}

	if len(portafolios) == 0 {
		return nil, fmt.Errorf("receta no encontrada")
	}

	p := portafolios[0]
	ownerID := p.EstudianteID.String()

	// Query 2: Obtener info del owner (estudiante o docente)
	result := &models.PortafolioConEstudiante{
		Portafolio: p,
	}

	// Buscar primero en estudiantes
	urlEstudiante := fmt.Sprintf("%s/rest/v1/estudiantes?id=eq.%s&select=id,codigo_estudiante,usuarios(nombre_completo,avatar_url)",
		config.AppConfig.SupabaseURL, ownerID)
	respEstudiante, err := r.client.DoRequest("GET", urlEstudiante, nil, r.client.GetAuthHeaders())

	if err == nil {
		var estudiantes []struct {
			ID               string `json:"id"`
			CodigoEstudiante string `json:"codigo_estudiante"`
			Usuarios         *struct {
				NombreCompleto string `json:"nombre_completo"`
				AvatarURL      string `json:"avatar_url"`
			} `json:"usuarios"`
		}

		if json.Unmarshal(respEstudiante, &estudiantes) == nil && len(estudiantes) > 0 && estudiantes[0].Usuarios != nil {
			result.NombreEstudiante = estudiantes[0].Usuarios.NombreCompleto
			result.CodigoEstudiante = estudiantes[0].CodigoEstudiante
			result.AvatarEstudiante = &estudiantes[0].Usuarios.AvatarURL
			return result, nil
		}
	}

	// Si no se encontró en estudiantes, buscar en docentes
	urlDocente := fmt.Sprintf("%s/rest/v1/docentes?id=eq.%s&select=id,codigo_docente,usuarios(nombre_completo,avatar_url)",
		config.AppConfig.SupabaseURL, ownerID)
	respDocente, err := r.client.DoRequest("GET", urlDocente, nil, r.client.GetAuthHeaders())

	if err == nil {
		var docentes []struct {
			ID            string `json:"id"`
			CodigoDocente string `json:"codigo_docente"`
			Usuarios      *struct {
				NombreCompleto string `json:"nombre_completo"`
				AvatarURL      string `json:"avatar_url"`
			} `json:"usuarios"`
		}

		if json.Unmarshal(respDocente, &docentes) == nil && len(docentes) > 0 && docentes[0].Usuarios != nil {
			result.NombreEstudiante = docentes[0].Usuarios.NombreCompleto
			result.CodigoEstudiante = docentes[0].CodigoDocente
			result.AvatarEstudiante = &docentes[0].Usuarios.AvatarURL
			return result, nil
		}
	}

	// Si no se encuentra ni en estudiantes ni en docentes, retornar sin info del owner
	return result, nil
}

// Eliminar receta (funciona para estudiantes y docentes)
func (r *PortafolioRepository) Eliminar(ctx context.Context, id uuid.UUID, ownerID uuid.UUID) error {
	url := fmt.Sprintf("%s/rest/v1/portafolio?id=eq.%s&estudiante_id=eq.%s",
		config.AppConfig.SupabaseURL, id.String(), ownerID.String())

	_, err := r.client.DoRequest("DELETE", url, nil, r.client.GetAuthHeaders())
	return err
}

// YaDioLike verifica si dio like
func (r *PortafolioRepository) YaDioLike(ctx context.Context, portafolioID, usuarioID uuid.UUID) (bool, error) {
	url := fmt.Sprintf("%s/rest/v1/likes_portafolio?portafolio_id=eq.%s&usuario_id=eq.%s",
		config.AppConfig.SupabaseURL, portafolioID.String(), usuarioID.String())

	resp, err := r.client.DoRequest("GET", url, nil, r.client.GetAuthHeaders())
	if err != nil {
		return false, err
	}

	var likes []map[string]interface{}
	json.Unmarshal(resp, &likes)

	return len(likes) > 0, nil
}

// DarLike da like a una receta
func (r *PortafolioRepository) DarLike(ctx context.Context, portafolioID, usuarioID uuid.UUID) error {
	like := map[string]interface{}{
		"id":            uuid.New().String(),
		"portafolio_id": portafolioID.String(),
		"usuario_id":    usuarioID.String(),
	}

	url := fmt.Sprintf("%s/rest/v1/likes_portafolio", config.AppConfig.SupabaseURL)
	_, err := r.client.DoRequest("POST", url, like, r.client.GetAuthHeaders())
	return err
}

// QuitarLike quita like
func (r *PortafolioRepository) QuitarLike(ctx context.Context, portafolioID, usuarioID uuid.UUID) error {
	url := fmt.Sprintf("%s/rest/v1/likes_portafolio?portafolio_id=eq.%s&usuario_id=eq.%s",
		config.AppConfig.SupabaseURL, portafolioID.String(), usuarioID.String())

	_, err := r.client.DoRequest("DELETE", url, nil, r.client.GetAuthHeaders())
	return err
}

// CrearComentario crea un comentario
func (r *PortafolioRepository) CrearComentario(ctx context.Context, portafolioID, usuarioID uuid.UUID, texto string) (*models.ComentarioPortafolio, error) {
	comentario := map[string]interface{}{
		"id":            uuid.New().String(),
		"portafolio_id": portafolioID.String(),
		"usuario_id":    usuarioID.String(),
		"comentario":    texto,
	}

	url := fmt.Sprintf("%s/rest/v1/comentarios_portafolio", config.AppConfig.SupabaseURL)
	resp, err := r.client.DoRequest("POST", url, comentario, r.client.GetAuthHeadersWithPrefer())
	if err != nil {
		return nil, err
	}

	var result []models.ComentarioPortafolio
	json.Unmarshal(resp, &result)
	return &result[0], nil
}

// ObtenerComentarios obtiene comentarios
func (r *PortafolioRepository) ObtenerComentarios(ctx context.Context, portafolioID uuid.UUID) ([]models.ComentarioConUsuario, error) {
	url := fmt.Sprintf("%s/rest/v1/comentarios_portafolio?portafolio_id=eq.%s&select=*,usuarios(nombre_completo,avatar_url)&order=created_at.desc",
		config.AppConfig.SupabaseURL, portafolioID.String())

	resp, err := r.client.DoRequest("GET", url, nil, r.client.GetAuthHeaders())
	if err != nil {
		return nil, err
	}

	var result []models.ComentarioConUsuario
	json.Unmarshal(resp, &result)
	return result, nil
}

// ✨ AGREGAR ESTE MÉTODO en portafolio_repository.go

// Actualizar receta
func (r *PortafolioRepository) Actualizar(ctx context.Context, id uuid.UUID, ownerID uuid.UUID, req models.ActualizarPortafolioRequest) (*models.Portafolio, error) {
	// Construir el mapa de actualización solo con campos no nulos
	updateData := make(map[string]interface{})

	if req.Titulo != nil {
		updateData["titulo"] = *req.Titulo
	}
	if req.Descripcion != nil {
		updateData["descripcion"] = *req.Descripcion
	}
	if req.Ingredientes != nil {
		updateData["ingredientes"] = *req.Ingredientes
	}
	if req.Preparacion != nil {
		updateData["preparacion"] = *req.Preparacion
	}
	if req.Fotos != nil && len(req.Fotos) > 0 {
		updateData["fotos"] = req.Fotos
	}
	if req.VideoURL != nil {
		updateData["video_url"] = *req.VideoURL
	}
	if req.CategoriaID != nil {
		categoriaID, err := uuid.Parse(*req.CategoriaID)
		if err != nil {
			return nil, fmt.Errorf("categoria_id inválido: %w", err)
		}
		updateData["categoria_id"] = categoriaID.String()
	}
	if req.Visibilidad != nil {
		updateData["visibilidad"] = *req.Visibilidad
	}

	// Siempre actualizar updated_at
	updateData["updated_at"] = "now()"

	// Hacer el PATCH a Supabase
	url := fmt.Sprintf("%s/rest/v1/portafolio?id=eq.%s&estudiante_id=eq.%s",
		config.AppConfig.SupabaseURL, id.String(), ownerID.String())

	body, err := r.client.DoRequest("PATCH", url, updateData, r.client.GetAuthHeadersWithPrefer())
	if err != nil {
		return nil, fmt.Errorf("error actualizando portafolio: %w", err)
	}

	// Parsear respuesta
	var result []models.Portafolio
	if err := json.Unmarshal(body, &result); err != nil {
		return nil, fmt.Errorf("error parseando respuesta: %w", err)
	}

	if len(result) == 0 {
		return nil, fmt.Errorf("no se pudo actualizar la receta (verifique permisos)")
	}

	fmt.Printf("✅ [Repo] Receta actualizada: %s\n", id)
	return &result[0], nil
}
