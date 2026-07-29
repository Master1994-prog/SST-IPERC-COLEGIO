using FluentValidation;
using SST.Application.SST.Dtos;

namespace SST.Application.SST.Validators;

/// <summary>
/// Validador para registrar un detalle IPERC.
/// </summary>
public class CreateDetalleIPERCDtoValidator : AbstractValidator<CreateDetalleIPERCDto>
{
    public CreateDetalleIPERCDtoValidator()
    {
        RuleFor(x => x.MatrizIPERCId)
            .GreaterThan(0)
            .WithMessage("Debe seleccionar una Matriz IPERC válida.");

        RuleFor(x => x.Item)
            .GreaterThanOrEqualTo(0)
            .WithMessage("El item no puede ser negativo.");

        RuleFor(x => x.Tarea)
            .NotEmpty()
            .WithMessage("La tarea es obligatoria.")
            .MaximumLength(250)
            .WithMessage("La tarea no debe superar los 250 caracteres.");

        RuleFor(x => x.PeligroId)
            .GreaterThan(0)
            .WithMessage("Debe seleccionar un peligro válido.");

        RuleFor(x => x.ConsecuenciaId)
            .GreaterThan(0)
            .WithMessage("Debe seleccionar una consecuencia válida.");

        RuleFor(x => x.DescripcionPeligro)
            .MaximumLength(1000)
            .WithMessage("La descripción del peligro no debe superar los 1000 caracteres.")
            .When(x => !string.IsNullOrWhiteSpace(x.DescripcionPeligro));

        RuleFor(x => x.EvaluacionInicialId)
            .GreaterThan(0)
            .WithMessage("Debe seleccionar una evaluación inicial válida.");

        RuleForEach(x => x.ControlIds)
            .GreaterThan(0)
            .WithMessage("Debe seleccionar controles válidos.");

        RuleForEach(x => x.EquipoProteccionIds)
            .GreaterThan(0)
            .WithMessage("Debe seleccionar equipos de protección válidos.");

        RuleFor(x => x.FechaImplementacion)
            .GreaterThanOrEqualTo(x => x.FechaCompromiso)
            .WithMessage("La fecha de implementación no puede ser menor que la fecha de compromiso.")
            .When(x => x.FechaCompromiso.HasValue && x.FechaImplementacion.HasValue);

        RuleFor(x => x.EstadoImplementacion)
            .InclusiveBetween(0, 4)
            .WithMessage("El estado de implementación debe estar entre 0 y 4.");
    }
}
