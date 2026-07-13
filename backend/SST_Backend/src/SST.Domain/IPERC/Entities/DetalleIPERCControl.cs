using SST.Domain.Common;
using SST.Domain.SST.Entities;
using System.ComponentModel.DataAnnotations.Schema;

namespace SST.Domain.IPERC.Entities;

/// <summary>
/// Relación entre un detalle IPERC y los controles aplicados.
/// </summary>
[Table("DetalleIPERCControles")]
public class DetalleIPERCControl : BaseEntity
{
    public long DetalleIPERCId { get; set; }

    public long ControlId { get; set; }

    [ForeignKey(nameof(DetalleIPERCId))]
    public virtual DetalleIPERC DetalleIPERC { get; set; } = default!;

    [ForeignKey(nameof(ControlId))]
    public virtual Control Control { get; set; } = default!;
}