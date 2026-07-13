using FluentValidation;
using SST.Application.SST.Dtos;

namespace SST.Application.SST.Validators;

/// <summary>
/// Validador para registrar un tipo de peligro.
/// Verifica que los datos enviados sean correctos antes de guardar.
/// </summary>
public class CreateTipoPeligroDtoValidator : AbstractValidator<CreateTipoPeligroDto>
{
    public CreateTipoPeligroDtoValidator()
    {
        // El nombre es obligatorio y no debe superar los 150 caracteres.
        RuleFor(x => x.Nombre)
            .NotEmpty()
            .WithMessage("El nombre del tipo de peligro es obligatorio.")
            .MaximumLength(150)
            .WithMessage("El nombre no debe superar los 150 caracteres.");

        // La descripción es opcional, pero no debe superar los 1000 caracteres.
        RuleFor(x => x.Descripcion)
            .MaximumLength(1000)
            .WithMessage("La descripción no debe superar los 1000 caracteres.")
            .When(x => !string.IsNullOrWhiteSpace(x.Descripcion));

        // Debe estar asociado a una categoría de peligro válida.
        RuleFor(x => x.CategoriaPeligroId)
            .GreaterThan(0)
            .WithMessage("Debe seleccionar una categoría de peligro válida.");
    }
}
