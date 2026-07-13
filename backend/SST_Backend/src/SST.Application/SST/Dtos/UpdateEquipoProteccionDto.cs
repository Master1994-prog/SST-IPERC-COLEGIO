using System.ComponentModel.DataAnnotations;

namespace SST.Application.SST.Dtos;

/// <summary>
/// DTO utilizado para actualizar un Equipo de Protección Personal.
/// No contiene Id porque el Id llega desde la ruta.
/// </summary>
public class UpdateEquipoProteccionDto
{
    /// <summary>
    /// Código actualizado del EPP.
    /// </summary>
    [Required]
    [MaxLength(20)]
    public string Codigo { get; set; } = string.Empty;

    /// <summary>
    /// Nombre actualizado del equipo.
    /// </summary>
    [Required]
    [MaxLength(200)]
    public string Nombre { get; set; } = string.Empty;

    /// <summary>
    /// Descripción actualizada del equipo.
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
    /// Estado del registro.
    /// </summary>
    public bool Activo { get; set; }

    /// <summary>
    /// Indica si pertenece al catálogo global.
    /// </summary>
    public bool EsGlobal { get; set; }

    /// <summary>
    /// Colegio propietario.
    /// </summary>
    public long? ColegioId { get; set; }
}
