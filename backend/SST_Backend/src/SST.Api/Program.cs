using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.HttpOverrides;
using Microsoft.AspNetCore.Identity;
using Microsoft.IdentityModel.Tokens;
using SST.Application.Security.Interfaces;
using SST.Domain.Security.Entities;
using SST.Infrastructure.DependencyInjection;
using SST.Infrastructure.Persistence;
using SST.Infrastructure.Persistence.Seed;
using SST.Infrastructure.Security;

namespace SST.Api
{
    public class Program
    {
        public static void Main(string[] args)
        {
            var builder = WebApplication.CreateBuilder(args);

            builder.Services.AddControllers();
            builder.Services.AddOpenApi();
            builder.Services.AddInfrastructure(builder.Configuration);
            builder.Services.AddEndpointsApiExplorer();
            builder.Services.AddSwaggerGen();

            builder.Services.AddScoped<IPasswordHasher<Usuario>, PasswordHasher<Usuario>>();
            builder.Services.AddScoped<IJwtService, JwtService>();
            builder.Services.AddScoped<IAuthService, AuthService>();

            var allowedOrigins =
                builder.Configuration
                    .GetSection("Cors:AllowedOrigins")
                    .Get<string[]>()
                ?? Array.Empty<string>();

            builder.Services.AddCors(options =>
            {
                options.AddPolicy("SstCors", policy =>
                {
                    policy.AllowAnyHeader().AllowAnyMethod();

                    if (allowedOrigins.Length > 0)
                    {
                        policy.WithOrigins(allowedOrigins);
                    }
                });
            });

            builder.Services.Configure<ForwardedHeadersOptions>(options =>
            {
                options.ForwardedHeaders =
                    ForwardedHeaders.XForwardedFor |
                    ForwardedHeaders.XForwardedProto;
            });

            string jwtKey = builder.Configuration["Jwt:Key"] ?? string.Empty;
            string jwtIssuer = builder.Configuration["Jwt:Issuer"] ?? string.Empty;
            string jwtAudience = builder.Configuration["Jwt:Audience"] ?? string.Empty;

            if (string.IsNullOrWhiteSpace(jwtKey) ||
                Encoding.UTF8.GetByteCount(jwtKey) < 32)
            {
                throw new InvalidOperationException(
                    "Jwt:Key no esta configurado o tiene menos de 32 bytes. " +
                    "Use Jwt__Key como variable de entorno en produccion.");
            }

            if (string.IsNullOrWhiteSpace(jwtIssuer))
            {
                throw new InvalidOperationException("Jwt:Issuer no esta configurado.");
            }

            if (string.IsNullOrWhiteSpace(jwtAudience))
            {
                throw new InvalidOperationException("Jwt:Audience no esta configurado.");
            }

            builder.Services
                .AddAuthentication(options =>
                {
                    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
                    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
                })
                .AddJwtBearer(options =>
                {
                    options.TokenValidationParameters = new TokenValidationParameters
                    {
                        ValidateIssuer = true,
                        ValidateAudience = true,
                        ValidateLifetime = true,
                        ValidateIssuerSigningKey = true,
                        ValidIssuer = jwtIssuer,
                        ValidAudience = jwtAudience,
                        IssuerSigningKey =
                            new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey)),
                        ClockSkew = TimeSpan.Zero
                    };
                });

            builder.Services.AddAuthorization();

            bool runSeedOnStartup =
                builder.Configuration.GetValue<bool?>("Database:RunSeedOnStartup")
                ?? builder.Environment.IsDevelopment();

            var app = builder.Build();

            if (runSeedOnStartup)
            {
                using var scope = app.Services.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<SSTDbContext>();

                SSTSeedData.SeedAsync(context).GetAwaiter().GetResult();
                SuperAdminBootstrap.EjecutarAsync(context).GetAwaiter().GetResult();
            }

            if (app.Environment.IsDevelopment())
            {
                app.UseSwagger();
                app.UseSwaggerUI();
                app.MapOpenApi();
            }

            app.UseForwardedHeaders();

            if (!app.Environment.IsDevelopment())
            {
                app.UseHsts();
            }

            app.UseHttpsRedirection();
            app.UseCors("SstCors");

            // En produccion wwwroot/uploads debe ser persistente.
            app.UseStaticFiles();

            app.UseAuthentication();
            app.UseAuthorization();

            app.MapGet("/health", () => Results.Ok(new
            {
                status = "ok",
                service = "SST.Api"
            })).AllowAnonymous();

            app.MapControllers();
            app.Run();
        }
    }
}