using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;

namespace PaceUp.Api.Extensions;

public static class ClaimsPrincipalExtensions
{
    public static Guid GetUserId(
        this ClaimsPrincipal user)
    {
        var userIdClaim =
            user.FindFirst(
                ClaimTypes.NameIdentifier)
            ?? user.FindFirst(
                JwtRegisteredClaimNames.Sub);

        if (userIdClaim is null ||
            !Guid.TryParse(
                userIdClaim.Value,
                out var userId))
        {
            throw new UnauthorizedAccessException(
                "User ID claim is missing or invalid.");
        }

        return userId;
    }
}