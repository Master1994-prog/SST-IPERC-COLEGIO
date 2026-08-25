using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using SST.Domain.Common;

namespace SST.Domain.Security.Entities;

/// <summary>
/// Representa un usuario del sistema SST EduRisk.
/// </summary>
[Table("Usuarios")]
public class Usuario : BaseAuditableEntity
{
    /// <summary>
    /// Cantidad máxima de inicios de sesión permitidos
    /// antes de obligar al usuario a cambiar su contraseña.
    /// </summary>
    public const int MaximoSesionesAntesCambioPassword = 30;

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

    /// <summary>
    /// Indica si el usuario debe cambiar su contraseña
    /// antes de continuar utilizando la aplicación.
    ///
    /// Se utiliza en dos escenarios:
    /// 1. Contraseña temporal asignada por un administrador.
    /// 2. El usuario alcanzó 30 sesiones desde su último cambio.
    /// </summary>
    public bool DebeCambiarPassword { get; set; } = true;

    /// <summary>
    /// Fecha y hora UTC del último inicio de sesión correcto.
    /// </summary>
    public DateTime? UltimoAcceso { get; set; }

    /// <summary>
    /// Cantidad de sesiones online realizadas desde
    /// el último cambio válido de contraseña.
    ///
    /// Valores esperados:
    /// 0  = contraseña recién cambiada.
    /// 5  = primer recordatorio.
    /// 10 = segundo recordatorio.
    /// 15 = tercer recordatorio.
    /// 20 = cuarto recordatorio.
    /// 25 = quinto recordatorio.
    /// 30 = cambio obligatorio.
    /// </summary>
    public int SesionesDesdeCambioPassword { get; set; } = 0;

    #endregion

    #region Organización

    public long InstitucionId { get; set; }

    public long? SedeId { get; set; }

    public long? AreaId { get; set; }

    #endregion

    #region Gestión

    public bool Activo { get; set; } = true;

    #endregion

    #region Roles

    public virtual ICollection<UsuarioRol> UsuariosRoles { get; set; }
        = new List<UsuarioRol>();

    #endregion

    #region Métodos de Dominio

    /// <summary>
    /// Activa la cuenta del usuario.
    /// </summary>
    public void Activar()
    {
        Activo = true;
    }

    /// <summary>
    /// Desactiva la cuenta del usuario.
    /// </summary>
    public void Desactivar()
    {
        Activo = false;
    }

    /// <summary>
    /// Registra un inicio de sesión online correcto.
    ///
    /// Si existe un cambio obligatorio pendiente, no incrementa
    /// el contador porque el usuario todavía no debe entrar
    /// normalmente al sistema.
    ///
    /// Cuando llega a 30 sesiones, marca automáticamente
    /// DebeCambiarPassword = true.
    /// </summary>
    public void RegistrarAcceso()
    {
        UltimoAcceso = DateTime.UtcNow;

        // Si ya existe un cambio obligatorio pendiente,
        // no incrementamos nuevamente el contador.
        if (DebeCambiarPassword)
        {
            return;
        }

        if (SesionesDesdeCambioPassword <
            MaximoSesionesAntesCambioPassword)
        {
            SesionesDesdeCambioPassword++;
        }

        if (SesionesDesdeCambioPassword >=
            MaximoSesionesAntesCambioPassword)
        {
            SesionesDesdeCambioPassword =
                MaximoSesionesAntesCambioPassword;

            DebeCambiarPassword = true;
        }
    }

    /// <summary>
    /// Establece una contraseña y define si el usuario
    /// deberá cambiarla en su próximo inicio de sesión.
    ///
    /// Siempre reinicia el contador a cero.
    ///
    /// Úsalo cuando:
    /// - SUPER_ADMIN asigne una contraseña temporal.
    /// - se realice una recuperación de contraseña.
    /// - se cambie administrativamente la contraseña.
    /// </summary>
    public void EstablecerPassword(
        string passwordHash,
        bool debeCambiarPassword)
    {
        if (string.IsNullOrWhiteSpace(passwordHash))
        {
            throw new ArgumentException(
                "El hash de la contraseña es obligatorio.",
                nameof(passwordHash));
        }

        PasswordHash = passwordHash;
        DebeCambiarPassword = debeCambiarPassword;
        SesionesDesdeCambioPassword = 0;
    }

    /// <summary>
    /// Registra un cambio de contraseña realizado
    /// correctamente por el propio usuario.
    ///
    /// Después del cambio:
    /// - DebeCambiarPassword = false.
    /// - SesionesDesdeCambioPassword = 0.
    /// </summary>
    public void CambiarPassword(
        string passwordHash)
    {
        EstablecerPassword(
            passwordHash,
            debeCambiarPassword: false);
    }

    /// <summary>
    /// Fuerza al usuario a cambiar su contraseña
    /// en el siguiente acceso.
    ///
    /// Si se utiliza por vencimiento de sesiones,
    /// conserva el contador en el máximo permitido.
    /// </summary>
    public void ForzarCambioPassword()
    {
        DebeCambiarPassword = true;
    }

    /// <summary>
    /// Devuelve cuántas sesiones faltan para llegar
    /// al cambio obligatorio de contraseña.
    /// </summary>
    [NotMapped]
    public int SesionesRestantesCambioPassword
    {
        get
        {
            int restantes =
                MaximoSesionesAntesCambioPassword -
                SesionesDesdeCambioPassword;

            return Math.Max(
                0,
                restantes);
        }
    }

    /// <summary>
    /// Indica si corresponde mostrar uno de los recordatorios
    /// de seguridad de las sesiones 5, 10, 15, 20 o 25.
    /// </summary>
    [NotMapped]
    public bool DebeRecordarCambioPassword
    {
        get
        {
            return !DebeCambiarPassword &&
                   SesionesDesdeCambioPassword > 0 &&
                   SesionesDesdeCambioPassword <
                       MaximoSesionesAntesCambioPassword &&
                   SesionesDesdeCambioPassword % 5 == 0;
        }
    }

    #endregion
}