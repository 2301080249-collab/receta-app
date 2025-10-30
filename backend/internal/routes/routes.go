package routes

import (
	"recetario-backend/internal/handlers"
	"recetario-backend/internal/middleware"

	"github.com/gofiber/fiber/v2"
)

func SetupRoutes(
	app *fiber.App,
	authHandler *handlers.AuthHandler,
	adminHandler *handlers.AdminHandler,
	cicloHandler *handlers.CicloHandler,
	cursoHandler *handlers.CursoHandler,
	matriculaHandler *handlers.MatriculaHandler,
	temaHandler *handlers.TemaHandler,
	materialHandler *handlers.MaterialHandler,
	tareaHandler *handlers.TareaHandler,
	entregaHandler *handlers.EntregaHandler,
) {
	api := app.Group("/api")

	// ==================== AUTH ====================
	auth := api.Group("/auth")
	auth.Post("/login", authHandler.Login)
	auth.Post("/cambiar-password", authHandler.ChangePassword)
	auth.Patch("/omitir-cambio-password", authHandler.OmitirCambioPassword)

	// ==================== ✅ NUEVAS RUTAS: PERFIL POR ROL ====================
	// Estas rutas requieren autenticación y devuelven los datos extendidos según el rol
	api.Get("/docente/perfil", middleware.AuthRequired, authHandler.GetDocentePerfil)
	api.Get("/estudiante/perfil", middleware.AuthRequired, authHandler.GetEstudiantePerfil)
	api.Get("/admin/perfil", middleware.AuthRequired, authHandler.GetAdministradorPerfil)

	// ==================== ADMIN ====================
	admin := api.Group("/admin")
	admin.Use(middleware.AuthRequired)
	// ✅ AGREGA ESTA LÍNEA NUEVA (línea después de admin.Use)
	admin.Get("/dashboard/stats", adminHandler.ObtenerEstadisticas)

	admin.Post("/crear-usuario", adminHandler.CrearUsuario)
	admin.Get("/usuarios", adminHandler.ListarUsuarios)
	admin.Get("/usuarios/:id", adminHandler.ObtenerUsuarioPorID)
	admin.Put("/usuarios/:id", adminHandler.EditarUsuario)
	admin.Delete("/usuarios/:id", adminHandler.EliminarUsuario)

	admin.Post("/ciclos", cicloHandler.CrearCiclo)
	admin.Get("/ciclos", cicloHandler.ListarCiclos)
	admin.Get("/ciclos/activo", cicloHandler.ObtenerCicloActivo)
	admin.Get("/ciclos/:id", cicloHandler.ObtenerCicloPorID)
	admin.Patch("/ciclos/:id", cicloHandler.ActualizarCiclo)
	admin.Delete("/ciclos/:id", cicloHandler.EliminarCiclo)
	admin.Post("/ciclos/:id/activar", cicloHandler.ActivarCiclo)
	admin.Post("/ciclos/:id/desactivar", cicloHandler.DesactivarCiclo)

	admin.Post("/cursos", cursoHandler.CrearCurso)
	admin.Get("/cursos", cursoHandler.ListarCursos)
	admin.Get("/cursos/:id", cursoHandler.ObtenerCursoPorID)
	admin.Patch("/cursos/:id", cursoHandler.ActualizarCurso)
	admin.Delete("/cursos/:id", cursoHandler.EliminarCurso)
	admin.Post("/cursos/:id/activar", cursoHandler.ActivarCurso)
	admin.Post("/cursos/:id/desactivar", cursoHandler.DesactivarCurso)

	admin.Get("/matriculas", matriculaHandler.ListarTodasLasMatriculas)
	admin.Post("/matriculas", matriculaHandler.CrearMatricula)
	admin.Post("/matriculas/masiva", matriculaHandler.CrearMatriculaMasiva)
	admin.Get("/matriculas/curso/:curso_id", matriculaHandler.ListarMatriculasPorCurso)
	admin.Get("/matriculas/estudiante/:estudiante_id", matriculaHandler.ListarMatriculasPorEstudiante)
	admin.Get("/matriculas/disponibles", matriculaHandler.ListarEstudiantesDisponibles)
	admin.Patch("/matriculas/:id", matriculaHandler.ActualizarMatricula)
	admin.Delete("/matriculas/:id", matriculaHandler.EliminarMatricula)

	// ==================== ESTUDIANTES ====================
	estudiantes := api.Group("/estudiantes")
	estudiantes.Use(middleware.AuthRequired)

	estudiantes.Get("/:estudiante_id/cursos", cursoHandler.ListarCursosPorEstudiante)

	// ==================== CURSOS ====================
	cursos := api.Group("/cursos")
	cursos.Use(middleware.AuthRequired)

	cursos.Get("/:id/temas", temaHandler.ListarTemasPorCurso)

	// ==================== TEMAS ====================
	temas := api.Group("/temas")
	temas.Use(middleware.AuthRequired)

	temas.Post("/", temaHandler.CrearTema)
	temas.Get("/:id", temaHandler.ObtenerTema)
	temas.Patch("/:id", temaHandler.ActualizarTema)
	temas.Put("/:id", temaHandler.ActualizarTema) // ✅ AGREGADO: Soporte para PUT
	temas.Delete("/:id", temaHandler.EliminarTema)

	// Materiales por tema
	temas.Get("/:id/materiales", materialHandler.ListarMaterialesPorTema)
	// Tareas por tema
	temas.Get("/:id/tareas", tareaHandler.ListarTareasPorTema)

	// ==================== MATERIALES ====================
	materiales := api.Group("/materiales")
	materiales.Use(middleware.AuthRequired)

	materiales.Post("/", materialHandler.CrearMaterial)
	materiales.Put("/:id", materialHandler.ActualizarMaterial)
	materiales.Post("/upload", materialHandler.SubirArchivo)
	materiales.Post("/:id/marcar-visto", materialHandler.MarcarComoVisto)
	materiales.Delete("/:id", materialHandler.EliminarMaterial)

	// ==================== TAREAS ====================
	tareas := api.Group("/tareas")
	tareas.Use(middleware.AuthRequired)

	tareas.Post("/", tareaHandler.CrearTarea)
	tareas.Get("/:id", tareaHandler.ObtenerTarea)
	tareas.Put("/:id", tareaHandler.ActualizarTarea)
	tareas.Delete("/:id", tareaHandler.EliminarTarea)

	// Entregas de una tarea (docente)
	tareas.Get("/:id/entregas", tareaHandler.GetEntregasPorTarea)
	// Mi entrega (estudiante)
	tareas.Get("/:id/mi-entrega", entregaHandler.ObtenerMiEntrega)

	// ==================== ENTREGAS ====================
	entregas := api.Group("/entregas")
	entregas.Use(middleware.AuthRequired)

	entregas.Post("/", entregaHandler.CrearEntrega)
	entregas.Get("/:id", entregaHandler.ObtenerEntregaPorID)
	entregas.Put("/:id", entregaHandler.EditarEntrega)
	entregas.Delete("/:id", entregaHandler.EliminarEntrega)

	// Subir archivos a entrega
	entregas.Post("/:id/archivos", entregaHandler.SubirArchivoEntrega)

	// Eliminar archivo individual
	entregas.Delete("/archivos/:archivoId", entregaHandler.EliminarArchivoEntrega)

	// Calificar entrega (docente)
	entregas.Put("/:id/calificar", entregaHandler.CalificarEntrega)
}
