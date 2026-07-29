namespace SST.Application.SST.Dtos;

/// <summary>
/// DTO utilizado para devolver información
/// de una medida de control.
/// </summary>
public class ControlDto
{
    /// <summary>
    /// Identificador único.
    /// </summary>
    public long Id { get; set; }

    /// <summary>
    /// Código generado por el sistema.
    /// </summary>
    public string Codigo { get; set; } = string.Empty;

    /// <summary>
    /// Nombre del control.
    /// </summary>
    public string Nombre { get; set; } = string.Empty;

    /// <summary>
    /// Descripción del control.
    /// </summary>
    public string? Descripcion { get; set; }

    /// <summary>
    /// Identificador de la clasificación.
    /// </summary>
    public long ClasificacionControlId { get; set; }

    /// <summary>
    /// Nombre de la clasificación.
    /// </summary>
    public string ClasificacionControlNombre { get; set; }
        = string.Empty;

    /// <summary>
    /// Estado activo del control.
    /// </summary>
    public bool Activo { get; set; }

    /// <summary>
    /// Estado lógico heredado.
    /// </summary>
    public bool Estado { get; set; }

    /// <summary>
    /// Fecha de registro.
    /// </summary>
    public DateTime FechaRegistro { get; set; }

    /// <summary>
    /// Fecha de actualización.
    /// </summary>
    public DateTime? FechaActualizacion { get; set; }
}
