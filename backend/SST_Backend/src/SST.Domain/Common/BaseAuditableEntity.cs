namespace SST.Domain.Common;

/// <summary>
/// Clase base para las entidades auditables del sistema.
/// Proporciona información de auditoría y soporte para
/// catálogos globales y específicos por colegio.
/// </summary>
public abstract class BaseAuditableEntity : BaseEntity
{
    #region Estado

    /// <summary>
    /// Indica si el registro está activo.
    /// </summary>
    public bool Estado { get; set; } = true;

    #endregion

    #region Auditoría

    /// <summary>
    /// Fecha de creación del registro.
    /// </summary>
    public DateTime FechaRegistro { get; set; } = DateTime.UtcNow;

    /// <summary>
    /// Fecha de la última actualización.
    /// </summary>
    public DateTime? FechaActualizacion { get; set; }

    /// <summary>
    /// Usuario que creó el registro.
    /// </summary>
    public long UsuarioRegistroId { get; set; }

    /// <summary>
    /// Usuario que realizó la última actualización.
    /// </summary>
    public long? UsuarioActualizacionId { get; set; }

    #endregion

    #region Multicolegio

    /// <summary>
    /// Indica si el registro pertenece al catálogo global.
    /// Si es false, pertenece a un colegio específico.
    /// </summary>
    public bool EsGlobal { get; set; } = true;

    /// <summary>
    /// Colegio propietario del registro.
    /// Si es null, el registro pertenece al catálogo general.
    /// </summary>
    public long? ColegioId { get; set; }

    #endregion
}
