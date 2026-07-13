using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SST.Domain.SST.Entities;
using SST.Infrastructure.Persistence.Configurations.Common;

namespace SST.Infrastructure.Persistence.Configurations.SST;

public class ConsecuenciaConfiguration : BaseAuditableEntityConfiguration<Consecuencia>, IEntityTypeConfiguration<Consecuencia>
{
    public void Configure(EntityTypeBuilder<Consecuencia> builder)
    {
        ConfigureBase(builder);

        builder.ToTable("Consecuencias");

        builder.Property(x => x.Codigo)
            .IsRequired()
            .HasMaxLength(20);

        builder.Property(x => x.Nombre)
            .IsRequired()
            .HasMaxLength(200);

        builder.Property(x => x.Descripcion)
            .HasMaxLength(1500);

        builder.Property(x => x.Clasificacion)
            .HasMaxLength(100);

        builder.Property(x => x.IncapacidadPermanente)
            .IsRequired()
            .HasDefaultValue(false);

        builder.Property(x => x.Fatalidad)
            .IsRequired()
            .HasDefaultValue(false);

        builder.Property(x => x.Activo)
            .IsRequired()
            .HasDefaultValue(true);

        builder.HasIndex(x => x.Codigo)
            .IsUnique();

        builder.HasIndex(x => x.Nombre);
    }
}