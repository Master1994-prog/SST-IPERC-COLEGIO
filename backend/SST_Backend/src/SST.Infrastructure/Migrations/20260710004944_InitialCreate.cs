using System;
using Microsoft.EntityFrameworkCore.Migrations;
using MySql.EntityFrameworkCore.Metadata;

#nullable disable

namespace SST.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class InitialCreate : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterDatabase()
                .Annotation("MySQL:Charset", "utf8mb4");

            migrationBuilder.CreateTable(
                name: "CategoriasPeligro",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("MySQL:ValueGenerationStrategy", MySQLValueGenerationStrategy.IdentityColumn),
                    Codigo = table.Column<string>(type: "varchar(20)", maxLength: 20, nullable: false),
                    Nombre = table.Column<string>(type: "varchar(150)", maxLength: 150, nullable: false),
                    Descripcion = table.Column<string>(type: "varchar(1000)", maxLength: 1000, nullable: true),
                    Color = table.Column<string>(type: "varchar(10)", maxLength: 10, nullable: true),
                    Icono = table.Column<string>(type: "varchar(100)", maxLength: 100, nullable: true),
                    Orden = table.Column<int>(type: "int", nullable: false, defaultValue: 0),
                    Activo = table.Column<bool>(type: "tinyint(1)", nullable: false, defaultValue: true),
                    Estado = table.Column<bool>(type: "tinyint(1)", nullable: false),
                    FechaRegistro = table.Column<DateTime>(type: "datetime(6)", nullable: false),
                    FechaActualizacion = table.Column<DateTime>(type: "datetime(6)", nullable: true),
                    UsuarioRegistroId = table.Column<long>(type: "bigint", nullable: false),
                    UsuarioActualizacionId = table.Column<long>(type: "bigint", nullable: true),
                    EsGlobal = table.Column<bool>(type: "tinyint(1)", nullable: false),
                    ColegioId = table.Column<long>(type: "bigint", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_CategoriasPeligro", x => x.Id);
                })
                .Annotation("MySQL:Charset", "utf8mb4");

            migrationBuilder.CreateTable(
                name: "ClasificacionesControl",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("MySQL:ValueGenerationStrategy", MySQLValueGenerationStrategy.IdentityColumn),
                    Codigo = table.Column<string>(type: "varchar(20)", maxLength: 20, nullable: false),
                    Nombre = table.Column<string>(type: "varchar(150)", maxLength: 150, nullable: false),
                    Descripcion = table.Column<string>(type: "varchar(1000)", maxLength: 1000, nullable: true),
                    Prioridad = table.Column<int>(type: "int", nullable: false),
                    Activo = table.Column<bool>(type: "tinyint(1)", nullable: false, defaultValue: true),
                    Estado = table.Column<bool>(type: "tinyint(1)", nullable: false, defaultValue: true),
                    FechaRegistro = table.Column<DateTime>(type: "datetime(6)", nullable: false),
                    FechaActualizacion = table.Column<DateTime>(type: "datetime(6)", nullable: true),
                    UsuarioRegistroId = table.Column<long>(type: "bigint", nullable: false),
                    UsuarioActualizacionId = table.Column<long>(type: "bigint", nullable: true),
                    EsGlobal = table.Column<bool>(type: "tinyint(1)", nullable: false),
                    ColegioId = table.Column<long>(type: "bigint", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ClasificacionesControl", x => x.Id);
                })
                .Annotation("MySQL:Charset", "utf8mb4");

            migrationBuilder.CreateTable(
                name: "Consecuencias",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("MySQL:ValueGenerationStrategy", MySQLValueGenerationStrategy.IdentityColumn),
                    Codigo = table.Column<string>(type: "varchar(20)", maxLength: 20, nullable: false),
                    Nombre = table.Column<string>(type: "varchar(200)", maxLength: 200, nullable: false),
                    Descripcion = table.Column<string>(type: "varchar(1500)", maxLength: 1500, nullable: true),
                    Clasificacion = table.Column<string>(type: "varchar(100)", maxLength: 100, nullable: true),
                    IncapacidadPermanente = table.Column<bool>(type: "tinyint(1)", nullable: false, defaultValue: false),
                    Fatalidad = table.Column<bool>(type: "tinyint(1)", nullable: false, defaultValue: false),
                    Activo = table.Column<bool>(type: "tinyint(1)", nullable: false, defaultValue: true),
                    Estado = table.Column<bool>(type: "tinyint(1)", nullable: false, defaultValue: true),
                    FechaRegistro = table.Column<DateTime>(type: "datetime(6)", nullable: false),
                    FechaActualizacion = table.Column<DateTime>(type: "datetime(6)", nullable: true),
                    UsuarioRegistroId = table.Column<long>(type: "bigint", nullable: false),
                    UsuarioActualizacionId = table.Column<long>(type: "bigint", nullable: true),
                    EsGlobal = table.Column<bool>(type: "tinyint(1)", nullable: false),
                    ColegioId = table.Column<long>(type: "bigint", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Consecuencias", x => x.Id);
                })
                .Annotation("MySQL:Charset", "utf8mb4");

            migrationBuilder.CreateTable(
                name: "Instituciones",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("MySQL:ValueGenerationStrategy", MySQLValueGenerationStrategy.IdentityColumn),
                    Codigo = table.Column<string>(type: "varchar(20)", maxLength: 20, nullable: false),
                    Nombre = table.Column<string>(type: "varchar(200)", maxLength: 200, nullable: false),
                    Ruc = table.Column<string>(type: "varchar(20)", maxLength: 20, nullable: true),
                    Direccion = table.Column<string>(type: "varchar(300)", maxLength: 300, nullable: true),
                    Distrito = table.Column<string>(type: "varchar(100)", maxLength: 100, nullable: true),
                    Provincia = table.Column<string>(type: "varchar(100)", maxLength: 100, nullable: true),
                    Departamento = table.Column<string>(type: "varchar(100)", maxLength: 100, nullable: true),
                    Telefono = table.Column<string>(type: "varchar(100)", maxLength: 100, nullable: true),
                    Correo = table.Column<string>(type: "varchar(150)", maxLength: 150, nullable: true),
                    Activo = table.Column<bool>(type: "tinyint(1)", nullable: false),
                    Estado = table.Column<bool>(type: "tinyint(1)", nullable: false, defaultValue: true),
                    FechaRegistro = table.Column<DateTime>(type: "datetime(6)", nullable: false),
                    FechaActualizacion = table.Column<DateTime>(type: "datetime(6)", nullable: true),
                    UsuarioRegistroId = table.Column<long>(type: "bigint", nullable: false),
                    UsuarioActualizacionId = table.Column<long>(type: "bigint", nullable: true),
                    EsGlobal = table.Column<bool>(type: "tinyint(1)", nullable: false),
                    ColegioId = table.Column<long>(type: "bigint", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Instituciones", x => x.Id);
                })
                .Annotation("MySQL:Charset", "utf8mb4");

            migrationBuilder.CreateTable(
                name: "NivelesRiesgo",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("MySQL:ValueGenerationStrategy", MySQLValueGenerationStrategy.IdentityColumn),
                    Nombre = table.Column<string>(type: "varchar(80)", maxLength: 80, nullable: false),
                    Desde = table.Column<int>(type: "int", nullable: false),
                    Hasta = table.Column<int>(type: "int", nullable: false),
                    Color = table.Column<string>(type: "varchar(20)", maxLength: 20, nullable: false),
                    Aceptable = table.Column<bool>(type: "tinyint(1)", nullable: false),
                    Estado = table.Column<bool>(type: "tinyint(1)", nullable: false),
                    FechaRegistro = table.Column<DateTime>(type: "datetime(6)", nullable: false),
                    FechaActualizacion = table.Column<DateTime>(type: "datetime(6)", nullable: true),
                    UsuarioRegistroId = table.Column<long>(type: "bigint", nullable: false),
                    UsuarioActualizacionId = table.Column<long>(type: "bigint", nullable: true),
                    EsGlobal = table.Column<bool>(type: "tinyint(1)", nullable: false),
                    ColegioId = table.Column<long>(type: "bigint", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_NivelesRiesgo", x => x.Id);
                })
                .Annotation("MySQL:Charset", "utf8mb4");

            migrationBuilder.CreateTable(
                name: "Probabilidades",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("MySQL:ValueGenerationStrategy", MySQLValueGenerationStrategy.IdentityColumn),
                    Valor = table.Column<int>(type: "int", nullable: false),
                    Nombre = table.Column<string>(type: "varchar(100)", maxLength: 100, nullable: false),
                    Descripcion = table.Column<string>(type: "varchar(500)", maxLength: 500, nullable: true),
                    Estado = table.Column<bool>(type: "tinyint(1)", nullable: false),
                    FechaRegistro = table.Column<DateTime>(type: "datetime(6)", nullable: false),
                    FechaActualizacion = table.Column<DateTime>(type: "datetime(6)", nullable: true),
                    UsuarioRegistroId = table.Column<long>(type: "bigint", nullable: false),
                    UsuarioActualizacionId = table.Column<long>(type: "bigint", nullable: true),
                    EsGlobal = table.Column<bool>(type: "tinyint(1)", nullable: false),
                    ColegioId = table.Column<long>(type: "bigint", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Probabilidades", x => x.Id);
                })
                .Annotation("MySQL:Charset", "utf8mb4");

            migrationBuilder.CreateTable(
                name: "Severidades",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("MySQL:ValueGenerationStrategy", MySQLValueGenerationStrategy.IdentityColumn),
                    Valor = table.Column<int>(type: "int", nullable: false),
                    Nombre = table.Column<string>(type: "varchar(100)", maxLength: 100, nullable: false),
                    Descripcion = table.Column<string>(type: "varchar(500)", maxLength: 500, nullable: true),
                    Estado = table.Column<bool>(type: "tinyint(1)", nullable: false),
                    FechaRegistro = table.Column<DateTime>(type: "datetime(6)", nullable: false),
                    FechaActualizacion = table.Column<DateTime>(type: "datetime(6)", nullable: true),
                    UsuarioRegistroId = table.Column<long>(type: "bigint", nullable: false),
                    UsuarioActualizacionId = table.Column<long>(type: "bigint", nullable: true),
                    EsGlobal = table.Column<bool>(type: "tinyint(1)", nullable: false),
                    ColegioId = table.Column<long>(type: "bigint", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Severidades", x => x.Id);
                })
                .Annotation("MySQL:Charset", "utf8mb4");

            migrationBuilder.CreateTable(
                name: "TiposEquipoProteccion",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("MySQL:ValueGenerationStrategy", MySQLValueGenerationStrategy.IdentityColumn),
                    Codigo = table.Column<string>(type: "varchar(20)", maxLength: 20, nullable: false),
                    Nombre = table.Column<string>(type: "varchar(150)", maxLength: 150, nullable: false),
                    Descripcion = table.Column<string>(type: "varchar(1000)", maxLength: 1000, nullable: true),
                    Orden = table.Column<int>(type: "int", nullable: false),
                    Activo = table.Column<bool>(type: "tinyint(1)", nullable: false, defaultValue: true),
                    EsGlobal = table.Column<bool>(type: "tinyint(1)", nullable: false, defaultValue: true),
                    ColegioId = table.Column<long>(type: "bigint", nullable: true),
                    Estado = table.Column<bool>(type: "tinyint(1)", nullable: false, defaultValue: true),
                    FechaRegistro = table.Column<DateTime>(type: "datetime(6)", nullable: false),
                    FechaActualizacion = table.Column<DateTime>(type: "datetime(6)", nullable: true),
                    UsuarioRegistroId = table.Column<long>(type: "bigint", nullable: false),
                    UsuarioActualizacionId = table.Column<long>(type: "bigint", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_TiposEquipoProteccion", x => x.Id);
                })
                .Annotation("MySQL:Charset", "utf8mb4");

            migrationBuilder.CreateTable(
                name: "Usuarios",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("MySQL:ValueGenerationStrategy", MySQLValueGenerationStrategy.IdentityColumn),
                    Nombres = table.Column<string>(type: "varchar(100)", maxLength: 100, nullable: false),
                    Apellidos = table.Column<string>(type: "varchar(100)", maxLength: 100, nullable: false),
                    NumeroDocumento = table.Column<string>(type: "varchar(20)", maxLength: 20, nullable: true),
                    TipoDocumento = table.Column<string>(type: "varchar(20)", maxLength: 20, nullable: true),
                    Correo = table.Column<string>(type: "varchar(150)", maxLength: 150, nullable: true),
                    Telefono = table.Column<string>(type: "varchar(20)", maxLength: 20, nullable: true),
                    NombreUsuario = table.Column<string>(type: "varchar(80)", maxLength: 80, nullable: false),
                    PasswordHash = table.Column<string>(type: "varchar(500)", maxLength: 500, nullable: false),
                    DebeCambiarPassword = table.Column<bool>(type: "tinyint(1)", nullable: false),
                    UltimoAcceso = table.Column<DateTime>(type: "datetime(6)", nullable: true),
                    InstitucionId = table.Column<long>(type: "bigint", nullable: false),
                    SedeId = table.Column<long>(type: "bigint", nullable: true),
                    AreaId = table.Column<long>(type: "bigint", nullable: true),
                    Activo = table.Column<bool>(type: "tinyint(1)", nullable: false),
                    Estado = table.Column<bool>(type: "tinyint(1)", nullable: false),
                    FechaRegistro = table.Column<DateTime>(type: "datetime(6)", nullable: false),
                    FechaActualizacion = table.Column<DateTime>(type: "datetime(6)", nullable: true),
                    UsuarioRegistroId = table.Column<long>(type: "bigint", nullable: false),
                    UsuarioActualizacionId = table.Column<long>(type: "bigint", nullable: true),
                    EsGlobal = table.Column<bool>(type: "tinyint(1)", nullable: false),
                    ColegioId = table.Column<long>(type: "bigint", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Usuarios", x => x.Id);
                })
                .Annotation("MySQL:Charset", "utf8mb4");

            migrationBuilder.CreateTable(
                name: "TiposPeligro",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("MySQL:ValueGenerationStrategy", MySQLValueGenerationStrategy.IdentityColumn),
                    Codigo = table.Column<string>(type: "varchar(20)", maxLength: 20, nullable: false),
                    Nombre = table.Column<string>(type: "varchar(150)", maxLength: 150, nullable: false),
                    Descripcion = table.Column<string>(type: "varchar(1000)", maxLength: 1000, nullable: true),
                    Orden = table.Column<int>(type: "int", nullable: false),
                    Activo = table.Column<bool>(type: "tinyint(1)", nullable: false, defaultValue: true),
                    CategoriaPeligroId = table.Column<long>(type: "bigint", nullable: false),
                    Estado = table.Column<bool>(type: "tinyint(1)", nullable: false),
                    FechaRegistro = table.Column<DateTime>(type: "datetime(6)", nullable: false),
                    FechaActualizacion = table.Column<DateTime>(type: "datetime(6)", nullable: true),
                    UsuarioRegistroId = table.Column<long>(type: "bigint", nullable: false),
                    UsuarioActualizacionId = table.Column<long>(type: "bigint", nullable: true),
                    EsGlobal = table.Column<bool>(type: "tinyint(1)", nullable: false),
                    ColegioId = table.Column<long>(type: "bigint", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_TiposPeligro", x => x.Id);
                    table.ForeignKey(
                        name: "FK_TiposPeligro_CategoriasPeligro_CategoriaPeligroId",
                        column: x => x.CategoriaPeligroId,
                        principalTable: "CategoriasPeligro",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                })
                .Annotation("MySQL:Charset", "utf8mb4");

            migrationBuilder.CreateTable(
                name: "Controles",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("MySQL:ValueGenerationStrategy", MySQLValueGenerationStrategy.IdentityColumn),
                    Codigo = table.Column<string>(type: "varchar(20)", maxLength: 20, nullable: false),
                    Nombre = table.Column<string>(type: "varchar(250)", maxLength: 250, nullable: false),
                    Descripcion = table.Column<string>(type: "varchar(2000)", maxLength: 2000, nullable: true),
                    ClasificacionControlId = table.Column<long>(type: "bigint", nullable: false),
                    Prioridad = table.Column<int>(type: "int", nullable: false),
                    Obligatorio = table.Column<bool>(type: "tinyint(1)", nullable: false, defaultValue: false),
                    Frecuencia = table.Column<string>(type: "varchar(100)", maxLength: 100, nullable: true),
                    ResponsableSugerido = table.Column<string>(type: "varchar(200)", maxLength: 200, nullable: true),
                    RequisitoLegal = table.Column<string>(type: "varchar(1000)", maxLength: 1000, nullable: true),
                    Activo = table.Column<bool>(type: "tinyint(1)", nullable: false, defaultValue: true),
                    EsGlobal = table.Column<bool>(type: "tinyint(1)", nullable: false, defaultValue: true),
                    ColegioId = table.Column<long>(type: "bigint", nullable: true),
                    Estado = table.Column<bool>(type: "tinyint(1)", nullable: false, defaultValue: true),
                    FechaRegistro = table.Column<DateTime>(type: "datetime(6)", nullable: false),
                    FechaActualizacion = table.Column<DateTime>(type: "datetime(6)", nullable: true),
                    UsuarioRegistroId = table.Column<long>(type: "bigint", nullable: false),
                    UsuarioActualizacionId = table.Column<long>(type: "bigint", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Controles", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Controles_ClasificacionesControl_ClasificacionControlId",
                        column: x => x.ClasificacionControlId,
                        principalTable: "ClasificacionesControl",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                })
                .Annotation("MySQL:Charset", "utf8mb4");

            migrationBuilder.CreateTable(
                name: "Areas",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("MySQL:ValueGenerationStrategy", MySQLValueGenerationStrategy.IdentityColumn),
                    Nombre = table.Column<string>(type: "varchar(150)", maxLength: 150, nullable: false),
                    Descripcion = table.Column<string>(type: "varchar(500)", maxLength: 500, nullable: true),
                    Activo = table.Column<bool>(type: "tinyint(1)", nullable: false),
                    InstitucionId = table.Column<long>(type: "bigint", nullable: false),
                    Estado = table.Column<bool>(type: "tinyint(1)", nullable: false, defaultValue: true),
                    FechaRegistro = table.Column<DateTime>(type: "datetime(6)", nullable: false),
                    FechaActualizacion = table.Column<DateTime>(type: "datetime(6)", nullable: true),
                    UsuarioRegistroId = table.Column<long>(type: "bigint", nullable: false),
                    UsuarioActualizacionId = table.Column<long>(type: "bigint", nullable: true),
                    EsGlobal = table.Column<bool>(type: "tinyint(1)", nullable: false),
                    ColegioId = table.Column<long>(type: "bigint", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Areas", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Areas_Instituciones_InstitucionId",
                        column: x => x.InstitucionId,
                        principalTable: "Instituciones",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                })
                .Annotation("MySQL:Charset", "utf8mb4");

            migrationBuilder.CreateTable(
                name: "Sedes",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("MySQL:ValueGenerationStrategy", MySQLValueGenerationStrategy.IdentityColumn),
                    Nombre = table.Column<string>(type: "varchar(150)", maxLength: 150, nullable: false),
                    Direccion = table.Column<string>(type: "varchar(300)", maxLength: 300, nullable: true),
                    Activo = table.Column<bool>(type: "tinyint(1)", nullable: false),
                    InstitucionId = table.Column<long>(type: "bigint", nullable: false),
                    Estado = table.Column<bool>(type: "tinyint(1)", nullable: false, defaultValue: true),
                    FechaRegistro = table.Column<DateTime>(type: "datetime(6)", nullable: false),
                    FechaActualizacion = table.Column<DateTime>(type: "datetime(6)", nullable: true),
                    UsuarioRegistroId = table.Column<long>(type: "bigint", nullable: false),
                    UsuarioActualizacionId = table.Column<long>(type: "bigint", nullable: true),
                    EsGlobal = table.Column<bool>(type: "tinyint(1)", nullable: false),
                    ColegioId = table.Column<long>(type: "bigint", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Sedes", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Sedes_Instituciones_InstitucionId",
                        column: x => x.InstitucionId,
                        principalTable: "Instituciones",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                })
                .Annotation("MySQL:Charset", "utf8mb4");

            migrationBuilder.CreateTable(
                name: "EvaluacionesRiesgo",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("MySQL:ValueGenerationStrategy", MySQLValueGenerationStrategy.IdentityColumn),
                    ProbabilidadId = table.Column<long>(type: "bigint", nullable: false),
                    SeveridadId = table.Column<long>(type: "bigint", nullable: false),
                    NivelRiesgoId = table.Column<long>(type: "bigint", nullable: false),
                    Valor = table.Column<int>(type: "int", nullable: false),
                    EsAceptable = table.Column<bool>(type: "tinyint(1)", nullable: false),
                    RequiereAccion = table.Column<bool>(type: "tinyint(1)", nullable: false),
                    Observaciones = table.Column<string>(type: "varchar(1000)", maxLength: 1000, nullable: true),
                    Estado = table.Column<bool>(type: "tinyint(1)", nullable: false),
                    FechaRegistro = table.Column<DateTime>(type: "datetime(6)", nullable: false),
                    FechaActualizacion = table.Column<DateTime>(type: "datetime(6)", nullable: true),
                    UsuarioRegistroId = table.Column<long>(type: "bigint", nullable: false),
                    UsuarioActualizacionId = table.Column<long>(type: "bigint", nullable: true),
                    EsGlobal = table.Column<bool>(type: "tinyint(1)", nullable: false),
                    ColegioId = table.Column<long>(type: "bigint", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_EvaluacionesRiesgo", x => x.Id);
                    table.ForeignKey(
                        name: "FK_EvaluacionesRiesgo_NivelesRiesgo_NivelRiesgoId",
                        column: x => x.NivelRiesgoId,
                        principalTable: "NivelesRiesgo",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_EvaluacionesRiesgo_Probabilidades_ProbabilidadId",
                        column: x => x.ProbabilidadId,
                        principalTable: "Probabilidades",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_EvaluacionesRiesgo_Severidades_SeveridadId",
                        column: x => x.SeveridadId,
                        principalTable: "Severidades",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                })
                .Annotation("MySQL:Charset", "utf8mb4");

            migrationBuilder.CreateTable(
                name: "EquiposProteccion",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("MySQL:ValueGenerationStrategy", MySQLValueGenerationStrategy.IdentityColumn),
                    Codigo = table.Column<string>(type: "varchar(20)", maxLength: 20, nullable: false),
                    Nombre = table.Column<string>(type: "varchar(200)", maxLength: 200, nullable: false),
                    Descripcion = table.Column<string>(type: "varchar(2000)", maxLength: 2000, nullable: true),
                    TipoEquipoProteccionId = table.Column<long>(type: "bigint", nullable: false),
                    Marca = table.Column<string>(type: "varchar(100)", maxLength: 100, nullable: true),
                    Modelo = table.Column<string>(type: "varchar(100)", maxLength: 100, nullable: true),
                    NormaTecnica = table.Column<string>(type: "varchar(300)", maxLength: 300, nullable: true),
                    VidaUtilMeses = table.Column<int>(type: "int", nullable: true),
                    RequiereCapacitacion = table.Column<bool>(type: "tinyint(1)", nullable: false, defaultValue: false),
                    RequiereMantenimiento = table.Column<bool>(type: "tinyint(1)", nullable: false, defaultValue: false),
                    Activo = table.Column<bool>(type: "tinyint(1)", nullable: false, defaultValue: true),
                    EsGlobal = table.Column<bool>(type: "tinyint(1)", nullable: false, defaultValue: true),
                    ColegioId = table.Column<long>(type: "bigint", nullable: true),
                    Estado = table.Column<bool>(type: "tinyint(1)", nullable: false, defaultValue: true),
                    FechaRegistro = table.Column<DateTime>(type: "datetime(6)", nullable: false),
                    FechaActualizacion = table.Column<DateTime>(type: "datetime(6)", nullable: true),
                    UsuarioRegistroId = table.Column<long>(type: "bigint", nullable: false),
                    UsuarioActualizacionId = table.Column<long>(type: "bigint", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_EquiposProteccion", x => x.Id);
                    table.ForeignKey(
                        name: "FK_EquiposProteccion_TiposEquipoProteccion_TipoEquipoProteccion~",
                        column: x => x.TipoEquipoProteccionId,
                        principalTable: "TiposEquipoProteccion",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                })
                .Annotation("MySQL:Charset", "utf8mb4");

            migrationBuilder.CreateTable(
                name: "Peligros",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("MySQL:ValueGenerationStrategy", MySQLValueGenerationStrategy.IdentityColumn),
                    Codigo = table.Column<string>(type: "varchar(20)", maxLength: 20, nullable: false),
                    Nombre = table.Column<string>(type: "varchar(200)", maxLength: 200, nullable: false),
                    Descripcion = table.Column<string>(type: "varchar(1500)", maxLength: 1500, nullable: true),
                    TipoPeligroId = table.Column<long>(type: "bigint", nullable: false),
                    Fuente = table.Column<string>(type: "varchar(300)", maxLength: 300, nullable: true),
                    Medio = table.Column<string>(type: "varchar(300)", maxLength: 300, nullable: true),
                    Receptor = table.Column<string>(type: "varchar(300)", maxLength: 300, nullable: true),
                    RequisitoLegal = table.Column<string>(type: "varchar(1000)", maxLength: 1000, nullable: true),
                    Recomendaciones = table.Column<string>(type: "varchar(2000)", maxLength: 2000, nullable: true),
                    Activo = table.Column<bool>(type: "tinyint(1)", nullable: false, defaultValue: true),
                    Estado = table.Column<bool>(type: "tinyint(1)", nullable: false, defaultValue: true),
                    FechaRegistro = table.Column<DateTime>(type: "datetime(6)", nullable: false),
                    FechaActualizacion = table.Column<DateTime>(type: "datetime(6)", nullable: true),
                    UsuarioRegistroId = table.Column<long>(type: "bigint", nullable: false),
                    UsuarioActualizacionId = table.Column<long>(type: "bigint", nullable: true),
                    EsGlobal = table.Column<bool>(type: "tinyint(1)", nullable: false),
                    ColegioId = table.Column<long>(type: "bigint", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Peligros", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Peligros_TiposPeligro_TipoPeligroId",
                        column: x => x.TipoPeligroId,
                        principalTable: "TiposPeligro",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                })
                .Annotation("MySQL:Charset", "utf8mb4");

            migrationBuilder.CreateTable(
                name: "Procesos",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("MySQL:ValueGenerationStrategy", MySQLValueGenerationStrategy.IdentityColumn),
                    Nombre = table.Column<string>(type: "varchar(150)", maxLength: 150, nullable: false),
                    Descripcion = table.Column<string>(type: "varchar(500)", maxLength: 500, nullable: true),
                    Activo = table.Column<bool>(type: "tinyint(1)", nullable: false),
                    AreaId = table.Column<long>(type: "bigint", nullable: false),
                    InstitucionId = table.Column<long>(type: "bigint", nullable: true),
                    Estado = table.Column<bool>(type: "tinyint(1)", nullable: false, defaultValue: true),
                    FechaRegistro = table.Column<DateTime>(type: "datetime(6)", nullable: false),
                    FechaActualizacion = table.Column<DateTime>(type: "datetime(6)", nullable: true),
                    UsuarioRegistroId = table.Column<long>(type: "bigint", nullable: false),
                    UsuarioActualizacionId = table.Column<long>(type: "bigint", nullable: true),
                    EsGlobal = table.Column<bool>(type: "tinyint(1)", nullable: false),
                    ColegioId = table.Column<long>(type: "bigint", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Procesos", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Procesos_Areas_AreaId",
                        column: x => x.AreaId,
                        principalTable: "Areas",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_Procesos_Instituciones_InstitucionId",
                        column: x => x.InstitucionId,
                        principalTable: "Instituciones",
                        principalColumn: "Id");
                })
                .Annotation("MySQL:Charset", "utf8mb4");

            migrationBuilder.CreateTable(
                name: "PuestosTrabajo",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("MySQL:ValueGenerationStrategy", MySQLValueGenerationStrategy.IdentityColumn),
                    Nombre = table.Column<string>(type: "varchar(150)", maxLength: 150, nullable: false),
                    Descripcion = table.Column<string>(type: "varchar(1000)", maxLength: 1000, nullable: true),
                    Activo = table.Column<bool>(type: "tinyint(1)", nullable: false),
                    AreaId = table.Column<long>(type: "bigint", nullable: false),
                    InstitucionId = table.Column<long>(type: "bigint", nullable: true),
                    Estado = table.Column<bool>(type: "tinyint(1)", nullable: false, defaultValue: true),
                    FechaRegistro = table.Column<DateTime>(type: "datetime(6)", nullable: false),
                    FechaActualizacion = table.Column<DateTime>(type: "datetime(6)", nullable: true),
                    UsuarioRegistroId = table.Column<long>(type: "bigint", nullable: false),
                    UsuarioActualizacionId = table.Column<long>(type: "bigint", nullable: true),
                    EsGlobal = table.Column<bool>(type: "tinyint(1)", nullable: false),
                    ColegioId = table.Column<long>(type: "bigint", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PuestosTrabajo", x => x.Id);
                    table.ForeignKey(
                        name: "FK_PuestosTrabajo_Areas_AreaId",
                        column: x => x.AreaId,
                        principalTable: "Areas",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_PuestosTrabajo_Instituciones_InstitucionId",
                        column: x => x.InstitucionId,
                        principalTable: "Instituciones",
                        principalColumn: "Id");
                })
                .Annotation("MySQL:Charset", "utf8mb4");

            migrationBuilder.CreateTable(
                name: "PeligrosConsecuencias",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("MySQL:ValueGenerationStrategy", MySQLValueGenerationStrategy.IdentityColumn),
                    PeligroId = table.Column<long>(type: "bigint", nullable: false),
                    ConsecuenciaId = table.Column<long>(type: "bigint", nullable: false),
                    Observaciones = table.Column<string>(type: "varchar(1000)", maxLength: 1000, nullable: true),
                    Principal = table.Column<bool>(type: "tinyint(1)", nullable: false, defaultValue: false),
                    Activo = table.Column<bool>(type: "tinyint(1)", nullable: false),
                    Estado = table.Column<bool>(type: "tinyint(1)", nullable: false, defaultValue: true),
                    FechaRegistro = table.Column<DateTime>(type: "datetime(6)", nullable: false),
                    FechaActualizacion = table.Column<DateTime>(type: "datetime(6)", nullable: true),
                    UsuarioRegistroId = table.Column<long>(type: "bigint", nullable: false),
                    UsuarioActualizacionId = table.Column<long>(type: "bigint", nullable: true),
                    EsGlobal = table.Column<bool>(type: "tinyint(1)", nullable: false),
                    ColegioId = table.Column<long>(type: "bigint", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PeligrosConsecuencias", x => x.Id);
                    table.ForeignKey(
                        name: "FK_PeligrosConsecuencias_Consecuencias_ConsecuenciaId",
                        column: x => x.ConsecuenciaId,
                        principalTable: "Consecuencias",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_PeligrosConsecuencias_Peligros_PeligroId",
                        column: x => x.PeligroId,
                        principalTable: "Peligros",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                })
                .Annotation("MySQL:Charset", "utf8mb4");

            migrationBuilder.CreateTable(
                name: "PeligrosControles",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("MySQL:ValueGenerationStrategy", MySQLValueGenerationStrategy.IdentityColumn),
                    PeligroId = table.Column<long>(type: "bigint", nullable: false),
                    ControlId = table.Column<long>(type: "bigint", nullable: false),
                    Obligatorio = table.Column<bool>(type: "tinyint(1)", nullable: false, defaultValue: false),
                    Prioridad = table.Column<int>(type: "int", nullable: false),
                    Activo = table.Column<bool>(type: "tinyint(1)", nullable: false),
                    Estado = table.Column<bool>(type: "tinyint(1)", nullable: false, defaultValue: true),
                    FechaRegistro = table.Column<DateTime>(type: "datetime(6)", nullable: false),
                    FechaActualizacion = table.Column<DateTime>(type: "datetime(6)", nullable: true),
                    UsuarioRegistroId = table.Column<long>(type: "bigint", nullable: false),
                    UsuarioActualizacionId = table.Column<long>(type: "bigint", nullable: true),
                    EsGlobal = table.Column<bool>(type: "tinyint(1)", nullable: false),
                    ColegioId = table.Column<long>(type: "bigint", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PeligrosControles", x => x.Id);
                    table.ForeignKey(
                        name: "FK_PeligrosControles_Controles_ControlId",
                        column: x => x.ControlId,
                        principalTable: "Controles",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_PeligrosControles_Peligros_PeligroId",
                        column: x => x.PeligroId,
                        principalTable: "Peligros",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                })
                .Annotation("MySQL:Charset", "utf8mb4");

            migrationBuilder.CreateTable(
                name: "PeligrosEquiposProteccion",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("MySQL:ValueGenerationStrategy", MySQLValueGenerationStrategy.IdentityColumn),
                    PeligroId = table.Column<long>(type: "bigint", nullable: false),
                    EquipoProteccionId = table.Column<long>(type: "bigint", nullable: false),
                    Obligatorio = table.Column<bool>(type: "tinyint(1)", nullable: false, defaultValue: false),
                    Estado = table.Column<bool>(type: "tinyint(1)", nullable: false, defaultValue: true),
                    FechaRegistro = table.Column<DateTime>(type: "datetime(6)", nullable: false),
                    FechaActualizacion = table.Column<DateTime>(type: "datetime(6)", nullable: true),
                    UsuarioRegistroId = table.Column<long>(type: "bigint", nullable: false),
                    UsuarioActualizacionId = table.Column<long>(type: "bigint", nullable: true),
                    EsGlobal = table.Column<bool>(type: "tinyint(1)", nullable: false),
                    ColegioId = table.Column<long>(type: "bigint", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PeligrosEquiposProteccion", x => x.Id);
                    table.ForeignKey(
                        name: "FK_PeligrosEquiposProteccion_EquiposProteccion_EquipoProteccion~",
                        column: x => x.EquipoProteccionId,
                        principalTable: "EquiposProteccion",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_PeligrosEquiposProteccion_Peligros_PeligroId",
                        column: x => x.PeligroId,
                        principalTable: "Peligros",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                })
                .Annotation("MySQL:Charset", "utf8mb4");

            migrationBuilder.CreateTable(
                name: "Actividades",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("MySQL:ValueGenerationStrategy", MySQLValueGenerationStrategy.IdentityColumn),
                    Nombre = table.Column<string>(type: "varchar(150)", maxLength: 150, nullable: false),
                    Descripcion = table.Column<string>(type: "varchar(500)", maxLength: 500, nullable: true),
                    Activo = table.Column<bool>(type: "tinyint(1)", nullable: false),
                    ProcesoId = table.Column<long>(type: "bigint", nullable: false),
                    InstitucionId = table.Column<long>(type: "bigint", nullable: true),
                    Estado = table.Column<bool>(type: "tinyint(1)", nullable: false, defaultValue: true),
                    FechaRegistro = table.Column<DateTime>(type: "datetime(6)", nullable: false),
                    FechaActualizacion = table.Column<DateTime>(type: "datetime(6)", nullable: true),
                    UsuarioRegistroId = table.Column<long>(type: "bigint", nullable: false),
                    UsuarioActualizacionId = table.Column<long>(type: "bigint", nullable: true),
                    EsGlobal = table.Column<bool>(type: "tinyint(1)", nullable: false),
                    ColegioId = table.Column<long>(type: "bigint", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Actividades", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Actividades_Instituciones_InstitucionId",
                        column: x => x.InstitucionId,
                        principalTable: "Instituciones",
                        principalColumn: "Id");
                    table.ForeignKey(
                        name: "FK_Actividades_Procesos_ProcesoId",
                        column: x => x.ProcesoId,
                        principalTable: "Procesos",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                })
                .Annotation("MySQL:Charset", "utf8mb4");

            migrationBuilder.CreateTable(
                name: "MatricesIPERC",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("MySQL:ValueGenerationStrategy", MySQLValueGenerationStrategy.IdentityColumn),
                    Codigo = table.Column<string>(type: "varchar(30)", maxLength: 30, nullable: false),
                    Nombre = table.Column<string>(type: "varchar(250)", maxLength: 250, nullable: false),
                    Objetivo = table.Column<string>(type: "varchar(1000)", maxLength: 1000, nullable: true),
                    Alcance = table.Column<string>(type: "varchar(1000)", maxLength: 1000, nullable: true),
                    Version = table.Column<int>(type: "int", nullable: false),
                    FechaEvaluacion = table.Column<DateTime>(type: "datetime(6)", nullable: false),
                    FechaRevision = table.Column<DateTime>(type: "datetime(6)", nullable: true),
                    FechaAprobacion = table.Column<DateTime>(type: "datetime(6)", nullable: true),
                    EstadoMatriz = table.Column<string>(type: "varchar(30)", maxLength: 30, nullable: false),
                    Observaciones = table.Column<string>(type: "varchar(3000)", maxLength: 3000, nullable: true),
                    InstitucionId = table.Column<long>(type: "bigint", nullable: false),
                    SedeId = table.Column<long>(type: "bigint", nullable: false),
                    AreaId = table.Column<long>(type: "bigint", nullable: false),
                    ProcesoId = table.Column<long>(type: "bigint", nullable: false),
                    ActividadId = table.Column<long>(type: "bigint", nullable: false),
                    PuestoTrabajoId = table.Column<long>(type: "bigint", nullable: false),
                    ResponsableId = table.Column<long>(type: "bigint", nullable: false),
                    AprobadorId = table.Column<long>(type: "bigint", nullable: true),
                    Estado = table.Column<bool>(type: "tinyint(1)", nullable: false),
                    FechaRegistro = table.Column<DateTime>(type: "datetime(6)", nullable: false),
                    FechaActualizacion = table.Column<DateTime>(type: "datetime(6)", nullable: true),
                    UsuarioRegistroId = table.Column<long>(type: "bigint", nullable: false),
                    UsuarioActualizacionId = table.Column<long>(type: "bigint", nullable: true),
                    EsGlobal = table.Column<bool>(type: "tinyint(1)", nullable: false),
                    ColegioId = table.Column<long>(type: "bigint", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_MatricesIPERC", x => x.Id);
                    table.ForeignKey(
                        name: "FK_MatricesIPERC_Actividades_ActividadId",
                        column: x => x.ActividadId,
                        principalTable: "Actividades",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_MatricesIPERC_Areas_AreaId",
                        column: x => x.AreaId,
                        principalTable: "Areas",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_MatricesIPERC_Instituciones_InstitucionId",
                        column: x => x.InstitucionId,
                        principalTable: "Instituciones",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_MatricesIPERC_Procesos_ProcesoId",
                        column: x => x.ProcesoId,
                        principalTable: "Procesos",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_MatricesIPERC_PuestosTrabajo_PuestoTrabajoId",
                        column: x => x.PuestoTrabajoId,
                        principalTable: "PuestosTrabajo",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_MatricesIPERC_Sedes_SedeId",
                        column: x => x.SedeId,
                        principalTable: "Sedes",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_MatricesIPERC_Usuarios_AprobadorId",
                        column: x => x.AprobadorId,
                        principalTable: "Usuarios",
                        principalColumn: "Id");
                    table.ForeignKey(
                        name: "FK_MatricesIPERC_Usuarios_ResponsableId",
                        column: x => x.ResponsableId,
                        principalTable: "Usuarios",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                })
                .Annotation("MySQL:Charset", "utf8mb4");

            migrationBuilder.CreateTable(
                name: "DetallesIPERC",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("MySQL:ValueGenerationStrategy", MySQLValueGenerationStrategy.IdentityColumn),
                    MatrizIPERCId = table.Column<long>(type: "bigint", nullable: false),
                    Item = table.Column<int>(type: "int", nullable: false),
                    Tarea = table.Column<string>(type: "varchar(500)", maxLength: 500, nullable: false),
                    PeligroId = table.Column<long>(type: "bigint", nullable: false),
                    ConsecuenciaId = table.Column<long>(type: "bigint", nullable: false),
                    DescripcionPeligro = table.Column<string>(type: "varchar(1500)", maxLength: 1500, nullable: true),
                    EvaluacionInicialId = table.Column<long>(type: "bigint", nullable: false),
                    EvaluacionResidualId = table.Column<long>(type: "bigint", nullable: true),
                    ResponsableImplementacionId = table.Column<long>(type: "bigint", nullable: true),
                    FechaCompromiso = table.Column<DateTime>(type: "datetime(6)", nullable: true),
                    FechaImplementacion = table.Column<DateTime>(type: "datetime(6)", nullable: true),
                    EstadoImplementacion = table.Column<int>(type: "int", nullable: false),
                    Estado = table.Column<bool>(type: "tinyint(1)", nullable: false, defaultValue: true),
                    FechaRegistro = table.Column<DateTime>(type: "datetime(6)", nullable: false),
                    FechaActualizacion = table.Column<DateTime>(type: "datetime(6)", nullable: true),
                    UsuarioRegistroId = table.Column<long>(type: "bigint", nullable: false),
                    UsuarioActualizacionId = table.Column<long>(type: "bigint", nullable: true),
                    EsGlobal = table.Column<bool>(type: "tinyint(1)", nullable: false),
                    ColegioId = table.Column<long>(type: "bigint", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_DetallesIPERC", x => x.Id);
                    table.ForeignKey(
                        name: "FK_DetallesIPERC_Consecuencias_ConsecuenciaId",
                        column: x => x.ConsecuenciaId,
                        principalTable: "Consecuencias",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_DetallesIPERC_EvaluacionesRiesgo_EvaluacionInicialId",
                        column: x => x.EvaluacionInicialId,
                        principalTable: "EvaluacionesRiesgo",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_DetallesIPERC_EvaluacionesRiesgo_EvaluacionResidualId",
                        column: x => x.EvaluacionResidualId,
                        principalTable: "EvaluacionesRiesgo",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_DetallesIPERC_MatricesIPERC_MatrizIPERCId",
                        column: x => x.MatrizIPERCId,
                        principalTable: "MatricesIPERC",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_DetallesIPERC_Peligros_PeligroId",
                        column: x => x.PeligroId,
                        principalTable: "Peligros",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_DetallesIPERC_Usuarios_ResponsableImplementacionId",
                        column: x => x.ResponsableImplementacionId,
                        principalTable: "Usuarios",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                })
                .Annotation("MySQL:Charset", "utf8mb4");

            migrationBuilder.CreateTable(
                name: "DetalleIPERCControles",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("MySQL:ValueGenerationStrategy", MySQLValueGenerationStrategy.IdentityColumn),
                    DetalleIPERCId = table.Column<long>(type: "bigint", nullable: false),
                    ControlId = table.Column<long>(type: "bigint", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_DetalleIPERCControles", x => x.Id);
                    table.ForeignKey(
                        name: "FK_DetalleIPERCControles_Controles_ControlId",
                        column: x => x.ControlId,
                        principalTable: "Controles",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_DetalleIPERCControles_DetallesIPERC_DetalleIPERCId",
                        column: x => x.DetalleIPERCId,
                        principalTable: "DetallesIPERC",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                })
                .Annotation("MySQL:Charset", "utf8mb4");

            migrationBuilder.CreateTable(
                name: "DetalleIPERCEPP",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("MySQL:ValueGenerationStrategy", MySQLValueGenerationStrategy.IdentityColumn),
                    DetalleIPERCId = table.Column<long>(type: "bigint", nullable: false),
                    EquipoProteccionId = table.Column<long>(type: "bigint", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_DetalleIPERCEPP", x => x.Id);
                    table.ForeignKey(
                        name: "FK_DetalleIPERCEPP_DetallesIPERC_DetalleIPERCId",
                        column: x => x.DetalleIPERCId,
                        principalTable: "DetallesIPERC",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_DetalleIPERCEPP_EquiposProteccion_EquipoProteccionId",
                        column: x => x.EquipoProteccionId,
                        principalTable: "EquiposProteccion",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                })
                .Annotation("MySQL:Charset", "utf8mb4");

            migrationBuilder.CreateTable(
                name: "SeguimientosIPERC",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("MySQL:ValueGenerationStrategy", MySQLValueGenerationStrategy.IdentityColumn),
                    DetalleIPERCId = table.Column<long>(type: "bigint", nullable: false),
                    FechaSeguimiento = table.Column<DateTime>(type: "datetime(6)", nullable: false),
                    UsuarioId = table.Column<long>(type: "bigint", nullable: false),
                    Descripcion = table.Column<string>(type: "varchar(3000)", maxLength: 3000, nullable: false),
                    PorcentajeAvance = table.Column<decimal>(type: "decimal(18,2)", nullable: false),
                    Verificado = table.Column<bool>(type: "tinyint(1)", nullable: false),
                    FechaVerificacion = table.Column<DateTime>(type: "datetime(6)", nullable: true),
                    Observaciones = table.Column<string>(type: "varchar(3000)", maxLength: 3000, nullable: true),
                    Archivo = table.Column<string>(type: "varchar(500)", maxLength: 500, nullable: true),
                    NombreArchivo = table.Column<string>(type: "varchar(250)", maxLength: 250, nullable: true),
                    TipoArchivo = table.Column<string>(type: "varchar(100)", maxLength: 100, nullable: true),
                    Estado = table.Column<bool>(type: "tinyint(1)", nullable: false),
                    FechaRegistro = table.Column<DateTime>(type: "datetime(6)", nullable: false),
                    FechaActualizacion = table.Column<DateTime>(type: "datetime(6)", nullable: true),
                    UsuarioRegistroId = table.Column<long>(type: "bigint", nullable: false),
                    UsuarioActualizacionId = table.Column<long>(type: "bigint", nullable: true),
                    EsGlobal = table.Column<bool>(type: "tinyint(1)", nullable: false),
                    ColegioId = table.Column<long>(type: "bigint", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SeguimientosIPERC", x => x.Id);
                    table.ForeignKey(
                        name: "FK_SeguimientosIPERC_DetallesIPERC_DetalleIPERCId",
                        column: x => x.DetalleIPERCId,
                        principalTable: "DetallesIPERC",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_SeguimientosIPERC_Usuarios_UsuarioId",
                        column: x => x.UsuarioId,
                        principalTable: "Usuarios",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                })
                .Annotation("MySQL:Charset", "utf8mb4");

            migrationBuilder.CreateIndex(
                name: "IX_Actividades_Estado",
                table: "Actividades",
                column: "Estado");

            migrationBuilder.CreateIndex(
                name: "IX_Actividades_FechaRegistro",
                table: "Actividades",
                column: "FechaRegistro");

            migrationBuilder.CreateIndex(
                name: "IX_Actividades_InstitucionId",
                table: "Actividades",
                column: "InstitucionId");

            migrationBuilder.CreateIndex(
                name: "IX_Actividades_ProcesoId",
                table: "Actividades",
                column: "ProcesoId");

            migrationBuilder.CreateIndex(
                name: "IX_Areas_Estado",
                table: "Areas",
                column: "Estado");

            migrationBuilder.CreateIndex(
                name: "IX_Areas_FechaRegistro",
                table: "Areas",
                column: "FechaRegistro");

            migrationBuilder.CreateIndex(
                name: "IX_Areas_InstitucionId",
                table: "Areas",
                column: "InstitucionId");

            migrationBuilder.CreateIndex(
                name: "IX_CategoriasPeligro_Codigo",
                table: "CategoriasPeligro",
                column: "Codigo",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_CategoriasPeligro_Nombre",
                table: "CategoriasPeligro",
                column: "Nombre");

            migrationBuilder.CreateIndex(
                name: "IX_ClasificacionesControl_Codigo",
                table: "ClasificacionesControl",
                column: "Codigo",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_ClasificacionesControl_Estado",
                table: "ClasificacionesControl",
                column: "Estado");

            migrationBuilder.CreateIndex(
                name: "IX_ClasificacionesControl_FechaRegistro",
                table: "ClasificacionesControl",
                column: "FechaRegistro");

            migrationBuilder.CreateIndex(
                name: "IX_ClasificacionesControl_Nombre",
                table: "ClasificacionesControl",
                column: "Nombre");

            migrationBuilder.CreateIndex(
                name: "IX_Consecuencias_Codigo",
                table: "Consecuencias",
                column: "Codigo",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Consecuencias_Estado",
                table: "Consecuencias",
                column: "Estado");

            migrationBuilder.CreateIndex(
                name: "IX_Consecuencias_FechaRegistro",
                table: "Consecuencias",
                column: "FechaRegistro");

            migrationBuilder.CreateIndex(
                name: "IX_Consecuencias_Nombre",
                table: "Consecuencias",
                column: "Nombre");

            migrationBuilder.CreateIndex(
                name: "IX_Controles_ClasificacionControlId",
                table: "Controles",
                column: "ClasificacionControlId");

            migrationBuilder.CreateIndex(
                name: "IX_Controles_Codigo",
                table: "Controles",
                column: "Codigo",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Controles_ColegioId",
                table: "Controles",
                column: "ColegioId");

            migrationBuilder.CreateIndex(
                name: "IX_Controles_Estado",
                table: "Controles",
                column: "Estado");

            migrationBuilder.CreateIndex(
                name: "IX_Controles_FechaRegistro",
                table: "Controles",
                column: "FechaRegistro");

            migrationBuilder.CreateIndex(
                name: "IX_Controles_Nombre",
                table: "Controles",
                column: "Nombre");

            migrationBuilder.CreateIndex(
                name: "IX_DetalleIPERCControles_ControlId",
                table: "DetalleIPERCControles",
                column: "ControlId");

            migrationBuilder.CreateIndex(
                name: "IX_DetalleIPERCControles_DetalleIPERCId",
                table: "DetalleIPERCControles",
                column: "DetalleIPERCId");

            migrationBuilder.CreateIndex(
                name: "IX_DetalleIPERCEPP_DetalleIPERCId",
                table: "DetalleIPERCEPP",
                column: "DetalleIPERCId");

            migrationBuilder.CreateIndex(
                name: "IX_DetalleIPERCEPP_EquipoProteccionId",
                table: "DetalleIPERCEPP",
                column: "EquipoProteccionId");

            migrationBuilder.CreateIndex(
                name: "IX_DetallesIPERC_ConsecuenciaId",
                table: "DetallesIPERC",
                column: "ConsecuenciaId");

            migrationBuilder.CreateIndex(
                name: "IX_DetallesIPERC_Estado",
                table: "DetallesIPERC",
                column: "Estado");

            migrationBuilder.CreateIndex(
                name: "IX_DetallesIPERC_EvaluacionInicialId",
                table: "DetallesIPERC",
                column: "EvaluacionInicialId");

            migrationBuilder.CreateIndex(
                name: "IX_DetallesIPERC_EvaluacionResidualId",
                table: "DetallesIPERC",
                column: "EvaluacionResidualId");

            migrationBuilder.CreateIndex(
                name: "IX_DetallesIPERC_FechaRegistro",
                table: "DetallesIPERC",
                column: "FechaRegistro");

            migrationBuilder.CreateIndex(
                name: "IX_DetallesIPERC_MatrizIPERCId",
                table: "DetallesIPERC",
                column: "MatrizIPERCId");

            migrationBuilder.CreateIndex(
                name: "IX_DetallesIPERC_PeligroId",
                table: "DetallesIPERC",
                column: "PeligroId");

            migrationBuilder.CreateIndex(
                name: "IX_DetallesIPERC_ResponsableImplementacionId",
                table: "DetallesIPERC",
                column: "ResponsableImplementacionId");

            migrationBuilder.CreateIndex(
                name: "IX_EquiposProteccion_Codigo",
                table: "EquiposProteccion",
                column: "Codigo",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_EquiposProteccion_ColegioId",
                table: "EquiposProteccion",
                column: "ColegioId");

            migrationBuilder.CreateIndex(
                name: "IX_EquiposProteccion_Estado",
                table: "EquiposProteccion",
                column: "Estado");

            migrationBuilder.CreateIndex(
                name: "IX_EquiposProteccion_FechaRegistro",
                table: "EquiposProteccion",
                column: "FechaRegistro");

            migrationBuilder.CreateIndex(
                name: "IX_EquiposProteccion_Nombre",
                table: "EquiposProteccion",
                column: "Nombre");

            migrationBuilder.CreateIndex(
                name: "IX_EquiposProteccion_TipoEquipoProteccionId",
                table: "EquiposProteccion",
                column: "TipoEquipoProteccionId");

            migrationBuilder.CreateIndex(
                name: "IX_EvaluacionesRiesgo_NivelRiesgoId",
                table: "EvaluacionesRiesgo",
                column: "NivelRiesgoId");

            migrationBuilder.CreateIndex(
                name: "IX_EvaluacionesRiesgo_ProbabilidadId",
                table: "EvaluacionesRiesgo",
                column: "ProbabilidadId");

            migrationBuilder.CreateIndex(
                name: "IX_EvaluacionesRiesgo_SeveridadId",
                table: "EvaluacionesRiesgo",
                column: "SeveridadId");

            migrationBuilder.CreateIndex(
                name: "IX_Instituciones_Codigo",
                table: "Instituciones",
                column: "Codigo",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Instituciones_Estado",
                table: "Instituciones",
                column: "Estado");

            migrationBuilder.CreateIndex(
                name: "IX_Instituciones_FechaRegistro",
                table: "Instituciones",
                column: "FechaRegistro");

            migrationBuilder.CreateIndex(
                name: "IX_Instituciones_Nombre",
                table: "Instituciones",
                column: "Nombre");

            migrationBuilder.CreateIndex(
                name: "IX_MatricesIPERC_ActividadId",
                table: "MatricesIPERC",
                column: "ActividadId");

            migrationBuilder.CreateIndex(
                name: "IX_MatricesIPERC_AprobadorId",
                table: "MatricesIPERC",
                column: "AprobadorId");

            migrationBuilder.CreateIndex(
                name: "IX_MatricesIPERC_AreaId",
                table: "MatricesIPERC",
                column: "AreaId");

            migrationBuilder.CreateIndex(
                name: "IX_MatricesIPERC_InstitucionId",
                table: "MatricesIPERC",
                column: "InstitucionId");

            migrationBuilder.CreateIndex(
                name: "IX_MatricesIPERC_ProcesoId",
                table: "MatricesIPERC",
                column: "ProcesoId");

            migrationBuilder.CreateIndex(
                name: "IX_MatricesIPERC_PuestoTrabajoId",
                table: "MatricesIPERC",
                column: "PuestoTrabajoId");

            migrationBuilder.CreateIndex(
                name: "IX_MatricesIPERC_ResponsableId",
                table: "MatricesIPERC",
                column: "ResponsableId");

            migrationBuilder.CreateIndex(
                name: "IX_MatricesIPERC_SedeId",
                table: "MatricesIPERC",
                column: "SedeId");

            migrationBuilder.CreateIndex(
                name: "IX_Peligros_Codigo",
                table: "Peligros",
                column: "Codigo",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Peligros_Estado",
                table: "Peligros",
                column: "Estado");

            migrationBuilder.CreateIndex(
                name: "IX_Peligros_FechaRegistro",
                table: "Peligros",
                column: "FechaRegistro");

            migrationBuilder.CreateIndex(
                name: "IX_Peligros_Nombre",
                table: "Peligros",
                column: "Nombre");

            migrationBuilder.CreateIndex(
                name: "IX_Peligros_TipoPeligroId",
                table: "Peligros",
                column: "TipoPeligroId");

            migrationBuilder.CreateIndex(
                name: "IX_PeligrosConsecuencias_ConsecuenciaId",
                table: "PeligrosConsecuencias",
                column: "ConsecuenciaId");

            migrationBuilder.CreateIndex(
                name: "IX_PeligrosConsecuencias_Estado",
                table: "PeligrosConsecuencias",
                column: "Estado");

            migrationBuilder.CreateIndex(
                name: "IX_PeligrosConsecuencias_FechaRegistro",
                table: "PeligrosConsecuencias",
                column: "FechaRegistro");

            migrationBuilder.CreateIndex(
                name: "IX_PeligrosConsecuencias_PeligroId_ConsecuenciaId",
                table: "PeligrosConsecuencias",
                columns: new[] { "PeligroId", "ConsecuenciaId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_PeligrosControles_ControlId",
                table: "PeligrosControles",
                column: "ControlId");

            migrationBuilder.CreateIndex(
                name: "IX_PeligrosControles_Estado",
                table: "PeligrosControles",
                column: "Estado");

            migrationBuilder.CreateIndex(
                name: "IX_PeligrosControles_FechaRegistro",
                table: "PeligrosControles",
                column: "FechaRegistro");

            migrationBuilder.CreateIndex(
                name: "IX_PeligrosControles_PeligroId_ControlId",
                table: "PeligrosControles",
                columns: new[] { "PeligroId", "ControlId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_PeligrosEquiposProteccion_EquipoProteccionId",
                table: "PeligrosEquiposProteccion",
                column: "EquipoProteccionId");

            migrationBuilder.CreateIndex(
                name: "IX_PeligrosEquiposProteccion_Estado",
                table: "PeligrosEquiposProteccion",
                column: "Estado");

            migrationBuilder.CreateIndex(
                name: "IX_PeligrosEquiposProteccion_FechaRegistro",
                table: "PeligrosEquiposProteccion",
                column: "FechaRegistro");

            migrationBuilder.CreateIndex(
                name: "IX_PeligrosEquiposProteccion_PeligroId_EquipoProteccionId",
                table: "PeligrosEquiposProteccion",
                columns: new[] { "PeligroId", "EquipoProteccionId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Procesos_AreaId",
                table: "Procesos",
                column: "AreaId");

            migrationBuilder.CreateIndex(
                name: "IX_Procesos_Estado",
                table: "Procesos",
                column: "Estado");

            migrationBuilder.CreateIndex(
                name: "IX_Procesos_FechaRegistro",
                table: "Procesos",
                column: "FechaRegistro");

            migrationBuilder.CreateIndex(
                name: "IX_Procesos_InstitucionId",
                table: "Procesos",
                column: "InstitucionId");

            migrationBuilder.CreateIndex(
                name: "IX_PuestosTrabajo_AreaId",
                table: "PuestosTrabajo",
                column: "AreaId");

            migrationBuilder.CreateIndex(
                name: "IX_PuestosTrabajo_Estado",
                table: "PuestosTrabajo",
                column: "Estado");

            migrationBuilder.CreateIndex(
                name: "IX_PuestosTrabajo_FechaRegistro",
                table: "PuestosTrabajo",
                column: "FechaRegistro");

            migrationBuilder.CreateIndex(
                name: "IX_PuestosTrabajo_InstitucionId",
                table: "PuestosTrabajo",
                column: "InstitucionId");

            migrationBuilder.CreateIndex(
                name: "IX_Sedes_Estado",
                table: "Sedes",
                column: "Estado");

            migrationBuilder.CreateIndex(
                name: "IX_Sedes_FechaRegistro",
                table: "Sedes",
                column: "FechaRegistro");

            migrationBuilder.CreateIndex(
                name: "IX_Sedes_InstitucionId",
                table: "Sedes",
                column: "InstitucionId");

            migrationBuilder.CreateIndex(
                name: "IX_SeguimientosIPERC_DetalleIPERCId",
                table: "SeguimientosIPERC",
                column: "DetalleIPERCId");

            migrationBuilder.CreateIndex(
                name: "IX_SeguimientosIPERC_UsuarioId",
                table: "SeguimientosIPERC",
                column: "UsuarioId");

            migrationBuilder.CreateIndex(
                name: "IX_TiposEquipoProteccion_Codigo",
                table: "TiposEquipoProteccion",
                column: "Codigo",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_TiposEquipoProteccion_ColegioId",
                table: "TiposEquipoProteccion",
                column: "ColegioId");

            migrationBuilder.CreateIndex(
                name: "IX_TiposEquipoProteccion_Estado",
                table: "TiposEquipoProteccion",
                column: "Estado");

            migrationBuilder.CreateIndex(
                name: "IX_TiposEquipoProteccion_FechaRegistro",
                table: "TiposEquipoProteccion",
                column: "FechaRegistro");

            migrationBuilder.CreateIndex(
                name: "IX_TiposEquipoProteccion_Nombre",
                table: "TiposEquipoProteccion",
                column: "Nombre");

            migrationBuilder.CreateIndex(
                name: "IX_TiposPeligro_CategoriaPeligroId",
                table: "TiposPeligro",
                column: "CategoriaPeligroId");

            migrationBuilder.CreateIndex(
                name: "IX_TiposPeligro_Codigo",
                table: "TiposPeligro",
                column: "Codigo",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_TiposPeligro_Nombre",
                table: "TiposPeligro",
                column: "Nombre");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "DetalleIPERCControles");

            migrationBuilder.DropTable(
                name: "DetalleIPERCEPP");

            migrationBuilder.DropTable(
                name: "PeligrosConsecuencias");

            migrationBuilder.DropTable(
                name: "PeligrosControles");

            migrationBuilder.DropTable(
                name: "PeligrosEquiposProteccion");

            migrationBuilder.DropTable(
                name: "SeguimientosIPERC");

            migrationBuilder.DropTable(
                name: "Controles");

            migrationBuilder.DropTable(
                name: "EquiposProteccion");

            migrationBuilder.DropTable(
                name: "DetallesIPERC");

            migrationBuilder.DropTable(
                name: "ClasificacionesControl");

            migrationBuilder.DropTable(
                name: "TiposEquipoProteccion");

            migrationBuilder.DropTable(
                name: "Consecuencias");

            migrationBuilder.DropTable(
                name: "EvaluacionesRiesgo");

            migrationBuilder.DropTable(
                name: "MatricesIPERC");

            migrationBuilder.DropTable(
                name: "Peligros");

            migrationBuilder.DropTable(
                name: "NivelesRiesgo");

            migrationBuilder.DropTable(
                name: "Probabilidades");

            migrationBuilder.DropTable(
                name: "Severidades");

            migrationBuilder.DropTable(
                name: "Actividades");

            migrationBuilder.DropTable(
                name: "PuestosTrabajo");

            migrationBuilder.DropTable(
                name: "Sedes");

            migrationBuilder.DropTable(
                name: "Usuarios");

            migrationBuilder.DropTable(
                name: "TiposPeligro");

            migrationBuilder.DropTable(
                name: "Procesos");

            migrationBuilder.DropTable(
                name: "CategoriasPeligro");

            migrationBuilder.DropTable(
                name: "Areas");

            migrationBuilder.DropTable(
                name: "Instituciones");
        }
    }
}
