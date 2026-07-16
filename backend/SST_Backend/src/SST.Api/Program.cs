using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.IdentityModel.Tokens;
using SST.Application.Security.Interfaces;
using SST.Domain.Security.Entities;
using SST.Infrastructure.Security;
using SST.Infrastructure.DependencyInjection;
using SST.Infrastructure.Persistence;
using SST.Infrastructure.Persistence.Seed;

namespace SST.Api
{
    public class Program
    {
        public static void Main(string[] args)
        {
            var builder = WebApplication.CreateBuilder(args);

            // Add services to the container.

            builder.Services.AddControllers();
            // Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
            builder.Services.AddOpenApi();

            builder.Services.AddInfrastructure(builder.Configuration);

            // Habilita Swagger para documentar y probar la API.
            builder.Services.AddEndpointsApiExplorer();

            builder.Services.AddSwaggerGen();

            builder.Services.AddScoped<
                IPasswordHasher<Usuario>,
                PasswordHasher<Usuario>>();

            builder.Services.AddScoped<IJwtService, JwtService>();
            builder.Services.AddScoped<IAuthService, AuthService>();

            string jwtKey = builder.Configuration["Jwt:Key"]
                ?? throw new InvalidOperationException(
                    "No se configuró Jwt:Key.");

            string jwtIssuer = builder.Configuration["Jwt:Issuer"]
                ?? throw new InvalidOperationException(
                    "No se configuró Jwt:Issuer.");

            string jwtAudience = builder.Configuration["Jwt:Audience"]
                ?? throw new InvalidOperationException(
                    "No se configuró Jwt:Audience.");

            builder.Services
                .AddAuthentication(options =>
                {
                    options.DefaultAuthenticateScheme =
                        JwtBearerDefaults.AuthenticationScheme;

                    options.DefaultChallengeScheme =
                        JwtBearerDefaults.AuthenticationScheme;
                })
                .AddJwtBearer(options =>
                {
                    options.TokenValidationParameters =
                        new TokenValidationParameters
                        {
                            ValidateIssuer = true,
                            ValidateAudience = true,
                            ValidateLifetime = true,
                            ValidateIssuerSigningKey = true,

                            ValidIssuer = jwtIssuer,
                            ValidAudience = jwtAudience,

                            IssuerSigningKey =
                                new SymmetricSecurityKey(
                                    Encoding.UTF8.GetBytes(jwtKey)),

                            ClockSkew = TimeSpan.Zero
                        };
                });

            builder.Services.AddAuthorization();

            var app = builder.Build();

            using (var scope = app.Services.CreateScope())
            {
                var context = scope.ServiceProvider.GetRequiredService<SSTDbContext>();

                SSTSeedData.SeedAsync(context).GetAwaiter().GetResult();
            }

            // Activa Swagger solo en entorno de desarrollo.
            if (app.Environment.IsDevelopment())
            {
                app.UseSwagger();
                app.UseSwaggerUI();
            }

            // Configure the HTTP request pipeline.
            if (app.Environment.IsDevelopment())
            {
                app.MapOpenApi();
            }

            app.UseHttpsRedirection();

            app.UseAuthentication();

            app.UseAuthorization();


            app.MapControllers();

            app.Run();
        }
    }
}
