using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SST.Domain.Common;

namespace SST.Infrastructure.Persistence.Configurations.Common;

/// <summary>
/// Configuración base para todas las entidades auditables.
/// </summary>
public abstract class BaseAuditableEntityConfiguration<T> where T : BaseAuditableEntity
{
    protected void ConfigureBase(EntityTypeBuilder<T> builder)
    {
        builder.HasKey(x => x.Id);

        builder.Property(x => x.Id)
            .ValueGeneratedOnAdd();

        builder.Property(x => x.Estado)
            .IsRequired()
            .HasDefaultValue(true);

        builder.Property(x => x.FechaRegistro)
            .IsRequired();

        builder.Property(x => x.FechaActualizacion)
            .IsRequired(false);

        builder.Property(x => x.UsuarioRegistroId)
            .IsRequired();

        builder.Property(x => x.UsuarioActualizacionId)
            .IsRequired(false);

        builder.HasIndex(x => x.Estado);
        builder.HasIndex(x => x.FechaRegistro);
    }
}
