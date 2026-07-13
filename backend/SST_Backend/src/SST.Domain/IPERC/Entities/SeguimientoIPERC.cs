using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using SST.Domain.Common;
using SST.Domain.Security.Entities;

namespace SST.Domain.IPERC.Entities;

/// <summary>
/// Representa el seguimiento realizado a una medida
/// de control dentro de un detalle IPERC.
/// Permite registrar auditorías, avances,
/// evidencias y verificaciones.
/// </summary>
[Table("SeguimientosIPERC")]
public class SeguimientoIPERC : BaseAuditableEntity
{
    #region Relación Principal

    /// <summary>
    /// Detalle IPERC al que pertenece.
    /// </summary>
    [Required]
    public long DetalleIPERCId { get; set; }

    #endregion

    #region Información

    /// <summary>
    /// Fecha del seguimiento.
    /// </summary>
    [Required]
    public DateTime FechaSeguimiento { get; set; }
        = DateTime.UtcNow;

    /// <summary>
    /// Usuario responsable del seguimiento.
    /// </summary>
    [Required]
    public long UsuarioId { get; set; }

    /// <summary>
    /// Descripción del avance.
    /// </summary>
    [Required]
    [MaxLength(3000)]
    public string Descripcion { get; set; } = string.Empty;

    /// <summary>
    /// Porcentaje de avance.
    /// </summary>
    [Range(0, 100)]
    public decimal PorcentajeAvance { get; set; }

    /// <summary>
    /// Indica si el seguimiento fue verificado.
    /// </summary>
    public bool Verificado { get; set; }

    /// <summary>
    /// Fecha de verificación.
    /// </summary>
    public DateTime? FechaVerificacion { get; set; }

    /// <summary>
    /// Observaciones del auditor.
    /// </summary>
    [MaxLength(3000)]
    public string? Observaciones { get; set; }

    #endregion

    #region Evidencias

    /// <summary>
    /// Ruta del archivo.
    /// </summary>
    [MaxLength(500)]
    public string? Archivo { get; set; }

    /// <summary>
    /// Nombre del archivo.
    /// </summary>
    [MaxLength(250)]
    public string? NombreArchivo { get; set; }

    /// <summary>
    /// Tipo MIME.
    /// </summary>
    [MaxLength(100)]
    public string? TipoArchivo { get; set; }

    #endregion

    #region Navegación

    [ForeignKey(nameof(DetalleIPERCId))]
    public virtual DetalleIPERC DetalleIPERC { get; set; } = null!;

    [ForeignKey(nameof(UsuarioId))]
    public virtual Usuario Usuario { get; set; } = null!;

    #endregion

    #region Métodos de Dominio

    /// <summary>
    /// Marca el seguimiento como verificado.
    /// </summary>
    public void Verificar()
    {
        Verificado = true;
        FechaVerificacion = DateTime.UtcNow;
    }

    /// <summary>
    /// Actualiza el porcentaje de avance.
    /// </summary>
    /// <param name="avance">Valor entre 0 y 100.</param>
    public void ActualizarAvance(decimal avance)
    {
        if (avance < 0 || avance > 100)
            throw new ArgumentOutOfRangeException(nameof(avance));

        PorcentajeAvance = avance;
    }

    #endregion
}