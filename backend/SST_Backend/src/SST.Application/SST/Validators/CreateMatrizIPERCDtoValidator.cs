using FluentValidation;
using SST.Application.SST.Dtos;

namespace SST.Application.SST.Validators;

/// <summary>
/// Validador para registrar una Matriz IPERC.
/// No valida Codigo porque el código se genera automáticamente.
/// </summary>
public class CreateMatrizIPERCDtoValidator : AbstractValidator<CreateMatrizIPERCDto>
{
    public CreateMatrizIPERCDtoValidator()
    {
        RuleFor(x => x.Nombre)
            .NotEmpty()
            .WithMessage("El nombre de la Matriz IPERC es obligatorio.")
            .MaximumLength(250)
            .WithMessage("El nombre no debe superar los 250 caracteres.");

        RuleFor(x => x.Objetivo)
            .MaximumLength(1000)
            .WithMessage("El objetivo no debe superar los 1000 caracteres.")
            .When(x => !string.IsNullOrWhiteSpace(x.Objetivo));

        RuleFor(x => x.Alcance)
            .MaximumLength(1000)
            .WithMessage("El alcance no debe superar los 1000 caracteres.")
            .When(x => !string.IsNullOrWhiteSpace(x.Alcance));

        RuleFor(x => x.Version)
            .GreaterThan(0)
            .WithMessage("La versión debe ser mayor a cero.");

        RuleFor(x => x.FechaEvaluacion)
            .NotEmpty()
            .WithMessage("La fecha de evaluación es obligatoria.");

        RuleFor(x => x.EstadoMatriz)
            .NotEmpty()
            .WithMessage("El estado de la matriz es obligatorio.")
            .MaximumLength(30)
            .WithMessage("El estado no debe superar los 30 caracteres.");

        RuleFor(x => x.Observaciones)
            .MaximumLength(3000)
            .WithMessage("Las observaciones no deben superar los 3000 caracteres.")
            .When(x => !string.IsNullOrWhiteSpace(x.Observaciones));

        RuleFor(x => x.InstitucionId)
            .GreaterThan(0)
            .WithMessage("Debe seleccionar una institución válida.");

        RuleFor(x => x.SedeId)
            .GreaterThan(0)
            .WithMessage("Debe seleccionar una sede válida.");

        RuleFor(x => x.AreaId)
            .GreaterThan(0)
            .WithMessage("Debe seleccionar un área válida.");

        RuleFor(x => x.ProcesoId)
            .GreaterThan(0)
            .WithMessage("Debe seleccionar un proceso válido.");

        RuleFor(x => x.ActividadId)
            .GreaterThan(0)
            .WithMessage("Debe seleccionar una actividad válida.");

        RuleFor(x => x.PuestoTrabajoId)
            .GreaterThan(0)
            .WithMessage("Debe seleccionar un puesto de trabajo válido.");

        RuleFor(x => x.ResponsableId)
            .GreaterThan(0)
            .WithMessage("Debe seleccionar un responsable válido.");
    }
}
