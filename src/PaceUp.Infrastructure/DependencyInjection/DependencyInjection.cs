using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using PaceUp.Application.Abstractions.Persistence;
using PaceUp.Infrastructure.Persistence;

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

        return services;
    }
}