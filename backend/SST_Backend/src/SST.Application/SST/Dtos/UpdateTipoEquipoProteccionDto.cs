using System.ComponentModel.DataAnnotations;

namespace SST.Application.SST.Dtos;

/// <summary>
/// DTO utilizado para actualizar un tipo de Equipo de Protección Personal.
/// No contiene Id porque el Id llega desde la ruta.
/// </summary>
public class UpdateTipoEquipoProteccionDto
{
    [Required]
    [MaxLength(20)]
    public string Codigo { get; set; } = string.Empty;

    [Required]
    [MaxLength(150)]
    public string Nombre { get; set; } = string.Empty;

    [MaxLength(1000)]
    public string? Descripcion { get; set; }

    public int Orden { get; set; }

    public bool Activo { get; set; }

    public bool EsGlobal { get; set; }

    public long? ColegioId { get; set; }
}
