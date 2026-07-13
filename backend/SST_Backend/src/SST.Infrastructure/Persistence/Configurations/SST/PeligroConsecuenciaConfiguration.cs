using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SST.Domain.SST.Entities;
using SST.Infrastructure.Persistence.Configurations.Common;

namespace SST.Infrastructure.Persistence.Configurations.SST;

public class PeligroConsecuenciaConfiguration : BaseAuditableEntityConfiguration<PeligroConsecuencia>, IEntityTypeConfiguration<PeligroConsecuencia>
{
    public void Configure(EntityTypeBuilder<PeligroConsecuencia> builder)
    {
        ConfigureBase(builder);

        builder.ToTable("PeligrosConsecuencias");

        builder.Property(x => x.Observaciones)
            .HasMaxLength(1000);

        builder.Property(x => x.Principal)
            .IsRequired()
            .HasDefaultValue(false);

        builder.HasIndex(x => new { x.PeligroId, x.ConsecuenciaId })
            .IsUnique();

        builder.HasOne(x => x.Peligro)
            .WithMany(x => x.PeligroConsecuencias)
            .HasForeignKey(x => x.PeligroId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(x => x.Consecuencia)
            .WithMany(x => x.PeligroConsecuencias)
            .HasForeignKey(x => x.ConsecuenciaId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
