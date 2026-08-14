using PaceUp.Application.Abstractions.Authentication;

namespace PaceUp.UnitTests.Authentication;

public class FakeJwtTokenService : IJwtTokenService
{
    public string GenerateAccessToken(
        Guid userId,
        string username,
        string email)
    {
        return "test-access-token";
    }

    public DateTime GetAccessTokenExpiration()
    {
        return DateTime.UtcNow.AddHours(1);
    }
}