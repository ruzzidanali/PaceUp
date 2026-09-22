namespace PaceUp.Domain.Constants;

public static class XpSourceTypes
{
    public const string Activity = "Activity";
    public const string Achievement = "Achievement";
    public const string Challenge = "Challenge";

    public static bool IsValid(string? sourceType)
    {
        return sourceType is
            Activity or
            Achievement or
            Challenge;
    }
}