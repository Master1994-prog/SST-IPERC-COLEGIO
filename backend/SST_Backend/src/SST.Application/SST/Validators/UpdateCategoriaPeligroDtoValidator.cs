using FluentValidation;
using SST.Application.SST.Dtos;

namespace SST.Application.SST.Validators;

/// <summary>
/// Validador para actualizar una categoría de peligro.
/// No valida Id porque el Id llega desde la ruta del controlador.
/// Ejemplo: PUT /api/categorias-peligro/1
/// </summary>
public class UpdateCategoriaPeligroDtoValidator : AbstractValidator<UpdateCategoriaPeligroDto>
{
    public UpdateCategoriaPeligroDtoValidator()
    {
        // El nombre es obligatorio y no debe superar los 150 caracteres.
        RuleFor(x => x.Nombre)
            .NotEmpty()
            .WithMessage("El nombre de la categoría de peligro es obligatorio.")
            .MaximumLength(150)
            .WithMessage("El nombre no debe superar los 150 caracteres.");

        // La descripción es opcional, pero si se ingresa no debe superar los 1000 caracteres.
        RuleFor(x => x.Descripcion)
            .MaximumLength(1000)
            .WithMessage("La descripción no debe superar los 1000 caracteres.")
            .When(x => !string.IsNullOrWhiteSpace(x.Descripcion));

        // El color es opcional, pero si se ingresa no debe superar los 10 caracteres.
        RuleFor(x => x.Color)
            .MaximumLength(10)
            .WithMessage("El color no debe superar los 10 caracteres.")
            .When(x => !string.IsNullOrWhiteSpace(x.Color));

        // El icono es opcional, pero si se ingresa no debe superar los 100 caracteres.
        RuleFor(x => x.Icono)
            .MaximumLength(100)
            .WithMessage("El icono no debe superar los 100 caracteres.")
            .When(x => !string.IsNullOrWhiteSpace(x.Icono));

        // El orden no debe ser negativo.
        RuleFor(x => x.Orden)
            .GreaterThanOrEqualTo(0)
            .WithMessage("El orden no puede ser negativo.");
    }
}
