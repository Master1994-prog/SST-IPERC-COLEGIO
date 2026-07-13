using FluentValidation;
using SST.Application.SST.Dtos;

namespace SST.Application.SST.Validators;

/// <summary>
/// Validador para registrar una consecuencia.
/// </summary>
public class CreateConsecuenciaDtoValidator : AbstractValidator<CreateConsecuenciaDto>
{
    public CreateConsecuenciaDtoValidator()
    {
        // El código es obligatorio.
        RuleFor(x => x.Codigo)
            .NotEmpty()
            .WithMessage("El código de la consecuencia es obligatorio.")
            .MaximumLength(50)
            .WithMessage("El código no debe superar los 50 caracteres.");

        // El nombre es obligatorio.
        RuleFor(x => x.Nombre)
            .NotEmpty()
            .WithMessage("El nombre de la consecuencia es obligatorio.")
            .MaximumLength(200)
            .WithMessage("El nombre no debe superar los 200 caracteres.");

        // La descripción es opcional.
        RuleFor(x => x.Descripcion)
            .MaximumLength(1000)
            .WithMessage("La descripción no debe superar los 1000 caracteres.")
            .When(x => !string.IsNullOrWhiteSpace(x.Descripcion));
    }
}
