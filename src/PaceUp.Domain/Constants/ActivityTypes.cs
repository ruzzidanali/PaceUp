namespace PaceUp.Domain.Constants;

public static class ActivityTypes
{
    public const string Run = "Run";
    public const string Ride = "Ride";
    public const string Walk = "Walk";
    public const string Hike = "Hike";
    public const string Swim = "Swim";
    public const string Other = "Other";

    public static bool IsValid(string? type)
    {
        return type is
            Run or
            Ride or
            Walk or
            Hike or
            Swim or
            Other;
    }
}