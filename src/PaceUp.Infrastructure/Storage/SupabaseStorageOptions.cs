namespace PaceUp.Infrastructure.Storage;

public sealed class SupabaseStorageOptions
{
    public string Url { get; set; } = string.Empty;

    public string ServiceRoleKey { get; set; } = string.Empty;

    public string BucketName { get; set; } = "profile-images";
}