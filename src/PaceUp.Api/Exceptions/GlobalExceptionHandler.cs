using Microsoft.AspNetCore.Diagnostics;
using Microsoft.AspNetCore.Mvc;
using PaceUp.Application.Exceptions;

namespace PaceUp.Api.Exceptions;

public class GlobalExceptionHandler : IExceptionHandler
{
    private readonly ILogger<GlobalExceptionHandler> _logger;

    public GlobalExceptionHandler(
        ILogger<GlobalExceptionHandler> logger)
    {
        _logger = logger;
    }

    public async ValueTask<bool> TryHandleAsync(
        HttpContext httpContext,
        Exception exception,
        CancellationToken cancellationToken)
    {
        if (exception is ConflictException)
        {
            _logger.LogWarning(
                exception,
                "Request conflict: {Message}",
                exception.Message);
        }
        else if (exception is UnauthorizedAccessException)
        {
            _logger.LogWarning(
                exception,
                "Unauthorized request: {Message}",
                exception.Message);
        }
        else if (exception is ArgumentException)
        {
            _logger.LogWarning(
                exception,
                "Invalid request: {Message}",
                exception.Message);
        }
        else
        {
            _logger.LogError(
                exception,
                "Unhandled exception occurred.");
        }

        var statusCode = exception switch
        {
            ConflictException =>
                StatusCodes.Status409Conflict,

            UnauthorizedAccessException =>
                StatusCodes.Status401Unauthorized,

            ArgumentException =>
                StatusCodes.Status400BadRequest,

            _ =>
                StatusCodes.Status500InternalServerError
        };

        var title = exception switch
        {
            ConflictException =>
                "Conflict",

            UnauthorizedAccessException =>
                "Unauthorized",

            ArgumentException =>
                "Invalid request",

            _ =>
                "An unexpected error occurred."
        };

        var problemDetails = new ProblemDetails
        {
            Status = statusCode,
            Title = title,
            Detail = exception.Message
        };

        httpContext.Response.StatusCode = statusCode;

        await httpContext.Response.WriteAsJsonAsync(
            problemDetails,
            cancellationToken);

        return true;
    }
}