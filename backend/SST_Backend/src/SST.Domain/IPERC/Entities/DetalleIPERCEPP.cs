using SST.Domain.Common;
using SST.Domain.SST.Entities;
using System.ComponentModel.DataAnnotations.Schema;

namespace SST.Domain.IPERC.Entities;

/// <summary>
/// Relación entre un detalle IPERC y los equipos de protección personal.
/// </summary>
[Table("DetalleIPERCEPP")]
public class DetalleIPERCEPP : BaseEntity
{
    public long DetalleIPERCId { get; set; }

    public long EquipoProteccionId { get; set; }

    [ForeignKey(nameof(DetalleIPERCId))]
    public virtual DetalleIPERC DetalleIPERC { get; set; } = default!;

    [ForeignKey(nameof(EquipoProteccionId))]
    public virtual EquipoProteccion EquipoProteccion { get; set; } = default!;
}