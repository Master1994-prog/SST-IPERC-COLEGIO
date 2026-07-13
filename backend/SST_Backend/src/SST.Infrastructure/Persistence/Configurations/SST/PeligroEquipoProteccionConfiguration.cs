using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SST.Domain.SST.Entities;
using SST.Infrastructure.Persistence.Configurations.Common;

namespace SST.Infrastructure.Persistence.Configurations.SST;

public class PeligroEquipoProteccionConfiguration : BaseAuditableEntityConfiguration<PeligroEquipoProteccion>, IEntityTypeConfiguration<PeligroEquipoProteccion>
{
    public void Configure(EntityTypeBuilder<PeligroEquipoProteccion> builder)
    {
        ConfigureBase(builder);

        builder.ToTable("PeligrosEquiposProteccion");

        builder.Property(x => x.Obligatorio)
            .IsRequired()
            .HasDefaultValue(false);

        builder.HasIndex(x => new { x.PeligroId, x.EquipoProteccionId })
            .IsUnique();

        builder.HasOne(x => x.Peligro)
            .WithMany(x => x.PeligroEquiposProteccion)
            .HasForeignKey(x => x.PeligroId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(x => x.EquipoProteccion)
            .WithMany(x => x.PeligroEquiposProteccion)
            .HasForeignKey(x => x.EquipoProteccionId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
