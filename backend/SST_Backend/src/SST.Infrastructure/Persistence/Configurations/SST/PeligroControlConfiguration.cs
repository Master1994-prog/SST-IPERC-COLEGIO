using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SST.Domain.SST.Entities;
using SST.Infrastructure.Persistence.Configurations.Common;

namespace SST.Infrastructure.Persistence.Configurations.SST;

public class PeligroControlConfiguration : BaseAuditableEntityConfiguration<PeligroControl>, IEntityTypeConfiguration<PeligroControl>
{
    public void Configure(EntityTypeBuilder<PeligroControl> builder)
    {
        ConfigureBase(builder);

        builder.ToTable("PeligrosControles");

        builder.Property(x => x.Obligatorio)
            .IsRequired()
            .HasDefaultValue(false);

        builder.Property(x => x.Prioridad)
            .IsRequired();

        builder.HasIndex(x => new { x.PeligroId, x.ControlId })
            .IsUnique();

        builder.HasOne(x => x.Peligro)
            .WithMany(x => x.PeligroControles)
            .HasForeignKey(x => x.PeligroId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(x => x.Control)
            .WithMany(x => x.PeligroControles)
            .HasForeignKey(x => x.ControlId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
