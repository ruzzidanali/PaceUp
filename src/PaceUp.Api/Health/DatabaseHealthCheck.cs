using Microsoft.Extensions.Diagnostics.HealthChecks;
using PaceUp.Infrastructure.Persistence;

namespace PaceUp.Api.Health;

public class DatabaseHealthCheck : IHealthCheck
{
    private readonly PaceUpDbContext _dbContext;

    public DatabaseHealthCheck(
        PaceUpDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<HealthCheckResult> CheckHealthAsync(
        HealthCheckContext context,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var canConnect =
                await _dbContext.Database.CanConnectAsync(
                    cancellationToken);

            return canConnect
                ? HealthCheckResult.Healthy(
                    "PostgreSQL database is reachable.")
                : HealthCheckResult.Unhealthy(
                    "PostgreSQL database is not reachable.");
        }
        catch (Exception exception)
        {
            return HealthCheckResult.Unhealthy(
                "PostgreSQL database health check failed.",
                exception);
        }
    }
}