using PaceUp.Domain.Entities;

namespace PaceUp.UnitTests.Goals;

public class GoalTests
{
    [Fact]
    public void Constructor_ShouldCreateGoal()
    {
        var userId = Guid.NewGuid();
        var startDate = DateTime.UtcNow.Date;
        var endDate = startDate.AddDays(6);

        var goal = new Goal(
            userId,
            "Distance",
            50,
            startDate,
            endDate);

        Assert.NotEqual(Guid.Empty, goal.Id);
        Assert.Equal(userId, goal.UserId);
        Assert.Equal("Distance", goal.Type);
        Assert.Equal(50, goal.Target);
        Assert.Equal(startDate, goal.StartDate);
        Assert.Equal(endDate, goal.EndDate);
        Assert.NotEqual(default, goal.CreatedAt);
        Assert.NotEqual(default, goal.UpdatedAt);
    }

    [Fact]
    public void Update_ShouldUpdateGoal()
    {
        var startDate = DateTime.UtcNow.Date;
        var endDate = startDate.AddDays(6);

        var goal = new Goal(
            Guid.NewGuid(),
            "Distance",
            50,
            startDate,
            endDate);

        goal.Update(
            "Calories",
            3000,
            startDate,
            endDate.AddDays(7));

        Assert.Equal("Calories", goal.Type);
        Assert.Equal(3000, goal.Target);
        Assert.Equal(endDate.AddDays(7), goal.EndDate);
    }
}