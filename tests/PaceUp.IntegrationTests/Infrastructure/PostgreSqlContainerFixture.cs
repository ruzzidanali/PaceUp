using Testcontainers.PostgreSql;

namespace PaceUp.IntegrationTests.Infrastructure;

public class PostgreSqlContainerFixture : IAsyncLifetime
{
    private readonly PostgreSqlContainer _container =
        new PostgreSqlBuilder("postgis/postgis:17-3.5")
            .WithDatabase("paceup_test")
            .WithUsername("paceup")
            .WithPassword("paceup_test_password")
            .Build();

    public string ConnectionString =>
        _container.GetConnectionString();

    public async Task InitializeAsync()
    {
        await _container.StartAsync();
    }

    public async Task DisposeAsync()
    {
        await _container.DisposeAsync();
    }
}