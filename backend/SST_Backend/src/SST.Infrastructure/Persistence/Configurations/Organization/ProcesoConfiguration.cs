using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SST.Domain.Organization.Entities;
using SST.Infrastructure.Persistence.Configurations.Common;

namespace SST.Infrastructure.Persistence.Configurations.Organization;

public class ProcesoConfiguration : BaseAuditableEntityConfiguration<Proceso>, IEntityTypeConfiguration<Proceso>
{
    public void Configure(EntityTypeBuilder<Proceso> builder)
    {
        ConfigureBase(builder);

        builder.ToTable("Procesos");

        builder.Property(x => x.Nombre)
            .IsRequired()
            .HasMaxLength(150);

        builder.Property(x => x.Descripcion)
            .HasMaxLength(500);

        builder.HasOne(x => x.Area)
            .WithMany(x => x.Procesos)
            .HasForeignKey(x => x.AreaId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
