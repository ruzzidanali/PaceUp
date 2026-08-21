using PaceUp.Domain.Entities;

namespace PaceUp.UnitTests.Authentication;

public class EmailVerificationTokenTests
{
    [Fact]
    public void NewToken_ShouldNotBeExpired()
    {
        var token =
            new EmailVerificationToken(
                Guid.NewGuid(),
                "verification-token",
                DateTime.UtcNow.AddMinutes(30));

        Assert.False(token.IsExpired());
        Assert.False(token.IsUsed());
    }

    [Fact]
    public void ExpiredToken_ShouldBeExpired()
    {
        var token =
            new EmailVerificationToken(
                Guid.NewGuid(),
                "verification-token",
                DateTime.UtcNow.AddMinutes(-1));

        Assert.True(token.IsExpired());
        Assert.False(token.IsUsed());
    }

    [Fact]
    public void MarkAsUsed_ShouldMarkTokenAsUsed()
    {
        var token =
            new EmailVerificationToken(
                Guid.NewGuid(),
                "verification-token",
                DateTime.UtcNow.AddMinutes(30));

        token.MarkAsUsed();

        Assert.True(token.IsUsed());
    }
}