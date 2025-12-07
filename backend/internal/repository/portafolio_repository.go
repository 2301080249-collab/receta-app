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

// ✅ CORREGIDO: Retorna userID directamente, NO busca en tablas
func (r *PortafolioRepository) ObtenerOwnerIDPorUserID(ctx context.Context, userID uuid.UUID) (uuid.UUID, string, error) {
	fmt.Printf("🔍 [ObtenerOwnerIDPorUserID] userID recibido: %s\n", userID)

	// Verificar si es estudiante
	estudianteURL := fmt.Sprintf("%s/rest/v1/estudiantes?usuario_id=eq.%s&select=id", config.AppConfig.SupabaseURL, userID.String())
	fmt.Printf("🔍 [ObtenerOwnerIDPorUserID] Verificando estudiante en: %s\n", estudianteURL)

	respEstudiante, err := r.client.DoRequest("GET", estudianteURL, nil, r.client.GetAuthHeaders())

	if err == nil {
		var estudiantes []struct {
			ID uuid.UUID `json:"id"`
		}
		if json.Unmarshal(respEstudiante, &estudiantes) == nil && len(estudiantes) > 0 {
			fmt.Printf("✅ [ObtenerOwnerIDPorUserID] Usuario ES ESTUDIANTE, retornando userID: %s\n", userID)
			return userID, "estudiante", nil // ✅ RETORNA userID, NO estudiantes[0].ID
		}
	}

	// Verificar si es docente
	docenteURL := fmt.Sprintf("%s/rest/v1/docentes?usuario_id=eq.%s&select=id", config.AppConfig.SupabaseURL, userID.String())
	fmt.Printf("🔍 [ObtenerOwnerIDPorUserID] Verificando docente en: %s\n", docenteURL)

	respDocente, err := r.client.DoRequest("GET", docenteURL, nil, r.client.GetAuthHeaders())

	if err == nil {
		var docentes []struct {
			ID uuid.UUID `json:"id"`
		}
		if json.Unmarshal(respDocente, &docentes) == nil && len(docentes) > 0 {
			fmt.Printf("✅ [ObtenerOwnerIDPorUserID] Usuario ES DOCENTE, retornando userID: %s\n", userID)
			return userID, "docente", nil // ✅ RETORNA userID, NO docentes[0].ID
		}
	}

	fmt.Printf("❌ [ObtenerOwnerIDPorUserID] Usuario no es ni estudiante ni docente\n")
	return uuid.Nil, "", fmt.Errorf("usuario no es ni estudiante ni docente")
}

