namespace SST.Application.SST.Dtos;

public class CategoriaPeligroDto
{
    public long Id { get; set; }

    public string Codigo { get; set; } = string.Empty;

    public string Nombre { get; set; } = string.Empty;

    public string? Descripcion { get; set; }

    public string? Color { get; set; }

    public string? Icono { get; set; }

    public int Orden { get; set; }

    public bool Activo { get; set; }
}
