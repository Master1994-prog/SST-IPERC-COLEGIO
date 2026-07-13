using FluentValidation;
using SST.Application.SST.Dtos;

namespace SST.Application.SST.Validators;

/// <summary>
/// Validador para registrar una relación peligro-control.
/// </summary>
public class CreatePeligroControlDtoValidator : AbstractValidator<CreatePeligroControlDto>
{
    public CreatePeligroControlDtoValidator()
    {
        RuleFor(x => x.PeligroId)
            .GreaterThan(0)
            .WithMessage("Debe seleccionar un peligro válido.");

        RuleFor(x => x.ControlId)
            .GreaterThan(0)
            .WithMessage("Debe seleccionar un control válido.");

        RuleFor(x => x.Prioridad)
            .GreaterThanOrEqualTo(0)
            .WithMessage("La prioridad no puede ser negativa.");
    }
}
