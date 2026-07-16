using System;
using Microsoft.EntityFrameworkCore.Migrations;
using MySql.EntityFrameworkCore.Metadata;

#nullable disable

namespace SST.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AgregarRolesSeguridad : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Roles",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("MySQL:ValueGenerationStrategy", MySQLValueGenerationStrategy.IdentityColumn),
                    Codigo = table.Column<string>(type: "varchar(50)", maxLength: 50, nullable: false),
                    Nombre = table.Column<string>(type: "varchar(100)", maxLength: 100, nullable: false),
                    Descripcion = table.Column<string>(type: "varchar(300)", maxLength: 300, nullable: true),
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
                    table.PrimaryKey("PK_Roles", x => x.Id);
                })
                .Annotation("MySQL:Charset", "utf8mb4");

            migrationBuilder.CreateTable(
                name: "UsuariosRoles",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("MySQL:ValueGenerationStrategy", MySQLValueGenerationStrategy.IdentityColumn),
                    UsuarioId = table.Column<long>(type: "bigint", nullable: false),
                    RolId = table.Column<long>(type: "bigint", nullable: false),
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
                    table.PrimaryKey("PK_UsuariosRoles", x => x.Id);
                    table.ForeignKey(
                        name: "FK_UsuariosRoles_Roles_RolId",
                        column: x => x.RolId,
                        principalTable: "Roles",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_UsuariosRoles_Usuarios_UsuarioId",
                        column: x => x.UsuarioId,
                        principalTable: "Usuarios",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                })
                .Annotation("MySQL:Charset", "utf8mb4");

            migrationBuilder.CreateIndex(
                name: "IX_Usuarios_Correo",
                table: "Usuarios",
                column: "Correo",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Usuarios_NombreUsuario",
                table: "Usuarios",
                column: "NombreUsuario",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Roles_Codigo",
                table: "Roles",
                column: "Codigo",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Roles_Nombre",
                table: "Roles",
                column: "Nombre",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_UsuariosRoles_RolId",
                table: "UsuariosRoles",
                column: "RolId");

            migrationBuilder.CreateIndex(
                name: "IX_UsuariosRoles_UsuarioId_RolId",
                table: "UsuariosRoles",
                columns: new[] { "UsuarioId", "RolId" },
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "UsuariosRoles");

            migrationBuilder.DropTable(
                name: "Roles");

            migrationBuilder.DropIndex(
                name: "IX_Usuarios_Correo",
                table: "Usuarios");

            migrationBuilder.DropIndex(
                name: "IX_Usuarios_NombreUsuario",
                table: "Usuarios");
        }
    }
}
