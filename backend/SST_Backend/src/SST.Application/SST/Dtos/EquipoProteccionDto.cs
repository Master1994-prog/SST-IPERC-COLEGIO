namespace SST.Application.SST.Dtos;

/// <summary>
/// DTO utilizado para mostrar la información de un Equipo de Protección Personal.
/// </summary>
public class EquipoProteccionDto
{
    /// <summary>
    /// Identificador único del EPP.
    /// </summary>
    public long Id { get; set; }

    /// <summary>
    /// Código único del EPP.
    /// </summary>
    public string Codigo { get; set; } = string.Empty;

    /// <summary>
    /// Nombre del equipo de protección.
    /// </summary>
    public string Nombre { get; set; } = string.Empty;

    /// <summary>
    /// Descripción del equipo.
    /// </summary>
    public string? Descripcion { get; set; }

    /// <summary>
    /// Id del tipo de equipo de protección.
    /// </summary>
    public long TipoEquipoProteccionId { get; set; }

    /// <summary>
    /// Nombre del tipo de equipo de protección.
    /// </summary>
    public string? TipoEquipoProteccionNombre { get; set; }

    /// <summary>
    /// Marca del equipo.
    /// </summary>
    public string? Marca { get; set; }

    /// <summary>
    /// Modelo del equipo.
    /// </summary>
    public string? Modelo { get; set; }

    /// <summary>
    /// Norma técnica aplicable.
    /// </summary>
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
    /// Colegio propietario del registro.
    /// </summary>
    public long? ColegioId { get; set; }
}
