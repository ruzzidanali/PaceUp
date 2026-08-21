namespace PaceUp.Application.Abstractions.Authentication;

public interface IEmailVerificationTokenService
{
    string GenerateToken();
}