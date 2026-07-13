using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SST.Domain.SST.Entities;

namespace SST.Infrastructure.Persistence.Configurations.SST;

public class CategoriaPeligroConfiguration : IEntityTypeConfiguration<CategoriaPeligro>
{
    public void Configure(EntityTypeBuilder<CategoriaPeligro> builder)
    {
        builder.ToTable("CategoriasPeligro");

        builder.HasKey(x => x.Id);

        builder.Property(x => x.Codigo)
            .IsRequired()
            .HasMaxLength(20);

        builder.Property(x => x.Nombre)
            .IsRequired()
            .HasMaxLength(150);

        builder.Property(x => x.Descripcion)
            .HasMaxLength(1000);

        builder.Property(x => x.Color)
            .HasMaxLength(10);

        builder.Property(x => x.Icono)
            .HasMaxLength(100);

        builder.Property(x => x.Activo)
            .HasDefaultValue(true);

        builder.Property(x => x.Orden)
            .HasDefaultValue(0);

        builder.HasIndex(x => x.Codigo)
            .IsUnique();

        builder.HasIndex(x => x.Nombre);

        builder.HasMany(x => x.TiposPeligro)
            .WithOne(x => x.CategoriaPeligro)
            .HasForeignKey(x => x.CategoriaPeligroId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
