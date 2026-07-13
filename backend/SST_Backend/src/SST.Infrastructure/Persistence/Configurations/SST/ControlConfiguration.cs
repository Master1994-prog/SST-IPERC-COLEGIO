using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SST.Domain.SST.Entities;
using SST.Infrastructure.Persistence.Configurations.Common;

namespace SST.Infrastructure.Persistence.Configurations.SST;

public class ControlConfiguration : BaseAuditableEntityConfiguration<Control>, IEntityTypeConfiguration<Control>
{
    public void Configure(EntityTypeBuilder<Control> builder)
    {
        ConfigureBase(builder);

        builder.ToTable("Controles");

        builder.Property(x => x.Codigo)
            .IsRequired()
            .HasMaxLength(20);

        builder.Property(x => x.Nombre)
            .IsRequired()
            .HasMaxLength(250);

        builder.Property(x => x.Descripcion)
            .HasMaxLength(2000);

        builder.Property(x => x.Prioridad)
            .IsRequired();

        builder.Property(x => x.Obligatorio)
            .IsRequired()
            .HasDefaultValue(false);

        builder.Property(x => x.Frecuencia)
            .HasMaxLength(100);

        builder.Property(x => x.ResponsableSugerido)
            .HasMaxLength(200);

        builder.Property(x => x.RequisitoLegal)
            .HasMaxLength(1000);

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

        builder.HasIndex(x => x.ClasificacionControlId);

        builder.HasIndex(x => x.ColegioId);

        builder.HasOne(x => x.ClasificacionControl)
            .WithMany(x => x.Controles)
            .HasForeignKey(x => x.ClasificacionControlId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
