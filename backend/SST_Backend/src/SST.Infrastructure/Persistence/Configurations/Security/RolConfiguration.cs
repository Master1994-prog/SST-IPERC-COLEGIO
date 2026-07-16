using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SST.Domain.Security.Entities;

namespace SST.Infrastructure.Persistence.Configurations.Security;

public class RolConfiguration : IEntityTypeConfiguration<Rol>
{
    public void Configure(EntityTypeBuilder<Rol> builder)
    {
        builder.ToTable("Roles");

        builder.HasKey(x => x.Id);

        builder.Property(x => x.Codigo)
            .IsRequired()
            .HasMaxLength(50);

        builder.Property(x => x.Nombre)
            .IsRequired()
            .HasMaxLength(100);

        builder.Property(x => x.Descripcion)
            .HasMaxLength(300);

        builder.HasIndex(x => x.Codigo)
            .IsUnique();

        builder.HasIndex(x => x.Nombre)
            .IsUnique();

        builder.Property(x => x.EsGlobal)
            .IsRequired()
            .HasDefaultValue(false);
    }
}
