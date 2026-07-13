using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using SST.Domain.Common;

namespace SST.Domain.Security.Entities;

[Table("Usuarios")]
public class Usuario : BaseAuditableEntity
{
    #region Información Personal

    [Required]
    [MaxLength(100)]
    public string Nombres { get; set; } = string.Empty;

    [Required]
    [MaxLength(100)]
    public string Apellidos { get; set; } = string.Empty;

    [MaxLength(20)]
    public string? NumeroDocumento { get; set; }

    [MaxLength(20)]
    public string? TipoDocumento { get; set; }

    [MaxLength(150)]
    public string? Correo { get; set; }

    [MaxLength(20)]
    public string? Telefono { get; set; }

    #endregion

    #region Acceso

    [Required]
    [MaxLength(80)]
    public string NombreUsuario { get; set; } = string.Empty;

    [Required]
    [MaxLength(500)]
    public string PasswordHash { get; set; } = string.Empty;

    public bool DebeCambiarPassword { get; set; } = true;

    public DateTime? UltimoAcceso { get; set; }

    #endregion

    #region Organización

    public long InstitucionId { get; set; }

    public long? SedeId { get; set; }

    public long? AreaId { get; set; }

    #endregion

    #region Gestión

    public bool Activo { get; set; } = true;

    #endregion

    #region Métodos de Dominio

    public void Activar()
    {
        Activo = true;
    }

    public void Desactivar()
    {
        Activo = false;
    }

    public void RegistrarAcceso()
    {
        UltimoAcceso = DateTime.UtcNow;
    }

    public void CambiarPassword(string passwordHash)
    {
        PasswordHash = passwordHash;
        DebeCambiarPassword = false;
    }

    #endregion
}
