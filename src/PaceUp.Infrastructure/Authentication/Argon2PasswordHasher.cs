using System.Security.Cryptography;
using System.Text;
using Konscious.Security.Cryptography;
using PaceUp.Application.Abstractions.Authentication;

namespace PaceUp.Infrastructure.Authentication;

public class Argon2PasswordHasher : IPasswordHasher
{
    private const int SaltSize = 16;
    private const int HashSize = 32;

    private const int DegreeOfParallelism = 4;
    private const int MemorySize = 65536;
    private const int Iterations = 3;

    public string Hash(string password)
    {
        ArgumentException.ThrowIfNullOrEmpty(password);

        var salt = RandomNumberGenerator.GetBytes(SaltSize);

        var passwordBytes = Encoding.UTF8.GetBytes(password);

        var argon2 = new Argon2id(passwordBytes)
        {
            Salt = salt,
            DegreeOfParallelism = DegreeOfParallelism,
            MemorySize = MemorySize,
            Iterations = Iterations
        };

        var hash = argon2.GetBytes(HashSize);

        return string.Join(
            "$",
            "argon2id",
            Convert.ToBase64String(salt),
            Convert.ToBase64String(hash));
    }

    public bool Verify(
        string password,
        string passwordHash)
    {
        ArgumentException.ThrowIfNullOrEmpty(password);
        ArgumentException.ThrowIfNullOrEmpty(passwordHash);

        var parts = passwordHash.Split('$');

        if (parts.Length != 3 ||
            parts[0] != "argon2id")
        {
            return false;
        }

        var salt = Convert.FromBase64String(parts[1]);
        var expectedHash = Convert.FromBase64String(parts[2]);

        var passwordBytes = Encoding.UTF8.GetBytes(password);

        var argon2 = new Argon2id(passwordBytes)
        {
            Salt = salt,
            DegreeOfParallelism = DegreeOfParallelism,
            MemorySize = MemorySize,
            Iterations = Iterations
        };

        var actualHash = argon2.GetBytes(expectedHash.Length);

        return CryptographicOperations.FixedTimeEquals(
            actualHash,
            expectedHash);
    }
}