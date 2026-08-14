namespace PaceUp.Application.Abstractions.Authentication;

public interface IJwtTokenService
{
    string GenerateAccessToken(
        Guid userId,
        string username,
        string email);

    DateTime GetAccessTokenExpiration();
}