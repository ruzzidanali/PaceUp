namespace PaceUp.Domain.Constants;

public static class ChallengeTypes
{
    public const string Distance = "Distance";
    public const string Duration = "Duration";
    public const string Activities = "Activities";

    public static bool IsValid(string? type)
    {
        return type is
            Distance or
            Duration or
            Activities;
    }
}