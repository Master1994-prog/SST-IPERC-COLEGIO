using FluentValidation;
using SST.Application.SST.Dtos;

namespace SST.Application.SST.Validators;

/// <summary>
/// Validador para actualizar una evaluación de riesgo.
/// </summary>
public class UpdateEvaluacionRiesgoDtoValidator : AbstractValidator<UpdateEvaluacionRiesgoDto>
{
    public UpdateEvaluacionRiesgoDtoValidator()
    {
        RuleFor(x => x.ProbabilidadId)
            .GreaterThan(0)
            .WithMessage("Debe seleccionar una probabilidad válida.");

        RuleFor(x => x.SeveridadId)
            .GreaterThan(0)
            .WithMessage("Debe seleccionar una severidad válida.");

        RuleFor(x => x.NivelRiesgoId)
            .GreaterThan(0)
            .WithMessage("Debe seleccionar un nivel de riesgo válido.");

        RuleFor(x => x.Observaciones)
            .MaximumLength(1000)
            .WithMessage("Las observaciones no deben superar los 1000 caracteres.")
            .When(x => !string.IsNullOrWhiteSpace(x.Observaciones));
    }
}
