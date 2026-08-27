using PaceUp.Domain.Entities;

namespace PaceUp.UnitTests.Challenges;

public class ChallengeTests
{
    [Fact]
    public void Constructor_ShouldCreateChallenge()
    {
        var userId = Guid.NewGuid();
        var startDate = DateTime.UtcNow.Date;
        var endDate = startDate.AddDays(6);

        var challenge = new Challenge(
            userId,
            "Run 50 KM",
            "Complete 50 KM this week.",
            "Distance",
            50,
            startDate,
            endDate);

        Assert.NotEqual(Guid.Empty, challenge.Id);
        Assert.Equal(userId, challenge.CreatedByUserId);
        Assert.Equal("Run 50 KM", challenge.Name);
        Assert.Equal(
            "Complete 50 KM this week.",
            challenge.Description);
        Assert.Equal("Distance", challenge.Type);
        Assert.Equal(50, challenge.TargetValue);
        Assert.Equal(startDate, challenge.StartDate);
        Assert.Equal(endDate, challenge.EndDate);
        Assert.NotEqual(default, challenge.CreatedAt);
        Assert.Empty(challenge.Participants);
    }

    [Fact]
    public void Constructor_ShouldTrimNameAndDescription()
    {
        var challenge = new Challenge(
            Guid.NewGuid(),
            "  Run Challenge  ",
            "  Complete 20 KM.  ",
            "Distance",
            20,
            DateTime.UtcNow.Date,
            DateTime.UtcNow.Date.AddDays(6));

        Assert.Equal(
            "Run Challenge",
            challenge.Name);

        Assert.Equal(
            "Complete 20 KM.",
            challenge.Description);
    }

    [Fact]
    public void Constructor_WithEmptyDescription_ShouldSetNull()
    {
        var challenge = new Challenge(
            Guid.NewGuid(),
            "Run Challenge",
            "   ",
            "Distance",
            20,
            DateTime.UtcNow.Date,
            DateTime.UtcNow.Date.AddDays(6));

        Assert.Null(challenge.Description);
    }

    [Fact]
    public void Constructor_WithInvalidName_ShouldThrow()
    {
        var exception =
            Assert.Throws<ArgumentException>(
                () =>
                    new Challenge(
                        Guid.NewGuid(),
                        "",
                        null,
                        "Distance",
                        20,
                        DateTime.UtcNow.Date,
                        DateTime.UtcNow.Date.AddDays(6)));

        Assert.Equal(
            "Challenge name is required. (Parameter 'name')",
            exception.Message);
    }

    [Fact]
    public void Constructor_WithInvalidType_ShouldThrow()
    {
        var exception =
            Assert.Throws<ArgumentException>(
                () =>
                    new Challenge(
                        Guid.NewGuid(),
                        "Run Challenge",
                        null,
                        "Invalid",
                        20,
                        DateTime.UtcNow.Date,
                        DateTime.UtcNow.Date.AddDays(6)));

        Assert.Contains(
            "Unsupported challenge type",
            exception.Message);
    }

    [Fact]
    public void Constructor_WithZeroTarget_ShouldThrow()
    {
        var exception =
            Assert.Throws<ArgumentException>(
                () =>
                    new Challenge(
                        Guid.NewGuid(),
                        "Run Challenge",
                        null,
                        "Distance",
                        0,
                        DateTime.UtcNow.Date,
                        DateTime.UtcNow.Date.AddDays(6)));

        Assert.Contains(
            "Challenge target must be greater than zero",
            exception.Message);
    }

    [Fact]
    public void Constructor_WithNegativeTarget_ShouldThrow()
    {
        var exception =
            Assert.Throws<ArgumentException>(
                () =>
                    new Challenge(
                        Guid.NewGuid(),
                        "Run Challenge",
                        null,
                        "Distance",
                        -10,
                        DateTime.UtcNow.Date,
                        DateTime.UtcNow.Date.AddDays(6)));

        Assert.Contains(
            "Challenge target must be greater than zero",
            exception.Message);
    }