// Crear receta (funciona para estudiantes y docentes)
func (r *PortafolioRepository) Crear(ctx context.Context, ownerID uuid.UUID, req models.CrearPortafolioRequest) (*models.Portafolio, error) {
	fmt.Println("🔍 [Repo.Crear] Iniciando creación de portafolio...")
	fmt.Printf("🔍 [Repo.Crear] ownerID recibido: %s\n", ownerID.String())

	// Parsear categoria_id
	categoriaID, err := uuid.Parse(req.CategoriaID)
	if err != nil {
		fmt.Printf("❌ [Repo.Crear] Error parseando categoria_id: %v\n", err)
		return nil, fmt.Errorf("categoria_id inválido: %w", err)
	}

	// ✅ CAMBIO: usuario_id en vez de estudiante_id
	portafolio := map[string]interface{}{
		"id":             uuid.New().String(),
		"usuario_id":     ownerID.String(), // ✅ Usa ownerID que es el usuario_id
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
	fmt.Printf("📤 [Repo.Crear] JSON a enviar:\n%s\n", string(jsonData))

	// Hacer el POST
	url := fmt.Sprintf("%s/rest/v1/portafolio", config.AppConfig.SupabaseURL)
	body, err := r.client.DoRequest("POST", url, portafolio, r.client.GetAuthHeadersWithPrefer())
	if err != nil {
		fmt.Printf("❌ [Repo.Crear] Error en POST a Supabase: %v\n", err)
		return nil, fmt.Errorf("error creando portafolio en Supabase: %w", err)
	}

	// Parsear respuesta
	var result []models.Portafolio
	if err := json.Unmarshal(body, &result); err != nil {
		fmt.Printf("❌ [Repo.Crear] Error parseando resultado: %v\n", err)
		fmt.Printf("📥 [Repo.Crear] Body recibido: %s\n", string(body))
		return nil, fmt.Errorf("error parseando respuesta: %w", err)
	}

	if len(result) == 0 {
		fmt.Println("❌ [Repo.Crear] No se retornó ningún portafolio")
		return nil, fmt.Errorf("no se retornó ningún registro después del insert")
	}

	fmt.Printf("✅ [Repo.Crear] Portafolio creado exitosamente: %s\n", result[0].ID)
	return &result[0], nil
}

// ObtenerPorOwner obtiene recetas del owner (estudiante o docente)
func (r *PortafolioRepository) ObtenerPorOwner(ctx context.Context, ownerID uuid.UUID) ([]models.Portafolio, error) {
	fmt.Printf("🔍 [ObtenerPorOwner] ownerID recibido: %s\n", ownerID)

	url := fmt.Sprintf("%s/rest/v1/portafolio?usuario_id=eq.%s&order=created_at.desc",
		config.AppConfig.SupabaseURL, ownerID.String())

	fmt.Printf("🔍 [ObtenerPorOwner] URL: %s\n", url)

	resp, err := r.client.DoRequest("GET", url, nil, r.client.GetAuthHeaders())
	if err != nil {
		fmt.Printf("❌ [ObtenerPorOwner] Error en request: %v\n", err)
		return nil, err
	}

	fmt.Printf("📥 [ObtenerPorOwner] Response length: %d\n", len(resp))

	var portafolios []models.Portafolio
	if err := json.Unmarshal(resp, &portafolios); err != nil {
		fmt.Printf("❌ [ObtenerPorOwner] Error parseando JSON: %v\n", err)
		return nil, err
	}

	fmt.Printf("✅ [ObtenerPorOwner] %d portafolios encontrados\n", len(portafolios))
	return portafolios, nil
}

// ✅ MANTENER: Por compatibilidad
func (r *PortafolioRepository) ObtenerPorEstudiante(ctx context.Context, estudianteID uuid.UUID) ([]models.Portafolio, error) {
	return r.ObtenerPorOwner(ctx, estudianteID)
}

// ✅ MODIFICADO: ObtenerPublicas - Incluye recetas de estudiantes Y docentes
func (r *PortafolioRepository) ObtenerPublicas(ctx context.Context) ([]models.PortafolioConEstudiante, error) {
	// ✅ USAR JOIN DIRECTO CON USUARIOS
	urlPortafolios := fmt.Sprintf("%s/rest/v1/portafolio?visibilidad=eq.publica&select=*,usuarios!portafolio_usuario_id_fkey(nombre_completo,avatar_url,codigo)&order=created_at.desc",
		config.AppConfig.SupabaseURL)

	fmt.Printf("🔍 [ObtenerPublicas] URL con JOIN: %s\n", urlPortafolios)

	respPortafolios, err := r.client.DoRequest("GET", urlPortafolios, nil, r.client.GetAuthHeaders())
	if err != nil {
		return nil, err
	}

	var portafoliosConUsuario []struct {
		models.Portafolio
		Usuarios *struct {
			NombreCompleto string `json:"nombre_completo"`
			AvatarURL      string `json:"avatar_url"`
			Codigo         string `json:"codigo"`
		} `json:"usuarios"`
	}

	if err := json.Unmarshal(respPortafolios, &portafoliosConUsuario); err != nil {
		return nil, err
	}

	result := make([]models.PortafolioConEstudiante, 0, len(portafoliosConUsuario))
	for _, p := range portafoliosConUsuario {
		item := models.PortafolioConEstudiante{
			Portafolio: p.Portafolio,
		}

		if p.Usuarios != nil {
			item.NombreEstudiante = p.Usuarios.NombreCompleto
			item.CodigoEstudiante = p.Usuarios.Codigo
			item.AvatarEstudiante = &p.Usuarios.AvatarURL
		}

		result = append(result, item)
	}

	fmt.Printf("✅ [ObtenerPublicas] %d recetas públicas con datos de usuario\n", len(result))
	return result, nil
}

// ✅ CORREGIDO COMPLETO: ObtenerPorID con JOIN directo
func (r *PortafolioRepository) ObtenerPorID(ctx context.Context, id uuid.UUID) (*models.PortafolioConEstudiante, error) {
	// ✅ USAR JOIN DIRECTO EN LA QUERY
	urlPortafolio := fmt.Sprintf("%s/rest/v1/portafolio?id=eq.%s&select=*,usuarios!portafolio_usuario_id_fkey(nombre_completo,avatar_url,codigo)",
		config.AppConfig.SupabaseURL, id.String())

	fmt.Printf("🔍 [ObtenerPorID] URL con JOIN: %s\n", urlPortafolio)

	respPortafolio, err := r.client.DoRequest("GET", urlPortafolio, nil, r.client.GetAuthHeaders())
	if err != nil {
		fmt.Printf("❌ [ObtenerPorID] Error en request: %v\n", err)
		return nil, err
	}

	fmt.Printf("📥 [ObtenerPorID] Response: %s\n", string(respPortafolio))

	var portafolios []struct {
		models.Portafolio
		Usuarios *struct {
			NombreCompleto string `json:"nombre_completo"`
			AvatarURL      string `json:"avatar_url"`
			Codigo         string `json:"codigo"`
		} `json:"usuarios"`
	}

	if err := json.Unmarshal(respPortafolio, &portafolios); err != nil {
		fmt.Printf("❌ [ObtenerPorID] Error parseando: %v\n", err)
		return nil, err
	}

	if len(portafolios) == 0 {
		return nil, fmt.Errorf("receta no encontrada")
	}

	p := portafolios[0]

	result := &models.PortafolioConEstudiante{
		Portafolio: p.Portafolio,
	}

	// ✅ USAR DATOS DEL JOIN DIRECTAMENTE
	if p.Usuarios != nil {
		result.NombreEstudiante = p.Usuarios.NombreCompleto
		result.CodigoEstudiante = p.Usuarios.Codigo
		result.AvatarEstudiante = &p.Usuarios.AvatarURL
		fmt.Printf("✅ [ObtenerPorID] Datos de usuario desde JOIN: %s (%s)\n", result.NombreEstudiante, result.CodigoEstudiante)
	} else {
		fmt.Printf("⚠️ [ObtenerPorID] No se encontraron datos de usuario en el JOIN\n")
	}

	return result, nil
}

// Eliminar receta
func (r *PortafolioRepository) Eliminar(ctx context.Context, id uuid.UUID, ownerID uuid.UUID) error {
	url := fmt.Sprintf("%s/rest/v1/portafolio?id=eq.%s&usuario_id=eq.%s",
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

// Actualizar receta
func (r *PortafolioRepository) Actualizar(ctx context.Context, id uuid.UUID, ownerID uuid.UUID, req models.ActualizarPortafolioRequest) (*models.Portafolio, error) {
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

	updateData["updated_at"] = "now()"

	url := fmt.Sprintf("%s/rest/v1/portafolio?id=eq.%s&usuario_id=eq.%s",
		config.AppConfig.SupabaseURL, id.String(), ownerID.String())

	body, err := r.client.DoRequest("PATCH", url, updateData, r.client.GetAuthHeadersWithPrefer())
	if err != nil {
		return nil, fmt.Errorf("error actualizando portafolio: %w", err)
	}

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
