using System.Net.Http.Headers;
using Microsoft.Extensions.Options;

namespace PaceUp.Infrastructure.Storage;

public sealed class SupabaseStorageService : IProfileImageStorage
{
    private readonly HttpClient _httpClient;
    private readonly SupabaseStorageOptions _options;

    public SupabaseStorageService(
        HttpClient httpClient,
        IOptions<SupabaseStorageOptions> options)
    {
        _httpClient = httpClient;
        _options = options.Value;
    }

    public async Task<string> UploadAsync(
        Stream fileStream,
        string fileName,
        string contentType,
        CancellationToken cancellationToken)
    {
        var url =
            $"{_options.Url.TrimEnd('/')}/storage/v1/object/" +
            $"{Uri.EscapeDataString(_options.BucketName)}/" +
            $"{Uri.EscapeDataString(fileName)}";

        using var request = new HttpRequestMessage(
            HttpMethod.Post,
            url);

        request.Headers.Authorization =
            new AuthenticationHeaderValue(
                "Bearer",
                _options.ServiceRoleKey);

        request.Headers.Add(
            "apikey",
            _options.ServiceRoleKey);

        request.Headers.Add(
            "x-upsert",
            "false");

        request.Content = new StreamContent(fileStream);

        request.Content.Headers.ContentType =
            new MediaTypeHeaderValue(contentType);

        using var response =
            await _httpClient.SendAsync(
                request,
                cancellationToken);

        if (!response.IsSuccessStatusCode)
        {
            var responseBody =
                await response.Content.ReadAsStringAsync(
                    cancellationToken);

            throw new InvalidOperationException(
                $"Supabase Storage upload failed: " +
                $"{(int)response.StatusCode} {responseBody}");
        }

        return
            $"{_options.Url.TrimEnd('/')}/storage/v1/object/public/" +
            $"{Uri.EscapeDataString(_options.BucketName)}/" +
            $"{Uri.EscapeDataString(fileName)}";
    }

    public async Task DeleteAsync(
        string fileName,
        CancellationToken cancellationToken)
    {
        var url =
            $"{_options.Url.TrimEnd('/')}/storage/v1/object/" +
            $"{Uri.EscapeDataString(_options.BucketName)}/" +
            $"{Uri.EscapeDataString(fileName)}";

        using var request = new HttpRequestMessage(
            HttpMethod.Delete,
            url);

        request.Headers.Authorization =
            new AuthenticationHeaderValue(
                "Bearer",
                _options.ServiceRoleKey);

        request.Headers.Add(
            "apikey",
            _options.ServiceRoleKey);

        using var response =
            await _httpClient.SendAsync(
                request,
                cancellationToken);

        if (!response.IsSuccessStatusCode)
        {
            var responseBody =
                await response.Content.ReadAsStringAsync(
                    cancellationToken);

            throw new InvalidOperationException(
                $"Supabase Storage delete failed: " +
                $"{(int)response.StatusCode} {responseBody}");
        }
    }
}