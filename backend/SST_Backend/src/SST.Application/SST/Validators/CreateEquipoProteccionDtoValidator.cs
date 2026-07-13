using FluentValidation;
using SST.Application.SST.Dtos;

namespace SST.Application.SST.Validators;

/// <summary>
/// Validador para registrar un Equipo de Protección Personal.
/// </summary>
public class CreateEquipoProteccionDtoValidator : AbstractValidator<CreateEquipoProteccionDto>
{
    public CreateEquipoProteccionDtoValidator()
    {
        RuleFor(x => x.Codigo)
            .NotEmpty()
            .WithMessage("El código del equipo de protección es obligatorio.")
            .MaximumLength(20)
            .WithMessage("El código no debe superar los 20 caracteres.");

        RuleFor(x => x.Nombre)
            .NotEmpty()
            .WithMessage("El nombre del equipo de protección es obligatorio.")
            .MaximumLength(200)
            .WithMessage("El nombre no debe superar los 200 caracteres.");

        RuleFor(x => x.Descripcion)
            .MaximumLength(2000)
            .WithMessage("La descripción no debe superar los 2000 caracteres.")
            .When(x => !string.IsNullOrWhiteSpace(x.Descripcion));

        RuleFor(x => x.TipoEquipoProteccionId)
            .GreaterThan(0)
            .WithMessage("Debe seleccionar un tipo de equipo de protección válido.");

        RuleFor(x => x.Marca)
            .MaximumLength(100)
            .WithMessage("La marca no debe superar los 100 caracteres.")
            .When(x => !string.IsNullOrWhiteSpace(x.Marca));

        RuleFor(x => x.Modelo)
            .MaximumLength(100)
            .WithMessage("El modelo no debe superar los 100 caracteres.")
            .When(x => !string.IsNullOrWhiteSpace(x.Modelo));

        RuleFor(x => x.NormaTecnica)
            .MaximumLength(300)
            .WithMessage("La norma técnica no debe superar los 300 caracteres.")
            .When(x => !string.IsNullOrWhiteSpace(x.NormaTecnica));

        RuleFor(x => x.VidaUtilMeses)
            .GreaterThanOrEqualTo(0)
            .WithMessage("La vida útil no puede ser negativa.")
            .When(x => x.VidaUtilMeses.HasValue);
    }
}
