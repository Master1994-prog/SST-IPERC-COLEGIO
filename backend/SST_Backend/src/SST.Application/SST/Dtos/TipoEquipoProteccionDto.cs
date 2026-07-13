namespace SST.Application.SST.Dtos;

/// <summary>
/// DTO utilizado para mostrar información de un tipo de Equipo de Protección Personal.
/// </summary>
public class TipoEquipoProteccionDto
{
    public long Id { get; set; }

    public string Codigo { get; set; } = string.Empty;

    public string Nombre { get; set; } = string.Empty;

    public string? Descripcion { get; set; }

    public int Orden { get; set; }

    public bool Activo { get; set; }

    public bool EsGlobal { get; set; }

    public long? ColegioId { get; set; }
}
