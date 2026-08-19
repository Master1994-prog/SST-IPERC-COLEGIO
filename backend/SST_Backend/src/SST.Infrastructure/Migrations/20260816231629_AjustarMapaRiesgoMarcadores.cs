using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SST.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AjustarMapaRiesgoMarcadores : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "MarcadoresJson",
                table: "MapasRiesgo",
                type: "longtext",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "MarcadoresJson",
                table: "MapasRiesgo");
        }
    }
}
