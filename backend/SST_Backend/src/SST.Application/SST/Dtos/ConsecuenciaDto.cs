namespace SST.Application.SST.Dtos;

/// <summary>
/// DTO utilizado para mostrar la información de una consecuencia.
/// Una consecuencia representa el daño o efecto que puede generar un peligro.
/// </summary>
public class ConsecuenciaDto
{
    /// <summary>
    /// Identificador único de la consecuencia.
    /// </summary>
    public long Id { get; set; }

    /// <summary>
    /// Código de la consecuencia.
    /// Ejemplo: CONS-001.
    /// </summary>
    public string Codigo { get; set; } = string.Empty;

    /// <summary>
    /// Nombre de la consecuencia.
    /// Ejemplo: Golpes, fracturas, quemaduras, fatiga visual.
    /// </summary>
    public string Nombre { get; set; } = string.Empty;

    /// <summary>
    /// Descripción detallada de la consecuencia.
    /// </summary>
    public string? Descripcion { get; set; }

    /// <summary>
    /// Estado de la consecuencia.
    /// true = activo, false = inactivo.
    /// </summary>
    public bool Activo { get; set; }
}
