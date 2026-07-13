using System.ComponentModel.DataAnnotations;

namespace SST.Application.SST.Dtos;

public class UpdateCategoriaPeligroDto
{
    [Required]
    [MaxLength(150)]
    public string Nombre { get; set; } = string.Empty;

    [MaxLength(1000)]
    public string? Descripcion { get; set; }

    [MaxLength(10)]
    public string? Color { get; set; }

    [MaxLength(100)]
    public string? Icono { get; set; }

    public int Orden { get; set; }

    public bool Activo { get; set; }
}
