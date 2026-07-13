using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SST.Domain.SST.Entities;

namespace SST.Infrastructure.Persistence.Configurations.SST;

public class TipoPeligroConfiguration : IEntityTypeConfiguration<TipoPeligro>
{
    public void Configure(EntityTypeBuilder<TipoPeligro> builder)
    {
        builder.ToTable("TiposPeligro");

        builder.HasKey(x => x.Id);

        builder.Property(x => x.Codigo)
            .IsRequired()
            .HasMaxLength(20);

        builder.Property(x => x.Nombre)
            .IsRequired()
            .HasMaxLength(150);

        builder.Property(x => x.Descripcion)
            .HasMaxLength(1000);

        builder.Property(x => x.Activo)
            .HasDefaultValue(true);

        builder.HasIndex(x => x.Codigo)
            .IsUnique();

        builder.HasIndex(x => x.Nombre);

        builder.HasMany(x => x.Peligros)
            .WithOne(x => x.TipoPeligro)
            .HasForeignKey(x => x.TipoPeligroId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
