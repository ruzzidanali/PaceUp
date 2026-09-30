using System.Security.Cryptography;
using System.Text;

namespace PaceUp.Application.Features.Authentication;

public static class TokenHashing
{
    public static string Hash(string token)
    {
        var bytes =
            SHA256.HashData(
                Encoding.UTF8.GetBytes(token));

        return Convert.ToHexString(bytes);
    }
}