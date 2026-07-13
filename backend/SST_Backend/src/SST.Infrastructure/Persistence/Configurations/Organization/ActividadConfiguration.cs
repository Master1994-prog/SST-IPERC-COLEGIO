using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SST.Domain.Organization.Entities;
using SST.Infrastructure.Persistence.Configurations.Common;

namespace SST.Infrastructure.Persistence.Configurations.Organization;

public class ActividadConfiguration : BaseAuditableEntityConfiguration<Actividad>, IEntityTypeConfiguration<Actividad>
{
    public void Configure(EntityTypeBuilder<Actividad> builder)
    {
        ConfigureBase(builder);

        builder.ToTable("Actividades");

        builder.Property(x => x.Nombre)
            .IsRequired()
            .HasMaxLength(150);

        builder.Property(x => x.Descripcion)
            .HasMaxLength(500);

        builder.HasOne(x => x.Proceso)
            .WithMany(x => x.Actividades)
            .HasForeignKey(x => x.ProcesoId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
