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
        else
        {
            _logger.LogError(
                exception,
                "Unhandled exception occurred.");
        }

        var statusCode = exception switch
        {
            ConflictException => StatusCodes.Status409Conflict,

            _ => StatusCodes.Status500InternalServerError
        };

        var problemDetails = new ProblemDetails
        {
            Status = statusCode,
            Title = exception switch
            {
                ConflictException =>
                    "Conflict",

                _ =>
                    "An unexpected error occurred."
            },
            Detail = exception.Message
        };

        httpContext.Response.StatusCode = statusCode;

        await httpContext.Response.WriteAsJsonAsync(
            problemDetails,
            cancellationToken);

        return true;
    }
}