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
	categoriaHandler *handlers.CategoriaHandler,
	portafolioHandler *handlers.PortafolioHandler,
	notificationHandler *handlers.NotificationHandler,
	usuarioHandler *handlers.UsuarioHandler,
) {
	api := app.Group("/api")

	// ==================== USUARIOS (COMPARTIR) ====================
	usuarios := api.Group("/usuarios")
	usuarios.Use(middleware.AuthRequired)
	usuarios.Get("/para-compartir", usuarioHandler.ObtenerUsuariosParaCompartir)
	usuarios.Post("/device", usuarioHandler.RegistrarDispositivo) // ✅ NUEVA LÍNEA

	// ==================== AUTH ====================
	auth := api.Group("/auth")
	auth.Post("/login", authHandler.Login)
	auth.Post("/cambiar-password", authHandler.ChangePassword)
	auth.Patch("/omitir-cambio-password", authHandler.OmitirCambioPassword)

	// ==================== ✅ PERFILES POR ROL ====================
	api.Get("/docente/perfil", middleware.AuthRequired, authHandler.GetDocentePerfil)
	api.Get("/estudiante/perfil", middleware.AuthRequired, authHandler.GetEstudiantePerfil)
	api.Get("/admin/perfil", middleware.AuthRequired, authHandler.GetAdministradorPerfil)

	// ==================== ADMIN ====================
	admin := api.Group("/admin")
	admin.Use(middleware.AuthRequired)
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

	// ==================== ✅ CATEGORÍAS (ADMIN) ====================
	admin.Post("/categorias", categoriaHandler.Crear)

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
	temas.Put("/:id", temaHandler.ActualizarTema)
	temas.Delete("/:id", temaHandler.EliminarTema)

	temas.Get("/:id/materiales", materialHandler.ListarMaterialesPorTema)
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

	tareas.Get("/:id/entregas", tareaHandler.GetEntregasPorTarea)
	tareas.Get("/:id/mi-entrega", entregaHandler.ObtenerMiEntrega)

	// ==================== ENTREGAS ====================
	entregas := api.Group("/entregas")
	entregas.Use(middleware.AuthRequired)

	entregas.Post("/", entregaHandler.CrearEntrega)
	entregas.Get("/:id", entregaHandler.ObtenerEntregaPorID)
	entregas.Put("/:id", entregaHandler.EditarEntrega)
	entregas.Delete("/:id", entregaHandler.EliminarEntrega)

	entregas.Post("/:id/archivos", entregaHandler.SubirArchivoEntrega)
	entregas.Delete("/archivos/:archivoId", entregaHandler.EliminarArchivoEntrega)
	entregas.Put("/:id/calificar", entregaHandler.CalificarEntrega)

	// ==================== ✅ CATEGORÍAS (PÚBLICO) ====================
	categorias := api.Group("/categorias")
	categorias.Use(middleware.AuthRequired)

	categorias.Get("/", categoriaHandler.ListarActivas)
	categorias.Get("/:id", categoriaHandler.ObtenerPorID)

	// ==================== ✅ PORTAFOLIO ====================
	portafolio := api.Group("/portafolio")
	portafolio.Use(middleware.AuthRequired)

	// CRUD Recetas
	portafolio.Post("/", portafolioHandler.Crear)
	portafolio.Put("/:id", portafolioHandler.Actualizar)
	portafolio.Get("/mis-recetas", portafolioHandler.ObtenerMisRecetas)
	portafolio.Get("/publicas", portafolioHandler.ObtenerPublicas)
	portafolio.Get("/:id", portafolioHandler.ObtenerPorID)
	portafolio.Delete("/:id", portafolioHandler.Eliminar)

	// Likes
	portafolio.Post("/:id/like", portafolioHandler.ToggleLike)
	portafolio.Get("/:id/ya-dio-like", portafolioHandler.YaDioLike)

	// Comentarios
	portafolio.Post("/:id/comentarios", portafolioHandler.CrearComentario)
	portafolio.Get("/:id/comentarios", portafolioHandler.ObtenerComentarios)

	// ==================== ✅ NOTIFICACIONES ====================
	notificaciones := api.Group("/notificaciones")
	notificaciones.Use(middleware.AuthRequired)

	// Compartir recetas
	notificaciones.Post("/compartir-receta", notificationHandler.CompartirReceta)

	// Mis notificaciones
	notificaciones.Get("/mis-notificaciones", notificationHandler.ObtenerMisNotificaciones)
	notificaciones.Patch("/:id/leer", notificationHandler.MarcarComoLeida)
	notificaciones.Patch("/leer-todas", notificationHandler.MarcarTodasComoLeidas)
	notificaciones.Get("/no-leidas/count", notificationHandler.ContarNoLeidas)

	// Registrar dispositivo FCM
	notificaciones.Post("/registrar-dispositivo", notificationHandler.RegistrarDispositivo)
}
