using FluentValidation;
using SST.Application.SST.Dtos;

namespace SST.Application.SST.Validators;

/// <summary>
/// Validador para actualizar un peligro.
/// </summary>
public class UpdatePeligroDtoValidator : AbstractValidator<UpdatePeligroDto>
{
    public UpdatePeligroDtoValidator()
    {
        RuleFor(x => x.Codigo)
            .NotEmpty()
            .WithMessage("El código del peligro es obligatorio.")
            .MaximumLength(20)
            .WithMessage("El código no debe superar los 20 caracteres.");

        RuleFor(x => x.Nombre)
            .NotEmpty()
            .WithMessage("El nombre del peligro es obligatorio.")
            .MaximumLength(200)
            .WithMessage("El nombre no debe superar los 200 caracteres.");

        RuleFor(x => x.Descripcion)
            .MaximumLength(1500)
            .WithMessage("La descripción no debe superar los 1500 caracteres.")
            .When(x => !string.IsNullOrWhiteSpace(x.Descripcion));

        RuleFor(x => x.TipoPeligroId)
            .GreaterThan(0)
            .WithMessage("Debe seleccionar un tipo de peligro válido.");

        RuleFor(x => x.Fuente)
            .MaximumLength(300)
            .WithMessage("La fuente no debe superar los 300 caracteres.")
            .When(x => !string.IsNullOrWhiteSpace(x.Fuente));

        RuleFor(x => x.Medio)
            .MaximumLength(300)
            .WithMessage("El medio no debe superar los 300 caracteres.")
            .When(x => !string.IsNullOrWhiteSpace(x.Medio));

        RuleFor(x => x.Receptor)
            .MaximumLength(300)
            .WithMessage("El receptor no debe superar los 300 caracteres.")
            .When(x => !string.IsNullOrWhiteSpace(x.Receptor));

        RuleFor(x => x.RequisitoLegal)
            .MaximumLength(1000)
            .WithMessage("El requisito legal no debe superar los 1000 caracteres.")
            .When(x => !string.IsNullOrWhiteSpace(x.RequisitoLegal));

        RuleFor(x => x.Recomendaciones)
            .MaximumLength(2000)
            .WithMessage("Las recomendaciones no deben superar los 2000 caracteres.")
            .When(x => !string.IsNullOrWhiteSpace(x.Recomendaciones));
    }
}
