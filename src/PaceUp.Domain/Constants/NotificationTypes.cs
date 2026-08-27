namespace PaceUp.Domain.Constants;

public static class NotificationTypes
{
    public const string NewFollower = "NewFollower";

    public const string ChallengeJoined = "ChallengeJoined";

    public static bool IsValid(string? type)
    {
        return type is
            NewFollower or
            ChallengeJoined;
    }
}