using FluentValidation;
using SST.Application.SST.Dtos;

namespace SST.Application.SST.Validators;

/// <summary>
/// Validador utilizado para actualizar
/// una medida de control existente.
/// </summary>
public class UpdateControlDtoValidator
    : AbstractValidator<UpdateControlDto>
{
    public UpdateControlDtoValidator()
    {
        // El código es obligatorio al actualizar.
        RuleFor(x => x.Codigo)
            .NotEmpty()
            .WithMessage(
                "El código del control es obligatorio."
            )
            .MaximumLength(20)
            .WithMessage(
                "El código no debe superar "
                + "los 20 caracteres."
            );

        // El nombre es obligatorio.
        RuleFor(x => x.Nombre)
            .NotEmpty()
            .WithMessage(
                "El nombre del control es obligatorio."
            )
            .MinimumLength(3)
            .WithMessage(
                "El nombre del control debe tener "
                + "al menos 3 caracteres."
            )
            .MaximumLength(250)
            .WithMessage(
                "El nombre del control no debe superar "
                + "los 250 caracteres."
            );

        // La descripción es opcional.
        RuleFor(x => x.Descripcion)
            .MaximumLength(2000)
            .WithMessage(
                "La descripción no debe superar "
                + "los 2000 caracteres."
            )
            .When(x =>
                !string.IsNullOrWhiteSpace(
                    x.Descripcion
                )
            );

        // La clasificación es obligatoria.
        RuleFor(x => x.ClasificacionControlId)
            .GreaterThan(0)
            .WithMessage(
                "La clasificación seleccionada "
                + "no es válida."
            );

        // El usuario que actualiza debe ser válido.
        RuleFor(x => x.UsuarioActualizacionId)
            .GreaterThan(0)
            .WithMessage(
                "El usuario que actualiza "
                + "no es válido."
            );
    }
}
