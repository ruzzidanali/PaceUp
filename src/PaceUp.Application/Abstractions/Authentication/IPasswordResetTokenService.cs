namespace PaceUp.Application.Abstractions.Authentication;

public interface IPasswordResetTokenService
{
    string GenerateToken();
}