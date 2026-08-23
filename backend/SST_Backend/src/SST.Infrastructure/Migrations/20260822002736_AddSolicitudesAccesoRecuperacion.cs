using System;
using Microsoft.EntityFrameworkCore.Migrations;
using MySql.EntityFrameworkCore.Metadata;

#nullable disable

namespace SST.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddSolicitudesAccesoRecuperacion : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "solicitudesacceso",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("MySQL:ValueGenerationStrategy", MySQLValueGenerationStrategy.IdentityColumn),
                    Nombres = table.Column<string>(type: "varchar(150)", maxLength: 150, nullable: false),
                    Apellidos = table.Column<string>(type: "varchar(150)", maxLength: 150, nullable: false),
                    Correo = table.Column<string>(type: "varchar(200)", maxLength: 200, nullable: false),
                    Institucion = table.Column<string>(type: "varchar(200)", maxLength: 200, nullable: false),
                    Cargo = table.Column<string>(type: "varchar(150)", maxLength: 150, nullable: true),
                    Motivo = table.Column<string>(type: "varchar(1000)", maxLength: 1000, nullable: true),
                    EstadoSolicitud = table.Column<string>(type: "varchar(30)", maxLength: 30, nullable: false),
                    FechaSolicitud = table.Column<DateTime>(type: "datetime(6)", nullable: false),
                    FechaAtencion = table.Column<DateTime>(type: "datetime(6)", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_solicitudesacceso", x => x.Id);
                })
                .Annotation("MySQL:Charset", "utf8mb4");

            migrationBuilder.CreateTable(
                name: "solicitudesrecuperacionpassword",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("MySQL:ValueGenerationStrategy", MySQLValueGenerationStrategy.IdentityColumn),
                    UsuarioId = table.Column<long>(type: "bigint", nullable: true),
                    Identificador = table.Column<string>(type: "varchar(200)", maxLength: 200, nullable: false),
                    Correo = table.Column<string>(type: "varchar(200)", maxLength: 200, nullable: true),
                    EstadoSolicitud = table.Column<string>(type: "varchar(30)", maxLength: 30, nullable: false),
                    FechaSolicitud = table.Column<DateTime>(type: "datetime(6)", nullable: false),
                    FechaAtencion = table.Column<DateTime>(type: "datetime(6)", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_solicitudesrecuperacionpassword", x => x.Id);
                })
                .Annotation("MySQL:Charset", "utf8mb4");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "solicitudesacceso");

            migrationBuilder.DropTable(
                name: "solicitudesrecuperacionpassword");
        }
    }
}
