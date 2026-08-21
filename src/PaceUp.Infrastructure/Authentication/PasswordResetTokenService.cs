using System.Security.Cryptography;
using PaceUp.Application.Abstractions.Authentication;

namespace PaceUp.Infrastructure.Authentication;

public class PasswordResetTokenService
    : IPasswordResetTokenService
{
    public string GenerateToken()
    {
        var bytes = RandomNumberGenerator.GetBytes(32);

        return Convert.ToBase64String(bytes);
    }
}