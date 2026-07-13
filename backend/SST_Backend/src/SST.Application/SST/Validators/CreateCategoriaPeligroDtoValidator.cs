using FluentValidation;
using SST.Application.SST.Dtos;

namespace SST.Application.SST.Validators;

/// <summary>
/// Validador para el DTO de creación de una categoría de peligro.
/// Se encarga de verificar que los datos enviados sean correctos antes de registrar.
/// </summary>
public class CreateCategoriaPeligroDtoValidator : AbstractValidator<CreateCategoriaPeligroDto>
{
    public CreateCategoriaPeligroDtoValidator()
    {
        // El nombre es obligatorio.
        RuleFor(x => x.Nombre)
            .NotEmpty()
            .WithMessage("El nombre de la categoría de peligro es obligatorio.")
            .MaximumLength(150)
            .WithMessage("El nombre no debe superar los 150 caracteres.");

        // La descripción es opcional, pero si se ingresa no debe superar los 500 caracteres.
        RuleFor(x => x.Descripcion)
            .MaximumLength(500)
            .WithMessage("La descripción no debe superar los 500 caracteres.")
            .When(x => !string.IsNullOrWhiteSpace(x.Descripcion));
    }
}
