using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SST.Domain.Security.Entities;

namespace SST.Infrastructure.Persistence.Configurations.Security;

public class UsuarioRolConfiguration : IEntityTypeConfiguration<UsuarioRol>
{
    public void Configure(EntityTypeBuilder<UsuarioRol> builder)
    {
        builder.ToTable("UsuariosRoles");

        builder.HasKey(x => x.Id);

        builder.HasIndex(x => new
        {
            x.UsuarioId,
            x.RolId
        }).IsUnique();

        builder.HasOne(x => x.Usuario)
            .WithMany(x => x.UsuariosRoles)
            .HasForeignKey(x => x.UsuarioId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(x => x.Rol)
            .WithMany(x => x.UsuariosRoles)
            .HasForeignKey(x => x.RolId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
