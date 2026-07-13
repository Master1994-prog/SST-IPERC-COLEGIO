namespace SST.Application.SST.Dtos;

/// <summary>
/// DTO utilizado para mostrar la información de un tipo de peligro.
/// </summary>
public class TipoPeligroDto
{
    public long Id { get; set; }

    /// <summary>
    /// Código único del tipo de peligro.
    /// </summary>
    public string Codigo { get; set; } = string.Empty;

    public string Nombre { get; set; } = string.Empty;

    public string? Descripcion { get; set; }

    public long CategoriaPeligroId { get; set; }

    public string? CategoriaPeligroNombre { get; set; }

    public bool Activo { get; set; }
}
