using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SST.Domain.SST.Entities;
using SST.Infrastructure.Persistence.Configurations.Common;

namespace SST.Infrastructure.Persistence.Configurations.SST;

public class TipoEquipoProteccionConfiguration : BaseAuditableEntityConfiguration<TipoEquipoProteccion>, IEntityTypeConfiguration<TipoEquipoProteccion>
{
    public void Configure(EntityTypeBuilder<TipoEquipoProteccion> builder)
    {
        ConfigureBase(builder);

        builder.ToTable("TiposEquipoProteccion");

        builder.Property(x => x.Codigo)
            .IsRequired()
            .HasMaxLength(20);

        builder.Property(x => x.Nombre)
            .IsRequired()
            .HasMaxLength(150);

        builder.Property(x => x.Descripcion)
            .HasMaxLength(1000);

        builder.Property(x => x.Orden)
            .IsRequired();

        builder.Property(x => x.Activo)
            .IsRequired()
            .HasDefaultValue(true);

        builder.Property(x => x.EsGlobal)
            .IsRequired()
            .HasDefaultValue(true);

        builder.Property(x => x.ColegioId)
            .IsRequired(false);

        builder.HasIndex(x => x.Codigo)
            .IsUnique();

        builder.HasIndex(x => x.Nombre);

        builder.HasIndex(x => x.ColegioId);

        builder.HasMany(x => x.EquiposProteccion)
            .WithOne(x => x.TipoEquipoProteccion)
            .HasForeignKey(x => x.TipoEquipoProteccionId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
