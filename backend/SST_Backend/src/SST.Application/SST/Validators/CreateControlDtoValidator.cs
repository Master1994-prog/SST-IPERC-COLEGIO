using FluentValidation;
using SST.Application.SST.Dtos;

namespace SST.Application.SST.Validators;

/// <summary>
/// Validador utilizado para registrar
/// una nueva medida de control.
/// </summary>
public class CreateControlDtoValidator
    : AbstractValidator<CreateControlDto>
{
    public CreateControlDtoValidator()
    {
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

        // El usuario que registra debe ser válido.
        RuleFor(x => x.UsuarioRegistroId)
            .GreaterThan(0)
            .WithMessage(
                "El usuario que registra "
                + "no es válido."
            );
    }
}
