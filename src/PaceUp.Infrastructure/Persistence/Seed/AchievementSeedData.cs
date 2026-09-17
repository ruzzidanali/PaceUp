using Microsoft.EntityFrameworkCore;
using PaceUp.Domain.Entities;

namespace PaceUp.Infrastructure.Persistence.Seed;

public static class AchievementSeedData
{
    public static async Task SeedAsync(PaceUpDbContext context)
    {
        if (await context.Achievements.AnyAsync())
        {
            return;
        }

        var achievements = new[]
        {
            new Achievement(
                code: "FIRST_ACTIVITY",
                name: "First Steps",
                description: "Complete your first activity.",
                icon: "directions_run",
                requirementType: "ACTIVITY_COUNT",
                requirementValue: 1),

            new Achievement(
                code: "ACTIVITIES_5",
                name: "Getting Started",
                description: "Complete 5 activities.",
                icon: "looks_5",
                requirementType: "ACTIVITY_COUNT",
                requirementValue: 5),

            new Achievement(
                code: "ACTIVITIES_10",
                name: "Dedicated",
                description: "Complete 10 activities.",
                icon: "looks_10",
                requirementType: "ACTIVITY_COUNT",
                requirementValue: 10),

            new Achievement(
                code: "TOTAL_DISTANCE_10KM",
                name: "10K Club",
                description: "Reach 10 km of total distance.",
                icon: "route",
                requirementType: "TOTAL_DISTANCE_KM",
                requirementValue: 10),

            new Achievement(
                code: "TOTAL_DISTANCE_50KM",
                name: "50K Club",
                description: "Reach 50 km of total distance.",
                icon: "route",
                requirementType: "TOTAL_DISTANCE_KM",
                requirementValue: 50),

            new Achievement(
                code: "TOTAL_DISTANCE_100KM",
                name: "Century",
                description: "Reach 100 km of total distance.",
                icon: "emoji_events",
                requirementType: "TOTAL_DISTANCE_KM",
                requirementValue: 100),

            new Achievement(
                code: "ACTIVITY_DURATION_60MIN",
                name: "One Hour",
                description: "Complete an activity lasting at least 60 minutes.",
                icon: "timer",
                requirementType: "ACTIVITY_DURATION_MINUTES",
                requirementValue: 60),

            new Achievement(
                code: "ACTIVITIES_7",
                name: "Weekly Warrior",
                description: "Complete 7 activities.",
                icon: "calendar_today",
                requirementType: "ACTIVITY_COUNT",
                requirementValue: 7)
        };

        await context.Achievements.AddRangeAsync(achievements);
        await context.SaveChangesAsync();
    }
}