    [Fact]
    public void Constructor_WithInvalidDateRange_ShouldThrow()
    {
        var startDate = DateTime.UtcNow.Date;
        var endDate = startDate.AddDays(-1);

        var exception =
            Assert.Throws<ArgumentException>(
                () =>
                    new Challenge(
                        Guid.NewGuid(),
                        "Run Challenge",
                        null,
                        "Distance",
                        20,
                        startDate,
                        endDate));

        Assert.Contains(
            "Challenge end date must be greater than or equal to the start date",
            exception.Message);
    }

    [Fact]
    public void Update_ShouldUpdateChallenge()
    {
        var startDate = DateTime.UtcNow.Date;
        var endDate = startDate.AddDays(6);

        var challenge = new Challenge(
            Guid.NewGuid(),
            "Original Challenge",
            "Original description",
            "Distance",
            50,
            startDate,
            endDate);

        var newStartDate = startDate.AddDays(7);
        var newEndDate = newStartDate.AddDays(6);

        challenge.Update(
            "Updated Challenge",
            "Updated description",
            "Duration",
            3600,
            newStartDate,
            newEndDate);

        Assert.Equal(
            "Updated Challenge",
            challenge.Name);

        Assert.Equal(
            "Updated description",
            challenge.Description);

        Assert.Equal(
            "Duration",
            challenge.Type);

        Assert.Equal(
            3600,
            challenge.TargetValue);

        Assert.Equal(
            newStartDate,
            challenge.StartDate);

        Assert.Equal(
            newEndDate,
            challenge.EndDate);
    }

    [Fact]
    public void Update_WithEmptyDescription_ShouldSetNull()
    {
        var startDate = DateTime.UtcNow.Date;
        var endDate = startDate.AddDays(6);

        var challenge = new Challenge(
            Guid.NewGuid(),
            "Original Challenge",
            "Original description",
            "Distance",
            50,
            startDate,
            endDate);

        challenge.Update(
            "Updated Challenge",
            " ",
            "Activities",
            10,
            startDate,
            endDate);

        Assert.Null(challenge.Description);
    }

    [Fact]
    public void Update_WithInvalidName_ShouldThrow()
    {
        var startDate = DateTime.UtcNow.Date;
        var endDate = startDate.AddDays(6);

        var challenge = new Challenge(
            Guid.NewGuid(),
            "Original Challenge",
            null,
            "Distance",
            50,
            startDate,
            endDate);

        Assert.Throws<ArgumentException>(
            () =>
                challenge.Update(
                    "",
                    null,
                    "Distance",
                    50,
                    startDate,
                    endDate));
    }

    [Fact]
    public void Update_WithInvalidType_ShouldThrow()
    {
        var startDate = DateTime.UtcNow.Date;
        var endDate = startDate.AddDays(6);

        var challenge = new Challenge(
            Guid.NewGuid(),
            "Original Challenge",
            null,
            "Distance",
            50,
            startDate,
            endDate);

        Assert.Throws<ArgumentException>(
            () =>
                challenge.Update(
                    "Updated",
                    null,
                    "Invalid",
                    50,
                    startDate,
                    endDate));
    }

    [Fact]
    public void Update_WithInvalidTarget_ShouldThrow()
    {
        var startDate = DateTime.UtcNow.Date;
        var endDate = startDate.AddDays(6);

        var challenge = new Challenge(
            Guid.NewGuid(),
            "Original Challenge",
            null,
            "Distance",
            50,
            startDate,
            endDate);

        Assert.Throws<ArgumentException>(
            () =>
                challenge.Update(
                    "Updated",
                    null,
                    "Distance",
                    0,
                    startDate,
                    endDate));
    }

    [Fact]
    public void Update_WithInvalidDateRange_ShouldThrow()
    {
        var startDate = DateTime.UtcNow.Date;
        var endDate = startDate.AddDays(6);

        var challenge = new Challenge(
            Guid.NewGuid(),
            "Original Challenge",
            null,
            "Distance",
            50,
            startDate,
            endDate);

        Assert.Throws<ArgumentException>(
            () =>
                challenge.Update(
                    "Updated",
                    null,
                    "Distance",
                    50,
                    endDate,
                    startDate));
    }
}