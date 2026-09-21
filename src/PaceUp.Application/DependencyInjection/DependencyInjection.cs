using Microsoft.Extensions.DependencyInjection;
using PaceUp.Application.Abstractions.Users;
using PaceUp.Application.Features.Users;
using FluentValidation;
using PaceUp.Application.Abstractions.Authentication;
using PaceUp.Application.Features.Authentication;
using PaceUp.Application.Abstractions.Activities;
using PaceUp.Application.Features.Activities;
using PaceUp.Application.Abstractions.Goals;
using PaceUp.Application.Features.Goals;
using PaceUp.Application.Abstractions.Dashboard;
using PaceUp.Application.Features.Dashboard;
using PaceUp.Application.Abstractions.Feed;
using PaceUp.Application.Features.Feed;
using PaceUp.Application.Abstractions.Notifications;
using PaceUp.Application.Features.Notifications;
using PaceUp.Application.Abstractions.Challenges;
using PaceUp.Application.Features.Challenges;
using PaceUp.Application.Abstractions.Kudos;
using PaceUp.Application.Features.Kudos;
using PaceUp.Application.Abstractions.Comments;
using PaceUp.Application.Features.Comments;
using PaceUp.Application.Abstractions.Routes;
using PaceUp.Application.Features.Routes;
using PaceUp.Application.Abstractions.Achievements;
using PaceUp.Application.Features.Achievements;
using PaceUp.Application.Abstractions.Streaks;
using PaceUp.Application.Features.Streaks;
using PaceUp.Application.Abstractions.Leaderboards;
using PaceUp.Application.Features.Leaderboards;
namespace PaceUp.Application.DependencyInjection;

public static class DependencyInjection
{
    public static IServiceCollection AddApplication(
        this IServiceCollection services)
    {
        services.AddScoped<IUserService, UserService>();

        services.AddScoped<IAuthenticationService,AuthenticationService>();

        services.AddValidatorsFromAssembly(
            typeof(DependencyInjection).Assembly);

        services.AddScoped<IActivityService, ActivityService>();

        services.AddScoped<IGoalService, GoalService>();

        services.AddScoped<IFeedService, FeedService>();

        services.AddScoped<IDashboardService, DashboardService>();

        services.AddScoped<INotificationService, NotificationService>();

        services.AddScoped<IChallengeService, ChallengeService>();

        services.AddScoped<IKudosService, KudosService>();

        services.AddScoped<ICommentService, CommentService>();

        services.AddScoped<IRouteService, RouteService>();

        services.AddScoped<IAchievementService, AchievementService>();

        services.AddScoped<IStreakService, StreakService>();

        services.AddScoped<ILeaderboardService, LeaderboardService>();

        return services;
    }
}