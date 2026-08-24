using FluentValidation;
using PaceUp.Application.DTOs.Activities;
using PaceUp.Domain.Constants;

namespace PaceUp.Application.Features.Activities;

public class ActivityTrendRequestValidator
    : AbstractValidator<ActivityTrendRequest>
{
    public ActivityTrendRequestValidator()
    {
        RuleFor(x => x.GroupBy)
            .Must(IsValidGroupBy)
            .WithMessage(
                "GroupBy must be day, week, or month.");

        RuleFor(x => x.Type)
            .Must(ActivityTypes.IsValid)
            .When(x => !string.IsNullOrWhiteSpace(x.Type))
            .WithMessage(
                "Activity type is not supported.");

        RuleFor(x => x.To)
            .GreaterThanOrEqualTo(x => x.From)
            .When(x =>
                x.From.HasValue &&
                x.To.HasValue)
            .WithMessage(
                "To must be greater than or equal to From.");
    }

    private static bool IsValidGroupBy(
        string? groupBy)
    {
        return groupBy?.ToLowerInvariant() is
            "day" or
            "week" or
            "month";
    }
}