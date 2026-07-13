using FluentValidation;
using SST.Application.SST.Dtos;

namespace SST.Application.SST.Validators;

/// <summary>
/// Validador para actualizar una relación peligro-consecuencia.
/// </summary>
public class UpdatePeligroConsecuenciaDtoValidator : AbstractValidator<UpdatePeligroConsecuenciaDto>
{
    public UpdatePeligroConsecuenciaDtoValidator()
    {
        RuleFor(x => x.PeligroId)
            .GreaterThan(0)
            .WithMessage("Debe seleccionar un peligro válido.");

        RuleFor(x => x.ConsecuenciaId)
            .GreaterThan(0)
            .WithMessage("Debe seleccionar una consecuencia válida.");

        RuleFor(x => x.Observaciones)
            .MaximumLength(1000)
            .WithMessage("Las observaciones no deben superar los 1000 caracteres.")
            .When(x => !string.IsNullOrWhiteSpace(x.Observaciones));
    }
}
