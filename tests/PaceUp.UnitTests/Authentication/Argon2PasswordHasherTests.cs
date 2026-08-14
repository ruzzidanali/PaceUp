using PaceUp.Infrastructure.Authentication;

namespace PaceUp.UnitTests.Authentication;

public class Argon2PasswordHasherTests
{
    [Fact]
    public void Hash_ShouldProduceDifferentHashesForSamePassword()
    {
        var hasher = new Argon2PasswordHasher();

        var password = "MySecurePassword123!";

        var firstHash = hasher.Hash(password);
        var secondHash = hasher.Hash(password);

        Assert.NotEqual(firstHash, secondHash);
    }

    [Fact]
    public void Verify_ShouldReturnTrueForCorrectPassword()
    {
        var hasher = new Argon2PasswordHasher();

        var password = "MySecurePassword123!";

        var hash = hasher.Hash(password);

        var result = hasher.Verify(
            password,
            hash);

        Assert.True(result);
    }

    [Fact]
    public void Verify_ShouldReturnFalseForIncorrectPassword()
    {
        var hasher = new Argon2PasswordHasher();

        var password = "MySecurePassword123!";

        var hash = hasher.Hash(password);

        var result = hasher.Verify(
            "WrongPassword123!",
            hash);

        Assert.False(result);
    }

    [Fact]
    public void Hash_ShouldContainArgon2idFormat()
    {
        var hasher = new Argon2PasswordHasher();

        var hash = hasher.Hash(
            "MySecurePassword123!");

        Assert.StartsWith(
            "argon2id$",
            hash);

        var parts = hash.Split('$');

        Assert.Equal(3, parts.Length);
    }
}