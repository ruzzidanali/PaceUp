namespace PaceUp.Domain.Constants;

public static class NotificationTypes
{
    public const string NewFollower = "NewFollower";
    public const string ChallengeJoined = "ChallengeJoined";
    public const string ChallengeCompleted = "ChallengeCompleted";
    public const string ActivityKudos = "ActivityKudos";
    public const string ActivityComment = "ActivityComment";
    public const string AchievementUnlocked = "AchievementUnlocked";

    public static bool IsValid(string? type)
    {
        return type is
            NewFollower or
            ChallengeJoined or
            ChallengeCompleted or
            ActivityKudos or
            ActivityComment or
            AchievementUnlocked;
    }
}