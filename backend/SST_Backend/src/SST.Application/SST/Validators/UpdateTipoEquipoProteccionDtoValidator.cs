using FluentValidation;
using SST.Application.SST.Dtos;

namespace SST.Application.SST.Validators;

/// <summary>
/// Validador para actualizar un tipo de Equipo de Protección Personal.
/// </summary>
public class UpdateTipoEquipoProteccionDtoValidator : AbstractValidator<UpdateTipoEquipoProteccionDto>
{
    public UpdateTipoEquipoProteccionDtoValidator()
    {
        RuleFor(x => x.Codigo)
            .NotEmpty()
            .WithMessage("El código del tipo de equipo de protección es obligatorio.")
            .MaximumLength(20)
            .WithMessage("El código no debe superar los 20 caracteres.");

        RuleFor(x => x.Nombre)
            .NotEmpty()
            .WithMessage("El nombre del tipo de equipo de protección es obligatorio.")
            .MaximumLength(150)
            .WithMessage("El nombre no debe superar los 150 caracteres.");

        RuleFor(x => x.Descripcion)
            .MaximumLength(1000)
            .WithMessage("La descripción no debe superar los 1000 caracteres.")
            .When(x => !string.IsNullOrWhiteSpace(x.Descripcion));

        RuleFor(x => x.Orden)
            .GreaterThanOrEqualTo(0)
            .WithMessage("El orden no puede ser negativo.");
    }
}
