package services

import (
	"bytes"
	"fmt"
	"io"
	"mime/multipart"
	"net/http"
	"net/url"
	"path/filepath"
	"strings"
	"time"
)

type StorageService struct {
	bucket     string
	storageURL string
	apiKey     string
}

func NewStorageService(url, apiKey, bucket string) *StorageService {
	// Validar que los parámetros no estén vacíos
	if url == "" {
		panic("SUPABASE_STORAGE_URL no puede estar vacío")
	}
	if apiKey == "" {
		panic("SUPABASE_SERVICE_KEY no puede estar vacío")
	}
	if bucket == "" {
		panic("bucket no puede estar vacío")
	}

	return &StorageService{
		bucket:     bucket,
		storageURL: url,
		apiKey:     apiKey,
	}
}

func (s *StorageService) UploadFile(folder string, file multipart.File, fileHeader *multipart.FileHeader) (string, float64, error) {
	// Leer el archivo en memoria
	fileBytes, err := io.ReadAll(file)
	if err != nil {
		return "", 0, fmt.Errorf("error leyendo archivo: %w", err)
	}

	// Generar nombre único con timestamp
	timestamp := time.Now().Unix()
	ext := filepath.Ext(fileHeader.Filename)
	filename := fmt.Sprintf("%d%s", timestamp, ext)
	path := fmt.Sprintf("%s/%s", folder, filename)

	// ✅ Detectar Content-Type basado en la extensión
	contentType := getContentType(ext)

	// ✅ Subir archivo usando HTTP directo con Content-Type
	uploadURL := fmt.Sprintf("%s/object/%s/%s", s.storageURL, s.bucket, path)

	req, err := http.NewRequest("POST", uploadURL, bytes.NewReader(fileBytes))
	if err != nil {
		return "", 0, fmt.Errorf("error creando request: %w", err)
	}

	// Headers necesarios
	req.Header.Set("Authorization", "Bearer "+s.apiKey)
	req.Header.Set("Content-Type", contentType) // ✅ IMPORTANTE
	req.Header.Set("x-upsert", "true")

	// Ejecutar request
	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return "", 0, fmt.Errorf("error subiendo archivo: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 && resp.StatusCode != 201 {
		bodyBytes, _ := io.ReadAll(resp.Body)
		return "", 0, fmt.Errorf("error en upload: %s - %s", resp.Status, string(bodyBytes))
	}

	// Generar URL pública
	publicURL := fmt.Sprintf("%s/object/public/%s/%s", s.storageURL, s.bucket, path)

	// Calcular tamaño en MB
	sizeInMB := float64(len(fileBytes)) / (1024 * 1024)

	fmt.Printf("✅ Archivo subido: %s (Content-Type: %s)\n", publicURL, contentType)

	return publicURL, sizeInMB, nil
}

// ✅ MEJORADO: DeleteFile elimina un archivo del Storage
// Acepta tanto URL completa como path relativo
func (s *StorageService) DeleteFile(fileURL string) error {
	// Extraer path del archivo desde la URL
	path, err := s.extractPathFromURL(fileURL)
	if err != nil {
		return fmt.Errorf("error al extraer path: %w", err)
	}

	// URL para eliminar
	deleteURL := fmt.Sprintf("%s/object/%s/%s", s.storageURL, s.bucket, path)

	req, err := http.NewRequest("DELETE", deleteURL, nil)
	if err != nil {
		return fmt.Errorf("error creando request: %w", err)
	}

	req.Header.Set("Authorization", "Bearer "+s.apiKey)

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return fmt.Errorf("error eliminando archivo: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 && resp.StatusCode != 204 {
		bodyBytes, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("error eliminando archivo: %s - %s", resp.Status, string(bodyBytes))
	}

	fmt.Printf("✅ Archivo eliminado del Storage: %s\n", path)
	return nil
}

// ✅ NUEVO: extractPathFromURL extrae el path relativo desde una URL completa
// Ejemplo: https://xxx.supabase.co/storage/v1/object/public/archivos/entregas/abc/file.pdf
// Resultado: entregas/abc/file.pdf
func (s *StorageService) extractPathFromURL(fileURL string) (string, error) {
	// Si ya es un path relativo, devolverlo tal cual
	if !strings.HasPrefix(fileURL, "http") {
		return fileURL, nil
	}

	// Parse URL
	u, err := url.Parse(fileURL)
	if err != nil {
		return "", fmt.Errorf("URL inválida: %w", err)
	}

	// Buscar el patrón: /object/public/{bucket}/ o /object/{bucket}/
	// El path viene después del bucket
	pathParts := strings.Split(u.Path, "/"+s.bucket+"/")
	if len(pathParts) < 2 {
		return "", fmt.Errorf("URL no contiene el bucket esperado: %s", s.bucket)
	}

	// El path es todo lo que viene después del bucket
	relativePath := pathParts[1]

	fmt.Printf("🔍 Path extraído: %s\n", relativePath)
	return relativePath, nil
}

// ✅ NUEVO: DeleteMultipleFiles elimina múltiples archivos
func (s *StorageService) DeleteMultipleFiles(fileURLs []string) error {
	for _, fileURL := range fileURLs {
		if err := s.DeleteFile(fileURL); err != nil {
			fmt.Printf("⚠️ Error eliminando %s: %v\n", fileURL, err)
			// Continuar con los demás archivos
		}
	}
	return nil
}

// ✅ Detectar Content-Type por extensión
func getContentType(ext string) string {
	contentTypes := map[string]string{
		".jpg":  "image/jpeg",
		".jpeg": "image/jpeg",
		".png":  "image/png",
		".gif":  "image/gif",
		".webp": "image/webp",
		".pdf":  "application/pdf",
		".doc":  "application/msword",
		".docx": "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
		".xls":  "application/vnd.ms-excel",
		".xlsx": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
		".ppt":  "application/vnd.ms-powerpoint",
		".pptx": "application/vnd.openxmlformats-officedocument.presentationml.presentation",
		".mp4":  "video/mp4",
		".mov":  "video/quicktime",
		".avi":  "video/x-msvideo",
		".txt":  "text/plain",
		".zip":  "application/zip",
		".rar":  "application/x-rar-compressed",
	}

	// Convertir extensión a minúsculas
	ext = strings.ToLower(ext)

	// Buscar el content type
	if contentType, exists := contentTypes[ext]; exists {
		return contentType
	}

	// Por defecto: binary/octet-stream (descarga forzada)
	return "application/octet-stream"
}
