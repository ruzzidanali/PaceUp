using System.Net;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Extensions.DependencyInjection;

namespace PaceUp.IntegrationTests.Infrastructure;

public class RateLimitWebApplicationFactory
    : PaceUpWebApplicationFactory
{
    public RateLimitWebApplicationFactory(
        PostgreSqlContainerFixture postgresFixture)
        : base(postgresFixture)
    {
    }

    protected override void ConfigureWebHost(
        IWebHostBuilder builder)
    {
        builder.UseSetting(
            "Testing:EnableRateLimiter",
            "true");

        builder.ConfigureServices(services =>
        {
            services.AddSingleton<IStartupFilter,
                TestRemoteIpStartupFilter>();
        });

        base.ConfigureWebHost(builder);
    }
}

public sealed class TestRemoteIpStartupFilter : IStartupFilter
{
    public Action<IApplicationBuilder> Configure(
        Action<IApplicationBuilder> next)
    {
        return app =>
        {
            app.Use(async (context, nextMiddleware) =>
            {
                if (context.Request.Headers.TryGetValue(
                    "X-Test-Remote-IP",
                    out var value) &&
                    IPAddress.TryParse(
                        value.ToString(),
                        out var ipAddress))
                {
                    context.Connection.RemoteIpAddress = ipAddress;
                }

                await nextMiddleware();
            });

            next(app);
        };
    }
}
