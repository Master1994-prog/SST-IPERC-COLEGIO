using System;
using Microsoft.EntityFrameworkCore.Migrations;
using MySql.EntityFrameworkCore.Metadata;

#nullable disable

namespace SST.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddMapaRiesgo : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "MapasRiesgo",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("MySQL:ValueGenerationStrategy", MySQLValueGenerationStrategy.IdentityColumn),
                    Codigo = table.Column<string>(type: "varchar(30)", maxLength: 30, nullable: false),
                    Nombre = table.Column<string>(type: "varchar(250)", maxLength: 250, nullable: false),
                    Descripcion = table.Column<string>(type: "varchar(1500)", maxLength: 1500, nullable: true),
                    Ubicacion = table.Column<string>(type: "varchar(300)", maxLength: 300, nullable: true),
                    ArchivoUrl = table.Column<string>(type: "varchar(500)", maxLength: 500, nullable: true),
                    TipoArchivo = table.Column<string>(type: "varchar(100)", maxLength: 100, nullable: true),
                    FechaElaboracion = table.Column<DateTime>(type: "datetime(6)", nullable: false),
                    FechaRevision = table.Column<DateTime>(type: "datetime(6)", nullable: true),
                    Version = table.Column<int>(type: "int", nullable: false),
                    EstadoMapa = table.Column<string>(type: "varchar(30)", maxLength: 30, nullable: false),
                    Activo = table.Column<bool>(type: "tinyint(1)", nullable: false),
                    MatrizIPERCId = table.Column<long>(type: "bigint", nullable: false),
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
                    table.PrimaryKey("PK_MapasRiesgo", x => x.Id);
                    table.ForeignKey(
                        name: "FK_MapasRiesgo_MatricesIPERC_MatrizIPERCId",
                        column: x => x.MatrizIPERCId,
                        principalTable: "MatricesIPERC",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                })
                .Annotation("MySQL:Charset", "utf8mb4");

            migrationBuilder.CreateIndex(
                name: "IX_MapasRiesgo_MatrizIPERCId",
                table: "MapasRiesgo",
                column: "MatrizIPERCId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "MapasRiesgo");
        }
    }
}
