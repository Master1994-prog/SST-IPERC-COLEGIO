namespace SST.Application.SST.Dtos;

/// <summary>
/// DTO utilizado para mostrar información de un control.
/// Un control es una medida aplicada para reducir o eliminar un riesgo.
/// </summary>
public class ControlDto
{
    /// <summary>
    /// Identificador único del control.
    /// </summary>
    public long Id { get; set; }

    /// <summary>
    /// Código del control.
    /// Ejemplo: CTRL-001.
    /// </summary>
    public string Codigo { get; set; } = string.Empty;

    /// <summary>
    /// Nombre del control.
    /// Ejemplo: Señalización de seguridad, uso de EPP, mantenimiento preventivo.
    /// </summary>
    public string Nombre { get; set; } = string.Empty;

    /// <summary>
    /// Descripción detallada del control.
    /// </summary>
    public string? Descripcion { get; set; }

    /// <summary>
    /// Estado del control.
    /// true = activo, false = inactivo.
    /// </summary>
    public bool Activo { get; set; }
}
