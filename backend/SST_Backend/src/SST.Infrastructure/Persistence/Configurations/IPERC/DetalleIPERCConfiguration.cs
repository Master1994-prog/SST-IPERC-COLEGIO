using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SST.Domain.IPERC.Entities;
using SST.Infrastructure.Persistence.Configurations.Common;

namespace SST.Infrastructure.Persistence.Configurations.IPERC;

public class DetalleIPERCConfiguration : BaseAuditableEntityConfiguration<DetalleIPERC>, IEntityTypeConfiguration<DetalleIPERC>
{
    public void Configure(EntityTypeBuilder<DetalleIPERC> builder)
    {
        ConfigureBase(builder);

        builder.ToTable("DetallesIPERC");

        builder.Property(x => x.Item)
            .IsRequired();

        builder.Property(x => x.Tarea)
            .IsRequired()
            .HasMaxLength(500);

        builder.Property(x => x.DescripcionPeligro)
            .HasMaxLength(1500);

        builder.Property(x => x.FechaCompromiso)
            .IsRequired(false);

        builder.Property(x => x.FechaImplementacion)
            .IsRequired(false);

        builder.Property(x => x.EstadoImplementacion)
            .IsRequired();

        builder.HasIndex(x => x.MatrizIPERCId);
        builder.HasIndex(x => x.PeligroId);
        builder.HasIndex(x => x.ConsecuenciaId);
        builder.HasIndex(x => x.EvaluacionInicialId);
        builder.HasIndex(x => x.EvaluacionResidualId);
        builder.HasIndex(x => x.ResponsableImplementacionId);

        builder.HasOne(x => x.MatrizIPERC)
            .WithMany(x => x.Detalles)
            .HasForeignKey(x => x.MatrizIPERCId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(x => x.Peligro)
            .WithMany(x => x.DetallesIPERC)
            .HasForeignKey(x => x.PeligroId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(x => x.Consecuencia)
            .WithMany()
            .HasForeignKey(x => x.ConsecuenciaId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(x => x.EvaluacionInicial)
            .WithMany()
            .HasForeignKey(x => x.EvaluacionInicialId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(x => x.EvaluacionResidual)
            .WithMany()
            .HasForeignKey(x => x.EvaluacionResidualId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(x => x.ResponsableImplementacion)
            .WithMany()
            .HasForeignKey(x => x.ResponsableImplementacionId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasMany(x => x.Controles)
            .WithOne(x => x.DetalleIPERC)
            .HasForeignKey(x => x.DetalleIPERCId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasMany(x => x.EquiposProteccion)
            .WithOne(x => x.DetalleIPERC)
            .HasForeignKey(x => x.DetalleIPERCId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasMany(x => x.Seguimientos)
            .WithOne(x => x.DetalleIPERC)
            .HasForeignKey(x => x.DetalleIPERCId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
