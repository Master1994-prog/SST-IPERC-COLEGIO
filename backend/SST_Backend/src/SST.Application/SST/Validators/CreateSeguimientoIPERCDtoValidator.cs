using FluentValidation;
using SST.Application.SST.Dtos;

namespace SST.Application.SST.Validators;

/// <summary>
/// Validador para registrar un seguimiento IPERC.
/// </summary>
public class CreateSeguimientoIPERCDtoValidator : AbstractValidator<CreateSeguimientoIPERCDto>
{
    public CreateSeguimientoIPERCDtoValidator()
    {
        RuleFor(x => x.DetalleIPERCId)
            .GreaterThan(0)
            .WithMessage("Debe seleccionar un detalle IPERC válido.");

        RuleFor(x => x.UsuarioId)
            .GreaterThan(0)
            .WithMessage("Debe seleccionar un usuario válido.");

        RuleFor(x => x.Descripcion)
            .NotEmpty()
            .WithMessage("La descripción del seguimiento es obligatoria.")
            .MaximumLength(3000)
            .WithMessage("La descripción no debe superar los 3000 caracteres.");

        RuleFor(x => x.PorcentajeAvance)
            .InclusiveBetween(0, 100)
            .WithMessage("El porcentaje de avance debe estar entre 0 y 100.");

        RuleFor(x => x.Observaciones)
            .MaximumLength(3000)
            .WithMessage("Las observaciones no deben superar los 3000 caracteres.")
            .When(x => !string.IsNullOrWhiteSpace(x.Observaciones));

        RuleFor(x => x.Archivo)
            .MaximumLength(500)
            .WithMessage("La ruta del archivo no debe superar los 500 caracteres.")
            .When(x => !string.IsNullOrWhiteSpace(x.Archivo));

        RuleFor(x => x.NombreArchivo)
            .MaximumLength(250)
            .WithMessage("El nombre del archivo no debe superar los 250 caracteres.")
            .When(x => !string.IsNullOrWhiteSpace(x.NombreArchivo));

        RuleFor(x => x.TipoArchivo)
            .MaximumLength(100)
            .WithMessage("El tipo de archivo no debe superar los 100 caracteres.")
            .When(x => !string.IsNullOrWhiteSpace(x.TipoArchivo));

        RuleFor(x => x.FechaVerificacion)
            .NotNull()
            .WithMessage("Debe indicar la fecha de verificación cuando el seguimiento está verificado.")
            .When(x => x.Verificado);
    }
}
