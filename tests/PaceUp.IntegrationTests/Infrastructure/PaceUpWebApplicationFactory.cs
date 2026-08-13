using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using PaceUp.Infrastructure.Persistence;

namespace PaceUp.IntegrationTests.Infrastructure;

public class PaceUpWebApplicationFactory
    : WebApplicationFactory<Program>
{
    private readonly string _connectionString;

    public PaceUpWebApplicationFactory(
        string connectionString)
    {
        _connectionString = connectionString;
    }

    protected override void ConfigureWebHost(
        IWebHostBuilder builder)
    {
        builder.UseEnvironment("Testing");

        builder.ConfigureServices(services =>
        {
            var descriptor = services
                .SingleOrDefault(
                    d => d.ServiceType ==
                         typeof(DbContextOptions<PaceUpDbContext>));

            if (descriptor is not null)
            {
                services.Remove(descriptor);
            }

            services.AddDbContext<PaceUpDbContext>(
                options =>
                {
                    options.UseNpgsql(
                        _connectionString,
                        npgsqlOptions =>
                        {
                            npgsqlOptions
                                .UseNetTopologySuite();
                        });
                });

            using var scope =
                services.BuildServiceProvider()
                    .CreateScope();

            var dbContext =
                scope.ServiceProvider
                    .GetRequiredService<PaceUpDbContext>();

            dbContext.Database.Migrate();
        });
    }
}