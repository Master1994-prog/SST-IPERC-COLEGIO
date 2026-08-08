using FluentValidation;
using SST.Application.SST.Dtos;

namespace SST.Application.SST.Validators;

public class UpdateDetalleIPERCDtoValidator
    : AbstractValidator<UpdateDetalleIPERCDto>
{
    public UpdateDetalleIPERCDtoValidator()
    {
        RuleFor(x => x.MatrizIPERCId)
            .GreaterThan(0)
            .WithMessage(
                "Debe seleccionar una Matriz IPERC válida.");

        RuleFor(x => x.Item)
            .GreaterThanOrEqualTo(0)
            .WithMessage(
                "El número de item no puede ser negativo.");

        RuleFor(x => x.Tarea)
            .NotEmpty()
            .WithMessage(
                "La tarea es obligatoria.")
            .MinimumLength(2)
            .WithMessage(
                "La tarea debe tener al menos 2 caracteres.")
            .MaximumLength(250)
            .WithMessage(
                "La tarea no puede superar los 250 caracteres.");

        RuleFor(x => x.PeligroId)
            .GreaterThan(0)
            .WithMessage(
                "Debe seleccionar un peligro válido.");

        RuleFor(x => x.ConsecuenciaId)
            .GreaterThan(0)
            .WithMessage(
                "Debe seleccionar una consecuencia válida.");

        RuleFor(x => x.DescripcionPeligro)
            .MaximumLength(1000)
            .When(x =>
                !string.IsNullOrWhiteSpace(
                    x.DescripcionPeligro))
            .WithMessage(
                "La descripción del peligro no puede superar los 1000 caracteres.");

        RuleFor(x => x.ProbabilidadInicialId)
            .GreaterThan(0)
            .WithMessage(
                "Debe seleccionar la probabilidad inicial.");

        RuleFor(x => x.SeveridadInicialId)
            .GreaterThan(0)
            .WithMessage(
                "Debe seleccionar la severidad inicial.");

        RuleFor(x => x.ObservacionesEvaluacionInicial)
            .MaximumLength(1000)
            .When(x =>
                !string.IsNullOrWhiteSpace(
                    x.ObservacionesEvaluacionInicial))
            .WithMessage(
                "Las observaciones iniciales no pueden superar los 1000 caracteres.");

        RuleFor(x => x.ObservacionesEvaluacionResidual)
            .MaximumLength(1000)
            .When(x =>
                !string.IsNullOrWhiteSpace(
                    x.ObservacionesEvaluacionResidual))
            .WithMessage(
                "Las observaciones residuales no pueden superar los 1000 caracteres.");

        RuleFor(x => x.EstadoImplementacion)
            .InclusiveBetween(0, 4)
            .WithMessage(
                "El estado de implementación debe estar entre 0 y 4.");

        RuleFor(x => x)
            .Must(TenerEvaluacionResidualCompleta)
            .WithMessage(
                "Para la evaluación residual debe seleccionar probabilidad y severidad.");
    }

    private static bool TenerEvaluacionResidualCompleta(
        UpdateDetalleIPERCDto dto)
    {
        bool tieneProbabilidad =
            dto.ProbabilidadResidualId.HasValue &&
            dto.ProbabilidadResidualId.Value > 0;

        bool tieneSeveridad =
            dto.SeveridadResidualId.HasValue &&
            dto.SeveridadResidualId.Value > 0;

        return tieneProbabilidad ==
               tieneSeveridad;
    }
}