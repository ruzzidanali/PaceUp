namespace PaceUp.Infrastructure.Storage;

public interface IProfileImageStorage
{
    Task<string> UploadAsync(
        Stream fileStream,
        string fileName,
        string contentType,
        CancellationToken cancellationToken);

    Task DeleteAsync(
        string fileName,
        CancellationToken cancellationToken);
}