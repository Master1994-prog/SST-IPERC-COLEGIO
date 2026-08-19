using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using SST.Domain.Common;

namespace SST.Domain.IPERC.Entities;

/// <summary>
/// Representa un mapa de riesgo asociado a una Matriz IPERC.
/// El mapa permite ubicar visualmente los peligros identificados
/// dentro de un área, ambiente o zona.
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
    /// Descripción del mapa.
    /// </summary>
    [MaxLength(1500)]
    public string? Descripcion { get; set; }

    /// <summary>
    /// Ubicación o ambiente representado.
    /// </summary>
    [MaxLength(300)]
    public string? Ubicacion { get; set; }

    #endregion

    #region Archivo / Imagen

    /// <summary>
    /// URL relativa o absoluta del plano almacenado en el servidor.
    /// Ejemplo:
    /// /uploads/mapas-riesgo/9aa7....png
    /// </summary>
    [MaxLength(500)]
    public string? ArchivoUrl { get; set; }

    /// <summary>
    /// Tipo MIME del archivo.
    /// Ejemplo: image/png, image/jpeg.
    /// </summary>
    [MaxLength(100)]
    public string? TipoArchivo { get; set; }

    /// <summary>
    /// Coordenadas normalizadas de los marcadores del plano.
    ///
    /// Ejemplo:
    /// {
    ///   "Administración":{"x":0.25,"y":0.40},
    ///   "Laboratorio":{"x":0.72,"y":0.61}
    /// }
    ///
    /// Se almacena como LONGTEXT para permitir que el mapa
    /// crezca sin limitar la cantidad de ambientes.
    /// </summary>
    [Column(TypeName = "longtext")]
    public string? MarcadoresJson { get; set; }

    #endregion

    #region Fechas y Estado

    public DateTime FechaElaboracion { get; set; }

    public DateTime? FechaRevision { get; set; }

    public int Version { get; set; } = 1;

    [Required]
    [MaxLength(30)]
    public string EstadoMapa { get; set; } = "Borrador";

    public bool Activo { get; set; } = true;

    #endregion

    #region Relación IPERC

    [Required]
    public long MatrizIPERCId { get; set; }

    [ForeignKey(nameof(MatrizIPERCId))]
    public virtual MatrizIPERC MatrizIPERC { get; set; } = null!;

    #endregion
}
