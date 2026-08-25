using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SST.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AgregarContadorSesionesPassword : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "SesionesDesdeCambioPassword",
                table: "Usuarios",
                type: "int",
                nullable: false,
                defaultValue: 0);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "SesionesDesdeCambioPassword",
                table: "Usuarios");
        }
    }
}
