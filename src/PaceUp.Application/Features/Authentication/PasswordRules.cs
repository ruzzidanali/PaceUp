namespace PaceUp.Application.Features.Authentication;

public static class PasswordRules
{
    public const int MinimumLength = 8;

    public static bool IsValid(string password)
    {
        if (string.IsNullOrEmpty(password) ||
            password.Length < MinimumLength)
        {
            return false;
        }

        return password.Any(char.IsUpper) &&
               password.Any(char.IsLower) &&
               password.Any(char.IsDigit) &&
               password.Any(IsSpecialCharacter);
    }

    private static bool IsSpecialCharacter(char character)
    {
        return !char.IsLetterOrDigit(character);
    }
}