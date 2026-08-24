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

        services.AddScoped<IDashboardService, DashboardService>();

        return services;
    }
}