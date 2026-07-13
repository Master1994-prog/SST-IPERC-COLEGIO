using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SST.Domain.Organization.Entities;
using SST.Infrastructure.Persistence.Configurations.Common;

namespace SST.Infrastructure.Persistence.Configurations.Organization;

public class SedeConfiguration : BaseAuditableEntityConfiguration<Sede>, IEntityTypeConfiguration<Sede>
{
    public void Configure(EntityTypeBuilder<Sede> builder)
    {
        ConfigureBase(builder);

        builder.ToTable("Sedes");

        builder.Property(x => x.Nombre)
            .IsRequired()
            .HasMaxLength(150);

        builder.Property(x => x.Direccion)
            .HasMaxLength(300);

        builder.HasIndex(x => x.InstitucionId);

        builder.HasOne(x => x.Institucion)
            .WithMany(x => x.Sedes)
            .HasForeignKey(x => x.InstitucionId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
