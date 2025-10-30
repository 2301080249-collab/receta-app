package main

import (
	"log"
	"os"
	"os/signal"
	"syscall"

	"recetario-backend/internal/config"
	"recetario-backend/internal/handlers"
	"recetario-backend/internal/repository"
	"recetario-backend/internal/routes"
	"recetario-backend/internal/services"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"github.com/gofiber/fiber/v2/middleware/logger"
	"github.com/gofiber/fiber/v2/middleware/recover"
)

func main() {
	// Cargar configuración
	config.LoadConfig()

	// ✅ DEBUG: Verificar que las variables se carguen correctamente
	log.Println("========================================")
	log.Println("📋 CONFIGURACIÓN CARGADA")
	log.Println("========================================")
	log.Println("SUPABASE_URL:", config.AppConfig.SupabaseURL)
	log.Println("SUPABASE_STORAGE_URL:", config.AppConfig.SupabaseStorageURL)
	log.Println("PORT:", config.AppConfig.Port)
	log.Println("========================================")

	// Validar que las variables críticas existan
	if config.AppConfig.SupabaseStorageURL == "" {
		log.Fatal("❌ ERROR: SUPABASE_STORAGE_URL está vacío en el .env")
	}
	if config.AppConfig.SupabaseServiceKey == "" {
		log.Fatal("❌ ERROR: SUPABASE_SERVICE_KEY está vacío en el .env")
	}

	// ==================== DEPENDENCY INJECTION ====================

	// 1. Inicializar cliente Supabase
	supabaseClient := repository.NewSupabaseClient()
	// 2. Repositories
	authRepo := repository.NewAuthRepository(supabaseClient)
	usuarioRepo := repository.NewUsuarioRepository(supabaseClient)
	cicloRepo := repository.NewCicloRepository(supabaseClient)
	cursoRepo := repository.NewCursoRepository(supabaseClient)
	matriculaRepo := repository.NewMatriculaRepository(supabaseClient)
	temaRepo := repository.NewTemaRepository(supabaseClient)
	materialRepo := repository.NewMaterialRepository(supabaseClient) // ✅ NUEVO
	tareaRepo := repository.NewTareaRepository(supabaseClient)       // ✅ NUEVO
	entregaRepo := repository.NewEntregaRepository(supabaseClient)   // ✅ NUEVO

	// 3. Services
	authService := services.NewAuthService(authRepo, usuarioRepo)
	adminService := services.NewAdminService(authRepo, usuarioRepo)
	cicloService := services.NewCicloService(cicloRepo)
	cursoService := services.NewCursoService(cursoRepo, cicloRepo, usuarioRepo, temaRepo)
	matriculaService := services.NewMatriculaService(matriculaRepo, usuarioRepo, cursoRepo, cicloRepo)
	temaService := services.NewTemaService(temaRepo, tareaRepo, entregaRepo)

	// Storage Service
	storageService := services.NewStorageService(
		config.AppConfig.SupabaseStorageURL,
		config.AppConfig.SupabaseServiceKey,
		"archivos", // nombre del bucket
	) // ✅ NUEVO

	materialService := services.NewMaterialService(materialRepo, storageService)         // ✅ NUEVO
	tareaService := services.NewTareaService(tareaRepo, entregaRepo)                     // ✅ NUEVO
	entregaService := services.NewEntregaService(entregaRepo, tareaRepo, storageService) // ✅ NUEVO

	// 4. Handlers
	authHandler := handlers.NewAuthHandler(authService)
	adminHandler := handlers.NewAdminHandler(adminService)
	cicloHandler := handlers.NewCicloHandler(cicloService)
	cursoHandler := handlers.NewCursoHandler(cursoService)
	matriculaHandler := handlers.NewMatriculaHandler(matriculaService)
	temaHandler := handlers.NewTemaHandler(temaService)
	materialHandler := handlers.NewMaterialHandler(materialService, storageService)            // ✅ NUEVO
	tareaHandler := handlers.NewTareaHandler(tareaService, entregaService)                     // ✅ CORRECTO                                  // ✅ NUEVO
	entregaHandler := handlers.NewEntregaHandler(entregaService, tareaService, storageService) // ✅ NUEVO

	// ==================== FIBER SETUP ====================

	// Crear app Fiber
	app := fiber.New(fiber.Config{
		AppName:      "Sistema de Recetas API",
		ErrorHandler: customErrorHandler,
	})

	// Middlewares globales
	app.Use(recover.New())
	app.Use(logger.New(logger.Config{
		Format: "[${time}] ${status} - ${method} ${path}\n",
	}))
	app.Use(cors.New(cors.Config{
		AllowOrigins: "*",
		AllowHeaders: "Origin, Content-Type, Accept, Authorization",
		AllowMethods: "GET, POST, PUT, DELETE, OPTIONS, PATCH",
	}))

	// Health check
	app.Get("/health", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"status":  "ok",
			"service": "Sistema de Recetas API",
			"version": "1.0.0",
		})
	})

	// Configurar rutas - ✅ ACTUALIZADO
	routes.SetupRoutes(
		app,
		authHandler,
		adminHandler,
		cicloHandler,
		cursoHandler,
		matriculaHandler,
		temaHandler,
		materialHandler, // ✅ NUEVO
		tareaHandler,    // ✅ NUEVO
		entregaHandler,  // ✅ NUEVO
	)

	// Graceful shutdown
	go func() {
		sigint := make(chan os.Signal, 1)
		signal.Notify(sigint, os.Interrupt, syscall.SIGTERM)
		<-sigint
		log.Println("🛑 Apagando servidor...")
		app.Shutdown()
	}()

	// Iniciar servidor
	port := config.AppConfig.Port
	log.Printf("🚀 Servidor corriendo en http://localhost:%s", port)

	if err := app.Listen(":" + port); err != nil {
		log.Fatal("❌ Error al iniciar servidor:", err)
	}
}

// Manejo de errores personalizado
func customErrorHandler(c *fiber.Ctx, err error) error {
	code := fiber.StatusInternalServerError

	if e, ok := err.(*fiber.Error); ok {
		code = e.Code
	}

	return c.Status(code).JSON(fiber.Map{
		"error":   true,
		"message": err.Error(),
	})
}
