using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SST.Domain.Organization.Entities;
using SST.Infrastructure.Persistence.Configurations.Common;

namespace SST.Infrastructure.Persistence.Configurations.Organization;

public class PuestoTrabajoConfiguration : BaseAuditableEntityConfiguration<PuestoTrabajo>, IEntityTypeConfiguration<PuestoTrabajo>
{
    public void Configure(EntityTypeBuilder<PuestoTrabajo> builder)
    {
        ConfigureBase(builder);

        builder.ToTable("PuestosTrabajo");

        builder.Property(x => x.Nombre)
            .IsRequired()
            .HasMaxLength(150);

        builder.Property(x => x.Descripcion)
            .HasMaxLength(1000);

        builder.HasIndex(x => x.AreaId);

        builder.HasOne(x => x.Area)
            .WithMany(x => x.PuestosTrabajo)
            .HasForeignKey(x => x.AreaId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
