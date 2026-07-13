using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SST.Domain.SST.Entities;
using SST.Infrastructure.Persistence.Configurations.Common;

namespace SST.Infrastructure.Persistence.Configurations.SST;

public class PeligroConfiguration : BaseAuditableEntityConfiguration<Peligro>, IEntityTypeConfiguration<Peligro>
{
    public void Configure(EntityTypeBuilder<Peligro> builder)
    {
        ConfigureBase(builder);

        builder.ToTable("Peligros");

        builder.Property(x => x.Codigo)
            .IsRequired()
            .HasMaxLength(20);

        builder.Property(x => x.Nombre)
            .IsRequired()
            .HasMaxLength(200);

        builder.Property(x => x.Descripcion)
            .HasMaxLength(1500);

        builder.Property(x => x.Fuente)
            .HasMaxLength(300);

        builder.Property(x => x.Medio)
            .HasMaxLength(300);

        builder.Property(x => x.Receptor)
            .HasMaxLength(300);

        builder.Property(x => x.RequisitoLegal)
            .HasMaxLength(1000);

        builder.Property(x => x.Recomendaciones)
            .HasMaxLength(2000);

        builder.Property(x => x.Activo)
            .IsRequired()
            .HasDefaultValue(true);

        builder.HasIndex(x => x.Codigo)
            .IsUnique();

        builder.HasIndex(x => x.Nombre);

        builder.HasIndex(x => x.TipoPeligroId);

        builder.HasOne(x => x.TipoPeligro)
            .WithMany(x => x.Peligros)
            .HasForeignKey(x => x.TipoPeligroId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
