using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using PaceUp.Application.Abstractions.Persistence;
using PaceUp.Infrastructure.Persistence;
using PaceUp.Application.Abstractions.Authentication;
using PaceUp.Infrastructure.Authentication;
using PaceUp.Application.Abstractions.Communication;
using PaceUp.Infrastructure.Communication;
using Resend;

namespace PaceUp.Infrastructure.DependencyInjection;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        services.AddDbContext<PaceUpDbContext>(options =>
        {
            options.UseNpgsql(
                configuration.GetConnectionString(
                    "DefaultConnection"),
                npgsqlOptions =>
                {
                    npgsqlOptions.UseNetTopologySuite();
                });
        });

        services.AddScoped<IApplicationDbContext>(
            provider =>
                provider.GetRequiredService<PaceUpDbContext>());

        services.AddSingleton<IPasswordHasher, Argon2PasswordHasher>();

        services.AddScoped<IJwtTokenService, JwtTokenService>();

        services.AddScoped<IRefreshTokenService, RefreshTokenService>();

        services.AddScoped<IEmailVerificationTokenService, EmailVerificationTokenService>();

        services.AddScoped<IPasswordResetTokenService, PasswordResetTokenService>();

        services.AddScoped<IEmailService, EmailService>();

        services.AddOptions();

        services.AddHttpClient<ResendClient>();

        services.Configure<ResendClientOptions>(options =>
        {
            options.ApiToken =
                Environment.GetEnvironmentVariable("RESEND_API_KEY")
                ?? string.Empty;
        });

        services.AddTransient<IResend, ResendClient>();

        return services;
    }
}