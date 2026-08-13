using Microsoft.Extensions.DependencyInjection;
using PaceUp.Application.Abstractions.Users;
using PaceUp.Application.Features.Users;
using FluentValidation;

namespace PaceUp.Application.DependencyInjection;

public static class DependencyInjection
{
    public static IServiceCollection AddApplication(
        this IServiceCollection services)
    {
        services.AddScoped<IUserService, UserService>();

        services.AddValidatorsFromAssembly(
            typeof(DependencyInjection).Assembly);

        return services;
    }
}