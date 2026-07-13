using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SST.Domain.Organization.Entities;
using SST.Infrastructure.Persistence.Configurations.Common;

namespace SST.Infrastructure.Persistence.Configurations.Organization;

public class AreaConfiguration : BaseAuditableEntityConfiguration<Area>, IEntityTypeConfiguration<Area>
{
    public void Configure(EntityTypeBuilder<Area> builder)
    {
        ConfigureBase(builder);

        builder.ToTable("Areas");

        builder.Property(x => x.Nombre)
            .IsRequired()
            .HasMaxLength(150);

        builder.Property(x => x.Descripcion)
            .HasMaxLength(500);

        builder.HasOne(x => x.Institucion)
            .WithMany(x => x.Areas)
            .HasForeignKey(x => x.InstitucionId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
