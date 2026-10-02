using PaceUp.Infrastructure.Storage;

namespace PaceUp.IntegrationTests.Users;

public sealed class FakeProfileImageStorage : IProfileImageStorage
{
    private readonly Dictionary<string, byte[]> _files = [];

    public IReadOnlyDictionary<string, byte[]> Files => _files;

    public List<string> DeletedFiles { get; } = [];

    public Task<string> UploadAsync(
        Stream fileStream,
        string fileName,
        string contentType,
        CancellationToken cancellationToken)
    {
        using var memoryStream = new MemoryStream();

        fileStream.CopyTo(memoryStream);

        _files[fileName] = memoryStream.ToArray();

        var imageUrl =
            $"https://fake-storage.local/profile-images/{fileName}";

        return Task.FromResult(imageUrl);
    }

    public Task DeleteAsync(
        string fileName,
        CancellationToken cancellationToken)
    {
        _files.Remove(fileName);

        DeletedFiles.Add(fileName);

        return Task.CompletedTask;
    }
}