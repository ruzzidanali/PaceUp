namespace PaceUp.IntegrationTests.Infrastructure;

public class PaceUpIntegrationFixture : IAsyncLifetime
{
    public PostgreSqlContainerFixture Postgres { get; } = new();

    public PaceUpWebApplicationFactory Factory { get; private set; } = null!;

    public async Task InitializeAsync()
    {
        await Postgres.InitializeAsync();

        Factory =
            new PaceUpWebApplicationFactory(Postgres);
    }

    public async Task DisposeAsync()
    {
        Factory.Dispose();

        await Postgres.DisposeAsync();
    }
}