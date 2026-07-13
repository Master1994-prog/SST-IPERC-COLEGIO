using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using SST.Domain.Common;
using SST.Domain.IPERC.Entities;

namespace SST.Domain.SST.Entities;

/// <summary>
/// Representa un Equipo de Protección Personal (EPP)
/// utilizado para controlar la exposición a un peligro.
/// </summary>
[Table("EquiposProteccion")]
public class EquipoProteccion : BaseAuditableEntity
{
    #region Información General

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

    #endregion

    #region Clasificación

    /// <summary>
    /// Tipo de Equipo de Protección Personal.
    /// </summary>
    [Required]
    public long TipoEquipoProteccionId { get; set; }

    #endregion

    #region Especificaciones

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
    /// Ejemplo:
    /// ANSI
    /// NIOSH
    /// EN166
    /// ISO
    /// </summary>
    [MaxLength(300)]
    public string? NormaTecnica { get; set; }

    /// <summary>
    /// Vida útil estimada en meses.
    /// </summary>
    public int? VidaUtilMeses { get; set; }

    /// <summary>
    /// Indica si requiere capacitación para su uso.
    /// </summary>
    public bool RequiereCapacitacion { get; set; }

    /// <summary>
    /// Indica si requiere mantenimiento.
    /// </summary>
    public bool RequiereMantenimiento { get; set; }

    #endregion

    #region Gestión

    /// <summary>
    /// Estado del registro.
    /// </summary>
    public bool Activo { get; set; } = true;

    /// <summary>
    /// Indica si pertenece al catálogo global.
    /// </summary>
    public bool EsGlobal { get; set; } = true;

    /// <summary>
    /// Colegio propietario.
    /// Si es NULL el EPP pertenece al catálogo general.
    /// </summary>
    public long? ColegioId { get; set; }

    #endregion

    #region Navegación

    /// <summary>
    /// Tipo de EPP.
    /// </summary>
    [ForeignKey(nameof(TipoEquipoProteccionId))]
    public virtual TipoEquipoProteccion TipoEquipoProteccion { get; set; } = null!;

    /// <summary>
    /// Relación entre peligros y EPP.
    /// </summary>
    public virtual ICollection<PeligroEquipoProteccion> PeligroEquiposProteccion { get; set; }
        = new List<PeligroEquipoProteccion>();

    /// <summary>
    /// Relación entre Detalle IPERC y EPP utilizados.
    /// </summary>
    public virtual ICollection<DetalleIPERCEPP> DetalleIPERCEPPs { get; set; }
        = new List<DetalleIPERCEPP>();

    #endregion

    #region Métodos de Dominio

    /// <summary>
    /// Activa el equipo.
    /// </summary>
    public void Activar()
    {
        Activo = true;
    }

    /// <summary>
    /// Desactiva el equipo.
    /// </summary>
    public void Desactivar()
    {
        Activo = false;
    }

    /// <summary>
    /// Actualiza la descripción.
    /// </summary>
    public void ActualizarDescripcion(string? descripcion)
    {
        Descripcion = descripcion;
    }

    /// <summary>
    /// Actualiza la marca.
    /// </summary>
    public void ActualizarMarca(string? marca)
    {
        Marca = marca;
    }

    /// <summary>
    /// Actualiza el modelo.
    /// </summary>
    public void ActualizarModelo(string? modelo)
    {
        Modelo = modelo;
    }

    /// <summary>
    /// Actualiza la norma técnica.
    /// </summary>
    public void ActualizarNorma(string? norma)
    {
        NormaTecnica = norma;
    }

    /// <summary>
    /// Define la vida útil del equipo.
    /// </summary>
    public void DefinirVidaUtil(int meses)
    {
        VidaUtilMeses = meses;
    }

    /// <summary>
    /// Indica que requiere capacitación.
    /// </summary>
    public void RequiereCurso()
    {
        RequiereCapacitacion = true;
    }

    /// <summary>
    /// Indica que requiere mantenimiento.
    /// </summary>
    public void RequiereServicio()
    {
        RequiereMantenimiento = true;
    }

    #endregion
}
