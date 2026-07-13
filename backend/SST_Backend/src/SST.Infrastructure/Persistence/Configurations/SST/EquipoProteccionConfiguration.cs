using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SST.Domain.SST.Entities;
using SST.Infrastructure.Persistence.Configurations.Common;

namespace SST.Infrastructure.Persistence.Configurations.SST;

public class EquipoProteccionConfiguration : BaseAuditableEntityConfiguration<EquipoProteccion>, IEntityTypeConfiguration<EquipoProteccion>
{
    public void Configure(EntityTypeBuilder<EquipoProteccion> builder)
    {
        ConfigureBase(builder);

        builder.ToTable("EquiposProteccion");

        builder.Property(x => x.Codigo)
            .IsRequired()
            .HasMaxLength(20);

        builder.Property(x => x.Nombre)
            .IsRequired()
            .HasMaxLength(200);

        builder.Property(x => x.Descripcion)
            .HasMaxLength(2000);

        builder.Property(x => x.Marca)
            .HasMaxLength(100);

        builder.Property(x => x.Modelo)
            .HasMaxLength(100);

        builder.Property(x => x.NormaTecnica)
            .HasMaxLength(300);

        builder.Property(x => x.RequiereCapacitacion)
            .IsRequired()
            .HasDefaultValue(false);

        builder.Property(x => x.RequiereMantenimiento)
            .IsRequired()
            .HasDefaultValue(false);

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

        builder.HasIndex(x => x.TipoEquipoProteccionId);

        builder.HasIndex(x => x.ColegioId);

        builder.HasOne(x => x.TipoEquipoProteccion)
            .WithMany(x => x.EquiposProteccion)
            .HasForeignKey(x => x.TipoEquipoProteccionId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
