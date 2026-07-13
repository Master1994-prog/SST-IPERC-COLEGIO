using System.ComponentModel.DataAnnotations;

namespace SST.Application.SST.Dtos;

/// <summary>
/// DTO utilizado para registrar un nuevo tipo de Equipo de Protección Personal.
/// </summary>
public class CreateTipoEquipoProteccionDto
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

    public bool EsGlobal { get; set; } = true;

    public long? ColegioId { get; set; }
}
