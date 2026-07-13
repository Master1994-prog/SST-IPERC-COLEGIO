using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SST.Domain.SST.Entities;
using SST.Infrastructure.Persistence.Configurations.Common;

namespace SST.Infrastructure.Persistence.Configurations.SST;

public class ClasificacionControlConfiguration : BaseAuditableEntityConfiguration<ClasificacionControl>, IEntityTypeConfiguration<ClasificacionControl>
{
    public void Configure(EntityTypeBuilder<ClasificacionControl> builder)
    {
        ConfigureBase(builder);

        builder.ToTable("ClasificacionesControl");

        builder.Property(x => x.Codigo)
            .IsRequired()
            .HasMaxLength(20);

        builder.Property(x => x.Nombre)
            .IsRequired()
            .HasMaxLength(150);

        builder.Property(x => x.Descripcion)
            .HasMaxLength(1000);

        builder.Property(x => x.Prioridad)
            .IsRequired();

        builder.Property(x => x.Activo)
            .IsRequired()
            .HasDefaultValue(true);

        builder.HasIndex(x => x.Codigo)
            .IsUnique();

        builder.HasIndex(x => x.Nombre);

        builder.HasMany(x => x.Controles)
            .WithOne(x => x.ClasificacionControl)
            .HasForeignKey(x => x.ClasificacionControlId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
