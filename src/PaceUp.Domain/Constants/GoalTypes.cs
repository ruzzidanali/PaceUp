namespace PaceUp.Domain.Constants;

public static class GoalTypes
{
    public const string Distance = "Distance";
    public const string Duration = "Duration";
    public const string Calories = "Calories";
    public const string Activities = "Activities";

    public static bool IsValid(string type)
    {
        return type is
            Distance or
            Duration or
            Calories or
            Activities;
    }
}