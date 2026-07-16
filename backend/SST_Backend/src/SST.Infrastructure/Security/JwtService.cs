using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using SST.Application.Security.Interfaces;
using SST.Domain.Security.Entities;

namespace SST.Infrastructure.Security;

public sealed class JwtService : IJwtService
{
    private readonly IConfiguration _configuration;

    public JwtService(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    public string GenerarToken(
        Usuario usuario,
        IReadOnlyCollection<string> roles,
        out DateTime fechaExpiracion)
    {
        string clave = _configuration["Jwt:Key"]
            ?? throw new InvalidOperationException(
                "No se configuró Jwt:Key.");

        string issuer = _configuration["Jwt:Issuer"]
            ?? throw new InvalidOperationException(
                "No se configuró Jwt:Issuer.");

        string audience = _configuration["Jwt:Audience"]
            ?? throw new InvalidOperationException(
                "No se configuró Jwt:Audience.");

        int minutosExpiracion =
            int.TryParse(
                _configuration["Jwt:ExpirationMinutes"],
                out int minutos)
                ? minutos
                : 120;

        fechaExpiracion =
            DateTime.UtcNow.AddMinutes(minutosExpiracion);

        List<Claim> claims =
        [
            new Claim(
                JwtRegisteredClaimNames.Sub,
                usuario.Id.ToString()),

            new Claim(
                ClaimTypes.NameIdentifier,
                usuario.Id.ToString()),

            new Claim(
                ClaimTypes.Name,
                usuario.NombreUsuario),

            new Claim(
                "nombres",
                usuario.Nombres),

            new Claim(
                "apellidos",
                usuario.Apellidos),

            new Claim(
                "institucionId",
                usuario.InstitucionId.ToString()),

            new Claim(
                JwtRegisteredClaimNames.Jti,
                Guid.NewGuid().ToString())
        ];

        if (!string.IsNullOrWhiteSpace(usuario.Correo))
        {
            claims.Add(
                new Claim(
                    ClaimTypes.Email,
                    usuario.Correo));
        }

        foreach (string rol in roles)
        {
            claims.Add(new Claim(ClaimTypes.Role, rol));
        }

        SymmetricSecurityKey securityKey =
            new(Encoding.UTF8.GetBytes(clave));

        SigningCredentials credentials =
            new(
                securityKey,
                SecurityAlgorithms.HmacSha256);

        JwtSecurityToken token = new(
            issuer: issuer,
            audience: audience,
            claims: claims,
            notBefore: DateTime.UtcNow,
            expires: fechaExpiracion,
            signingCredentials: credentials);

        return new JwtSecurityTokenHandler()
            .WriteToken(token);
    }
}
