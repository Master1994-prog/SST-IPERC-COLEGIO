namespace SST.Application.SST.Dtos;

/// <summary>
/// DTO utilizado para mostrar la información de un peligro.
/// Un peligro representa una fuente, situación o condición que puede causar daño.
/// </summary>
public class PeligroDto
{
    /// <summary>
    /// Identificador único del peligro.
    /// </summary>
    public long Id { get; set; }

    /// <summary>
    /// Código único del peligro.
    /// Ejemplo: PEL-0001.
    /// </summary>
    public string Codigo { get; set; } = string.Empty;

    /// <summary>
    /// Nombre del peligro.
    /// Ejemplo: Piso mojado, exposición a ruido, trabajo en altura.
    /// </summary>
    public string Nombre { get; set; } = string.Empty;

    /// <summary>
    /// Descripción detallada del peligro.
    /// </summary>
    public string? Descripcion { get; set; }

    /// <summary>
    /// Id del tipo de peligro relacionado.
    /// </summary>
    public long TipoPeligroId { get; set; }

    /// <summary>
    /// Nombre del tipo de peligro relacionado.
    /// </summary>
    public string? TipoPeligroNombre { get; set; }

    /// <summary>
    /// Id de la categoría de peligro.
    /// Se obtiene desde el tipo de peligro.
    /// </summary>
    public long? CategoriaPeligroId { get; set; }

    /// <summary>
    /// Nombre de la categoría de peligro.
    /// Se obtiene desde el tipo de peligro.
    /// </summary>
    public string? CategoriaPeligroNombre { get; set; }

    /// <summary>
    /// Fuente que genera el peligro.
    /// </summary>
    public string? Fuente { get; set; }

    /// <summary>
    /// Medio por el cual se transmite el peligro.
    /// </summary>
    public string? Medio { get; set; }

    /// <summary>
    /// Persona o elemento expuesto al peligro.
    /// </summary>
    public string? Receptor { get; set; }

    /// <summary>
    /// Requisitos legales aplicables al peligro.
    /// </summary>
    public string? RequisitoLegal { get; set; }

    /// <summary>
    /// Recomendaciones generales para el peligro.
    /// </summary>
    public string? Recomendaciones { get; set; }

    /// <summary>
    /// Estado del peligro.
    /// true = activo, false = inactivo.
    /// </summary>
    public bool Activo { get; set; }
}
