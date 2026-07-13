using System.ComponentModel.DataAnnotations;

namespace SST.Application.SST.Dtos;

/// <summary>
/// DTO utilizado para registrar un nuevo Equipo de Protección Personal.
/// </summary>
public class CreateEquipoProteccionDto
{
    /// <summary>
    /// Código único del EPP.
    /// </summary>
    [Required]
    [MaxLength(20)]
    public string Codigo { get; set; } = string.Empty;

    /// <summary>
    /// Nombre del equipo.
    /// </summary>
    [Required]
    [MaxLength(200)]
    public string Nombre { get; set; } = string.Empty;

    /// <summary>
    /// Descripción del equipo.
    /// </summary>
    [MaxLength(2000)]
    public string? Descripcion { get; set; }

    /// <summary>
    /// Id del tipo de Equipo de Protección Personal.
    /// </summary>
    [Required]
    public long TipoEquipoProteccionId { get; set; }

    /// <summary>
    /// Marca del equipo.
    /// </summary>
    [MaxLength(100)]
    public string? Marca { get; set; }

    /// <summary>
    /// Modelo del equipo.
    /// </summary>
    [MaxLength(100)]
    public string? Modelo { get; set; }

    /// <summary>
    /// Norma técnica aplicable.
    /// </summary>
    [MaxLength(300)]
    public string? NormaTecnica { get; set; }

    /// <summary>
    /// Vida útil estimada en meses.
    /// </summary>
    public int? VidaUtilMeses { get; set; }

    /// <summary>
    /// Indica si requiere capacitación.
    /// </summary>
    public bool RequiereCapacitacion { get; set; }

    /// <summary>
    /// Indica si requiere mantenimiento.
    /// </summary>
    public bool RequiereMantenimiento { get; set; }

    /// <summary>
    /// Indica si pertenece al catálogo global.
    /// </summary>
    public bool EsGlobal { get; set; } = true;

    /// <summary>
    /// Colegio propietario. Si es null, pertenece al catálogo general.
    /// </summary>
    public long? ColegioId { get; set; }
}
