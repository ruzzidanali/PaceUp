using Npgsql;
using Respawn;
using Respawn.Graph;

namespace PaceUp.IntegrationTests.Infrastructure;

public class PaceUpIntegrationFixture : IAsyncLifetime
{
    public PostgreSqlContainerFixture Postgres { get; } = new();

    public PaceUpWebApplicationFactory Factory { get; private set; } = null!;

    private Respawner _respawner = null!;

    public async Task InitializeAsync()
    {
        await Postgres.InitializeAsync();

        Factory =
            new PaceUpWebApplicationFactory(Postgres);

        await using var connection =
            new NpgsqlConnection(Postgres.ConnectionString);

        await connection.OpenAsync();

        _respawner =
            await Respawner.CreateAsync(
                connection,
                new RespawnerOptions
                {
                    DbAdapter = DbAdapter.Postgres,
                    SchemasToInclude =
                    [
                        "public"
                    ],
                    TablesToIgnore =
                    [
                        new("__EFMigrationsHistory")
                    ]
                });
    }

    public async Task ResetDatabaseAsync()
    {
        await using var connection =
            new NpgsqlConnection(Postgres.ConnectionString);

        await connection.OpenAsync();

        await using var command =
            new NpgsqlCommand(
                """
            TRUNCATE TABLE
                kudos,
                challenge_participants,
                challenges,
                notifications,
                follows,
                activities,
                goals,
                refresh_tokens,
                password_reset_tokens,
                email_verification_tokens,
                user_identities,
                users
            RESTART IDENTITY CASCADE;
            """,
                connection);

        await command.ExecuteNonQueryAsync();
    }

    public async Task DisposeAsync()
    {
        Factory.Dispose();

        await Postgres.DisposeAsync();
    }
}
