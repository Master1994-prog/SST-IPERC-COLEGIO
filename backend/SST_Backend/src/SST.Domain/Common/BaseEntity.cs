namespace SST.Domain.Common;

/// <summary>
/// Clase base para todas las entidades del dominio.
/// Contiene la llave primaria utilizada por Entity Framework.
/// </summary>
public abstract class BaseEntity
{
    /// <summary>
    /// Identificador único de la entidad.
    /// </summary>
    public long Id { get; set; }
}