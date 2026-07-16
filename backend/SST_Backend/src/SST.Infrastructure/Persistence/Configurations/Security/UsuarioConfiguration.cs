using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SST.Domain.Security.Entities;

namespace SST.Infrastructure.Persistence.Configurations.Security;

public class UsuarioConfiguration : IEntityTypeConfiguration<Usuario>
{
    public void Configure(EntityTypeBuilder<Usuario> builder)
    {
        builder.ToTable("Usuarios");

        builder.HasKey(x => x.Id);

        builder.Property(x => x.Nombres)
            .IsRequired()
            .HasMaxLength(100);

        builder.Property(x => x.Apellidos)
            .IsRequired()
            .HasMaxLength(100);

        builder.Property(x => x.NombreUsuario)
            .IsRequired()
            .HasMaxLength(80);

        builder.Property(x => x.PasswordHash)
            .IsRequired()
            .HasMaxLength(500);

        builder.Property(x => x.Correo)
            .HasMaxLength(150);

        builder.HasIndex(x => x.NombreUsuario)
            .IsUnique();

        builder.HasIndex(x => x.Correo)
            .IsUnique();
    }
}
