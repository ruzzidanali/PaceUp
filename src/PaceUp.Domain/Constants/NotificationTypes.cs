namespace PaceUp.Domain.Constants;

public static class NotificationTypes
{
    public const string NewFollower = "NewFollower";
    public const string ChallengeJoined = "ChallengeJoined";
    public const string ActivityKudos = "ActivityKudos";
    public const string ActivityComment = "ActivityComment";

    public static bool IsValid(string? type)
    {
        return type is
            NewFollower or
            ChallengeJoined or
            ActivityKudos or
            ActivityComment;
    }
}