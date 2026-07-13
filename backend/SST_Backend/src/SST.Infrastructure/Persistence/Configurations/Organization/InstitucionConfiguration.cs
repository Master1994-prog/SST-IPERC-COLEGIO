using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SST.Domain.Organization.Entities;
using SST.Infrastructure.Persistence.Configurations.Common;

namespace SST.Infrastructure.Persistence.Configurations.Organization;

public class InstitucionConfiguration : BaseAuditableEntityConfiguration<Institucion>, IEntityTypeConfiguration<Institucion>
{
    public void Configure(EntityTypeBuilder<Institucion> builder)
    {
        ConfigureBase(builder);

        builder.ToTable("Instituciones");

        builder.Property(x => x.Codigo)
            .IsRequired()
            .HasMaxLength(20);

        builder.Property(x => x.Nombre)
            .IsRequired()
            .HasMaxLength(200);

        builder.Property(x => x.Ruc)
            .HasMaxLength(20);

        builder.Property(x => x.Direccion)
            .HasMaxLength(300);

        builder.HasIndex(x => x.Codigo).IsUnique();
        builder.HasIndex(x => x.Nombre);
    }
}
