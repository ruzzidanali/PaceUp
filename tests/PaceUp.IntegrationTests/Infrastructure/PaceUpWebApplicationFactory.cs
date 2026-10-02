using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using PaceUp.Application.Abstractions.Communication;
using PaceUp.Infrastructure.Persistence;
using PaceUp.Infrastructure.Storage;
using PaceUp.IntegrationTests.Users;

namespace PaceUp.IntegrationTests.Infrastructure;

public class PaceUpWebApplicationFactory
    : WebApplicationFactory<Program>
{
    private readonly string _connectionString;

    public PaceUpWebApplicationFactory(
        PostgreSqlContainerFixture postgresFixture)
    {
        _connectionString =
            postgresFixture.ConnectionString;
    }

    protected override void ConfigureWebHost(
        IWebHostBuilder builder)
    {
        builder.UseEnvironment("Testing");

        builder.ConfigureServices(services =>
        {
            var emailServiceDescriptor =
                services.SingleOrDefault(
                    d =>
                        d.ServiceType ==
                        typeof(IEmailService));

            if (emailServiceDescriptor is not null)
            {
                services.Remove(emailServiceDescriptor);
            }

            services.AddSingleton<FakeEmailService>();

            services.AddSingleton<IEmailService>(
                provider =>
                    provider.GetRequiredService<FakeEmailService>());

            services.RemoveAll<IProfileImageStorage>();

            services.AddSingleton<FakeProfileImageStorage>();

            services.AddSingleton<IProfileImageStorage>(
                provider =>
                    provider.GetRequiredService<FakeProfileImageStorage>());

            var descriptor =
                services.SingleOrDefault(
                    d =>
                        d.ServiceType ==
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
                services
                    .BuildServiceProvider()
                    .CreateScope();

            var dbContext =
                scope.ServiceProvider
                    .GetRequiredService<PaceUpDbContext>();

            dbContext.Database.Migrate();
        });
    }

    public FakeEmailService GetFakeEmailService()
    {
        return Services
            .GetRequiredService<FakeEmailService>();
    }
}