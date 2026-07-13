using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using SST.Domain.Common;

namespace SST.Domain.IPERC.Entities;

/// <summary>
/// Representa un mapa de riesgo asociado a una Matriz IPERC.
/// El mapa de riesgo permite ubicar visualmente los peligros identificados
/// dentro de un área, ambiente o zona del colegio.
/// </summary>
[Table("MapasRiesgo")]
public class MapaRiesgo : BaseAuditableEntity
{
    #region Información General

    /// <summary>
    /// Código único del mapa de riesgo.
    /// Ejemplo: MAP-2026-0001.
    /// </summary>
    [Required]
    [MaxLength(30)]
    public string Codigo { get; set; } = string.Empty;

    /// <summary>
    /// Nombre del mapa de riesgo.
    /// </summary>
    [Required]
    [MaxLength(250)]
    public string Nombre { get; set; } = string.Empty;

    /// <summary>
    /// Descripción del mapa de riesgo.
    /// </summary>
    [MaxLength(1500)]
    public string? Descripcion { get; set; }

    /// <summary>
    /// Ubicación o ambiente representado en el mapa.
    /// Ejemplo: Área administrativa, laboratorio, patio, biblioteca.
    /// </summary>
    [MaxLength(300)]
    public string? Ubicacion { get; set; }

    #endregion

    #region Archivo / Imagen

    /// <summary>
    /// Ruta o nombre del archivo del mapa de riesgo.
    /// Puede ser una imagen, PDF o plano.
    /// </summary>
    [MaxLength(500)]
    public string? ArchivoUrl { get; set; }

    /// <summary>
    /// Tipo de archivo.
    /// Ejemplo: image/png, image/jpeg, application/pdf.
    /// </summary>
    [MaxLength(100)]
    public string? TipoArchivo { get; set; }

    #endregion

    #region Fechas y Estado

    /// <summary>
    /// Fecha de elaboración del mapa.
    /// </summary>
    public DateTime FechaElaboracion { get; set; }

    /// <summary>
    /// Fecha de revisión del mapa.
    /// </summary>
    public DateTime? FechaRevision { get; set; }

    /// <summary>
    /// Versión del mapa de riesgo.
    /// </summary>
    public int Version { get; set; } = 1;

    /// <summary>
    /// Estado del mapa.
    /// Ejemplo: Borrador, Vigente, Actualizado, Cerrado.
    /// </summary>
    [Required]
    [MaxLength(30)]
    public string EstadoMapa { get; set; } = "Borrador";

    /// <summary>
    /// Estado del registro.
    /// </summary>
    public bool Activo { get; set; } = true;

    #endregion

    #region Relación IPERC

    /// <summary>
    /// Matriz IPERC relacionada con el mapa de riesgo.
    /// </summary>
    [Required]
    public long MatrizIPERCId { get; set; }

    [ForeignKey(nameof(MatrizIPERCId))]
    public virtual MatrizIPERC MatrizIPERC { get; set; } = null!;

    #endregion
}
