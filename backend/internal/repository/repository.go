package repository

// ==================== AUTH REPOSITORY ====================
type AuthRepository interface {
	Authenticate(email, password string) (accessToken string, userID string, err error)
	UpdatePassword(userID, newPassword string) error
	CreateAuthUser(email, password, nombreCompleto, rol string) (string, error)
	DeleteAuthUser(userID string) error
}

// ==================== USUARIO REPOSITORY ====================
type UsuarioRepository interface {
	GetUserByID(userID string) ([]byte, error)
	GetUserByIDWithRelations(userID string) ([]byte, error)
	GetAllUsers() ([]byte, error)
	GetAllUsersWithRelations() ([]byte, error)
	CreateUser(authBody, userData interface{}) ([]byte, error)
	UpdateUser(userID string, data map[string]interface{}) error
	UpdateEstudiante(userID string, data map[string]interface{}) error
	UpdateDocente(userID string, data map[string]interface{}) error
	CreateUsuario(data map[string]interface{}) error
	CreateEstudiante(data map[string]interface{}) error
	CreateDocente(data map[string]interface{}) error
	CreateAdministrador(data map[string]interface{}) error
	GetEstudiantesDisponibles(cursoID, cicloID string) ([]byte, error)

	// ✅ NUEVOS MÉTODOS PARA OBTENER PERFIL POR ROL
	GetDocenteByUserID(userID string) ([]byte, error)
	GetEstudianteByUserID(userID string) ([]byte, error)
	GetAdministradorByUserID(userID string) ([]byte, error)

	// 🆕 AGREGAR ESTE MÉTODO
	GetUsuariosRelacionadosPorCurso(userID string, userRol string) ([]byte, error)
}

// ==================== CICLO REPOSITORY ====================
type CicloRepository interface {
	CreateCiclo(data map[string]interface{}) ([]byte, error)
	GetAllCiclos() ([]byte, error)
	GetCicloByID(cicloID string) ([]byte, error)
	GetCicloActivo() ([]byte, error)
	UpdateCiclo(cicloID string, data map[string]interface{}) error
	DeleteCiclo(cicloID string) error
	CicloTieneCursos(cicloID string) (bool, error) // 👈 AGREGAR ESTA LÍNEA
}

// ==================== CURSO REPOSITORY ====================
type CursoRepository interface {
	CreateCurso(data map[string]interface{}) ([]byte, error)
	GetAllCursos() ([]byte, error)
	GetCursoByID(cursoID string) ([]byte, error)
	GetCursosByCiclo(cicloID string) ([]byte, error)
	GetCursosByDocente(docenteID string) ([]byte, error)
	GetCursosByEstudiante(estudianteID string) ([]byte, error)
	UpdateCurso(cursoID string, data map[string]interface{}) error
	DeleteCurso(cursoID string) error
	CursoTieneMatriculas(cursoID string) (bool, error) //
}

// ==================== MATRICULA REPOSITORY ====================
type MatriculaRepository interface {
	CreateMatricula(data map[string]interface{}) ([]byte, error)
	GetAllMatriculas() ([]byte, error)
	GetMatriculasByCurso(cursoID string) ([]byte, error)
	GetMatriculasByEstudiante(estudianteID string) ([]byte, error)
	CheckMatriculaExists(estudianteID, cursoID, cicloID string) ([]byte, error)
	UpdateMatricula(matriculaID string, data map[string]interface{}) error
	DeleteMatricula(matriculaID string) error
}
