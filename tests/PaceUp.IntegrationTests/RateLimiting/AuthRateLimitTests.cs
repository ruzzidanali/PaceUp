using System.Net;
using System.Net.Http.Json;
using PaceUp.IntegrationTests.Infrastructure;

namespace PaceUp.IntegrationTests.RateLimiting;

public class AuthRateLimitTests : IClassFixture<PaceUpIntegrationFixture>,
    IDisposable
{
    private readonly RateLimitWebApplicationFactory _factory;
    private readonly HttpClient _client;

    public AuthRateLimitTests(
        PaceUpIntegrationFixture fixture)
    {
        _factory =
            new RateLimitWebApplicationFactory(
                fixture.Postgres);

        _client = _factory.CreateClient();
    }

    [Fact]
    public async Task Login_WhenRequestsExceedLimit_ShouldReturn429()
    {
        var responses = new List<HttpResponseMessage>();

        try
        {
            // First 10 requests should not be rate-limited.
            for (var i = 0; i < 10; i++)
            {
                var response =
                    await _client.PostAsJsonAsync(
                        "/api/auth/login",
                        new { });

                responses.Add(response);

                Assert.NotEqual(
                    HttpStatusCode.TooManyRequests,
                    response.StatusCode);
            }

            // The 11th request should be rejected.
            var eleventhResponse =
                await _client.PostAsJsonAsync(
                    "/api/auth/login",
                    new { });

            responses.Add(eleventhResponse);

            Assert.Equal(
                HttpStatusCode.TooManyRequests,
                eleventhResponse.StatusCode);
        }
        finally
        {
            foreach (var response in responses)
            {
                response.Dispose();
            }
        }
    }


    [Fact]
    public async Task Login_WhenDifferentIpAddresses_ShouldHaveSeparateLimits()
    {
        var responses = new List<HttpResponseMessage>();

        try
        {
            // Client A: consume all 10 requests.
            for (var i = 0; i < 10; i++)
            {
                var response = await SendLoginRequest(
                    _client,
                    "192.0.2.1");

                responses.Add(response);

                Assert.NotEqual(
                    HttpStatusCode.TooManyRequests,
                    response.StatusCode);
            }

            // Client A: request 11 should be rejected.
            var clientAResponse = await SendLoginRequest(
                _client,
                "192.0.2.1");

            responses.Add(clientAResponse);

            Assert.Equal(
                HttpStatusCode.TooManyRequests,
                clientAResponse.StatusCode);

            // Client B: a different IP should have its own limit.
            var clientBResponse = await SendLoginRequest(
                _client,
                "192.0.2.2");

            responses.Add(clientBResponse);

            Assert.NotEqual(
                HttpStatusCode.TooManyRequests,
                clientBResponse.StatusCode);
        }
        finally
        {
            foreach (var response in responses)
            {
                response.Dispose();
            }
        }
    }

    private static async Task<HttpResponseMessage> SendLoginRequest(
    HttpClient client,
    string ipAddress)
    {
        var request = new HttpRequestMessage(
            HttpMethod.Post,
            "/api/auth/login")
        {
            Content = JsonContent.Create(new { })
        };

        request.Headers.Add("X-Test-Remote-IP", ipAddress);

        return await client.SendAsync(request);
    }

    public void Dispose()
    {
        _client.Dispose();
        _factory.Dispose();
    }


}