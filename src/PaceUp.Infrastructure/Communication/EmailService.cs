
using Microsoft.Extensions.Configuration;
using MimeKit;
using PaceUp.Application.Abstractions.Communication;
using PaceUp.Application.Exceptions;
using System.Net.Http.Json;
namespace PaceUp.Infrastructure.Communication;

public class EmailService : IEmailService
{
    private readonly IConfiguration _configuration;
    private readonly IHttpClientFactory _httpClientFactory;

    public EmailService(
    IConfiguration configuration,
    IHttpClientFactory httpClientFactory)
    {
        _configuration = configuration;
        _httpClientFactory = httpClientFactory;
    }

    public async Task SendPasswordResetEmailAsync(
        string email,
        string resetToken,
        CancellationToken cancellationToken)
    {
        var baseUrl = _configuration["PasswordReset:BaseUrl"];

        if (string.IsNullOrWhiteSpace(baseUrl))
        {
            throw new InvalidOperationException(
                "PasswordReset:BaseUrl is not configured.");
        }

        var resetUrl =
            $"{baseUrl}?token={Uri.EscapeDataString(resetToken)}";

        var message = new MimeMessage();

        var senderEmail = _configuration["Resend:FromEmail"];
        if (string.IsNullOrWhiteSpace(senderEmail))
        {
            throw new InvalidOperationException(
                "Resend:FromEmail is not configured."
            );
        }

        message.From.Add(
            new MailboxAddress("PaceUp", senderEmail)
        );

        message.To.Add(MailboxAddress.Parse(email));

        message.Subject = "Reset your PaceUp password";
        var bodyBuilder = new BodyBuilder();

        bodyBuilder.HtmlBody = $"""
            <!DOCTYPE html>
            <html lang="en">
            <head>
                <meta charset="UTF-8">
                <meta
                    name="viewport"
                    content="width=device-width, initial-scale=1.0"
                >
                <title>Reset your PaceUp password</title>
            </head>

            <body style="
                margin: 0;
                padding: 0;
                background-color: #080A0D;
                font-family: Arial, Helvetica, sans-serif;
                color: #F6F8F9;
            ">

                <table
                    width="100%"
                    cellpadding="0"
                    cellspacing="0"
                    border="0"
                    style="
                        background-color: #080A0D;
                        padding: 32px 16px;
                    "
                >
                    <tr>
                        <td align="center">

                            <table
                                width="100%"
                                cellpadding="0"
                                cellspacing="0"
                                border="0"
                                style="
                                    max-width: 560px;
                                    background-color: #11161B;
                                    border: 1px solid #283038;
                                    border-radius: 18px;
                                    overflow: hidden;
                                "
                            >

                                <!-- HEADER -->

                                <tr>
                                    <td
                                        style="
                                            padding: 30px 32px;
                                            background-color: #080A0D;
                                            border-bottom: 1px solid #283038;
                                        "
                                    >
                                        <div style="
                                            font-size: 30px;
                                            line-height: 1;
                                            font-weight: 800;
                                            font-style: italic;
                                            letter-spacing: -1.5px;
                                        ">
                                            <span style="
                                                color: #F6F8F9;
                                            ">pace</span><span style="
                                                color: #B8FF3D;
                                            ">up</span>
                                        </div>
                                    </td>
                                </tr>

                                <!-- CONTENT -->

                                <tr>
                                    <td style="
                                        padding: 40px 32px;
                                    ">

                                        <div style="
                                            width: 52px;
                                            height: 52px;
                                            line-height: 52px;
                                            text-align: center;
                                            border-radius: 50%;
                                            background-color: #122000;
                                            border: 1px solid #B8FF3D;
                                            color: #B8FF3D;
                                            font-size: 24px;
                                            margin-bottom: 24px;
                                        ">
                                            &#128274;
                                        </div>

                                        <h1 style="
                                            margin: 0 0 14px 0;
                                            color: #F6F8F9;
                                            font-size: 30px;
                                            line-height: 1.1;
                                            font-weight: 800;
                                            letter-spacing: -0.8px;
                                        ">
                                            Reset your password
                                        </h1>

                                        <p style="
                                            margin: 0 0 24px 0;
                                            color: #96A0AB;
                                            font-size: 15px;
                                            line-height: 1.7;
                                        ">
                                            We received a request to reset
                                            the password for your PaceUp
                                            account.
                                        </p>

                                        <p style="
                                            margin: 0 0 28px 0;
                                            color: #F6F8F9;
                                            font-size: 15px;
                                            line-height: 1.7;
                                        ">
                                            Click the button below to create
                                            a new password and get back to
                                            your PaceUp journey.
                                        </p>

                                        <!-- BUTTON -->

                                        <table
                                            cellpadding="0"
                                            cellspacing="0"
                                            border="0"
                                            width="100%"
                                        >
                                            <tr>
                                                <td align="center">
                                                    <a
                                                        href="{resetUrl}"
                                                        style="
                                                            display: block;
                                                            width: 100%;
                                                            box-sizing: border-box;
                                                            padding: 16px 20px;
                                                            background-color: #B8FF3D;
                                                            color: #122000;
                                                            border-radius: 12px;
                                                            text-decoration: none;
                                                            font-size: 14px;
                                                            line-height: 1;
                                                            font-weight: 800;
                                                            letter-spacing: 0.6px;
                                                        "
                                                    >
                                                        RESET PASSWORD
                                                    </a>
                                                </td>
                                            </tr>
                                        </table>

                                        <!-- EXPIRY -->

                                        <div style="
                                            margin-top: 28px;
                                            padding: 16px;
                                            background-color: #1A2026;
                                            border: 1px solid #283038;
                                            border-radius: 12px;
                                        ">
                                            <p style="
                                                margin: 0;
                                                color: #96A0AB;
                                                font-size: 13px;
                                                line-height: 1.6;
                                            ">
                                                <strong style="
                                                    color: #F6F8F9;
                                                ">
                                                    Security notice
                                                </strong>
                                                <br>
                                                This password reset link
                                                expires in 1 hour.
                                            </p>
                                        </div>

                                        <p style="
                                            margin: 28px 0 0 0;
                                            color: #96A0AB;
                                            font-size: 13px;
                                            line-height: 1.7;
                                        ">
                                            If you didn't request a password
                                            reset, you can safely ignore this
                                            email. Your password will remain
                                            unchanged.
                                        </p>

                                    </td>
                                </tr>

                                <!-- FOOTER -->

                                <tr>
                                    <td style="
                                        padding: 24px 32px;
                                        background-color: #0D1115;
                                        border-top: 1px solid #283038;
                                    ">

                                        <p style="
                                            margin: 0 0 8px 0;
                                            font-size: 12px;
                                            line-height: 1.5;
                                        ">
                                            <span style="
                                                color: #F6F8F9;
                                                font-weight: 800;
                                                font-style: italic;
                                            ">pace</span><span style="
                                                color: #B8FF3D;
                                                font-weight: 800;
                                                font-style: italic;
                                            ">up</span>
                                        </p>

                                        <p style="
                                            margin: 0;
                                            color: #58636E;
                                            font-size: 11px;
                                            line-height: 1.6;
                                        ">
                                            Keep moving. Keep improving.
                                        </p>

                                    </td>
                                </tr>

                            </table>

                        </td>
                    </tr>
                </table>

            </body>
            </html>
            """;

        bodyBuilder.TextBody =
            $"""
            paceup

            Reset your password

            We received a request to reset the password
            for your PaceUp account.

            Reset your password:
            {resetUrl}

            This password reset link expires in 1 hour.

            If you didn't request a password reset,
            you can safely ignore this email.

            — PaceUp
            """;

        message.Body = bodyBuilder.ToMessageBody();

        await SendEmailAsync(message, cancellationToken);
    }

    public async Task SendEmailVerificationAsync(
    string email,
    string verificationToken,
    CancellationToken cancellationToken)
    {
        var baseUrl =
            _configuration["EmailVerification:BaseUrl"]
            ?? "paceup://verify-email";

        var verificationUrl =
            $"{baseUrl}?token={Uri.EscapeDataString(verificationToken)}";

        var message = new MimeMessage();

        var senderEmail = _configuration["Resend:FromEmail"];
        if (string.IsNullOrWhiteSpace(senderEmail))
        {
            throw new InvalidOperationException(
                "Resend:FromEmail is not configured."
            );
        }

        message.From.Add(
            new MailboxAddress("PaceUp", senderEmail)
        );

        message.To.Add(MailboxAddress.Parse(email));

        message.Subject = "Verify your PaceUp email";
        var bodyBuilder = new BodyBuilder();

        bodyBuilder.HtmlBody = $"""
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta
                name="viewport"
                content="width=device-width, initial-scale=1.0"
            >
            <title>Verify your PaceUp email</title>
        </head>

        <body style="
            margin: 0;
            padding: 0;
            background-color: #080A0D;
            font-family: Arial, Helvetica, sans-serif;
            color: #F6F8F9;
        ">

            <table
                width="100%"
                cellpadding="0"
                cellspacing="0"
                border="0"
                style="
                    background-color: #080A0D;
                    padding: 32px 16px;
                "
            >
                <tr>
                    <td align="center">

                        <table
                            width="100%"
                            cellpadding="0"
                            cellspacing="0"
                            border="0"
                            style="
                                max-width: 560px;
                                background-color: #11161B;
                                border: 1px solid #283038;
                                border-radius: 18px;
                                overflow: hidden;
                            "
                        >

                            <tr>
                                <td style="
                                    padding: 30px 32px;
                                    background-color: #080A0D;
                                    border-bottom: 1px solid #283038;
                                ">
                                    <div style="
                                        font-size: 30px;
                                        line-height: 1;
                                        font-weight: 800;
                                        font-style: italic;
                                        letter-spacing: -1.5px;
                                    ">
                                        <span style="color: #F6F8F9;">
                                            pace
                                        </span>
                                        <span style="color: #B8FF3D;">
                                            up
                                        </span>
                                    </div>
                                </td>
                            </tr>

                            <tr>
                                <td style="
                                    padding: 40px 32px;
                                ">

                                    <div style="
                                        width: 52px;
                                        height: 52px;
                                        line-height: 52px;
                                        text-align: center;
                                        border-radius: 50%;
                                        background-color: #122000;
                                        border: 1px solid #B8FF3D;
                                        color: #B8FF3D;
                                        font-size: 24px;
                                        margin-bottom: 24px;
                                    ">
                                        &#10003;
                                    </div>

                                    <h1 style="
                                        margin: 0 0 14px 0;
                                        color: #F6F8F9;
                                        font-size: 30px;
                                        line-height: 1.1;
                                        font-weight: 800;
                                        letter-spacing: -0.8px;
                                    ">
                                        Verify your email
                                    </h1>

                                    <p style="
                                        margin: 0 0 24px 0;
                                        color: #96A0AB;
                                        font-size: 15px;
                                        line-height: 1.7;
                                    ">
                                        Welcome to PaceUp. Please verify
                                        your email address to activate your
                                        account.
                                    </p>

                                    <table
                                        cellpadding="0"
                                        cellspacing="0"
                                        border="0"
                                        width="100%"
                                    >
                                        <tr>
                                            <td align="center">
                                                <a
                                                    href="{verificationUrl}"
                                                    style="
                                                        display: block;
                                                        width: 100%;
                                                        box-sizing: border-box;
                                                        padding: 16px 20px;
                                                        background-color: #B8FF3D;
                                                        color: #122000;
                                                        border-radius: 12px;
                                                        text-decoration: none;
                                                        font-size: 14px;
                                                        line-height: 1;
                                                        font-weight: 800;
                                                        letter-spacing: 0.6px;
                                                    "
                                                >
                                                    VERIFY EMAIL
                                                </a>
                                            </td>
                                        </tr>
                                    </table>

                                    <div style="
                                        margin-top: 28px;
                                        padding: 16px;
                                        background-color: #1A2026;
                                        border: 1px solid #283038;
                                        border-radius: 12px;
                                    ">
                                        <p style="
                                            margin: 0;
                                            color: #96A0AB;
                                            font-size: 13px;
                                            line-height: 1.6;
                                        ">
                                            <strong style="
                                                color: #F6F8F9;
                                            ">
                                                Security notice
                                            </strong>
                                            <br>
                                            This verification link expires
                                            in 24 hours.
                                        </p>
                                    </div>

                                </td>
                            </tr>

                            <tr>
                                <td style="
                                    padding: 24px 32px;
                                    background-color: #0D1115;
                                    border-top: 1px solid #283038;
                                ">
                                    <p style="
                                        margin: 0 0 8px 0;
                                        font-size: 12px;
                                        line-height: 1.5;
                                    ">
                                        <span style="
                                            color: #F6F8F9;
                                            font-weight: 800;
                                            font-style: italic;
                                        ">pace</span><span style="
                                            color: #B8FF3D;
                                            font-weight: 800;
                                            font-style: italic;
                                        ">up</span>
                                    </p>

                                    <p style="
                                        margin: 0;
                                        color: #58636E;
                                        font-size: 11px;
                                        line-height: 1.6;
                                    ">
                                        Keep moving. Keep improving.
                                    </p>
                                </td>
                            </tr>

                        </table>

                    </td>
                </tr>
            </table>

        </body>
        </html>
        """;

        bodyBuilder.TextBody =
            $"""
        paceup

        Verify your email

        Welcome to PaceUp. Please verify your email address
        to activate your account.

        Verify your email:
        {verificationUrl}

        This verification link expires in 24 hours.

        — PaceUp
        """;

        message.Body = bodyBuilder.ToMessageBody();

        await SendEmailAsync(message, cancellationToken);
    }



    private async Task SendEmailAsync(
        MimeMessage message,
        CancellationToken cancellationToken)
    {
        var apiKey = _configuration["RESEND_API_KEY"];
        var senderEmail = _configuration["Resend:FromEmail"];

        if (string.IsNullOrWhiteSpace(apiKey))
        {
            throw new InvalidOperationException(
                "RESEND_API_KEY is not configured.");
        }

        if (string.IsNullOrWhiteSpace(senderEmail))
        {
            throw new InvalidOperationException(
                "Resend:FromEmail is not configured.");
        }

        try
        {
            using var request = new HttpRequestMessage(
                HttpMethod.Post,
                "https://api.resend.com/emails");

            request.Headers.Authorization =
                new System.Net.Http.Headers.AuthenticationHeaderValue(
                    "Bearer",
                    apiKey);

            request.Content = System.Net.Http.Json.JsonContent.Create(
                new
                {
                    from = $"PaceUp <{senderEmail}>",
                    to = message.To.Mailboxes
                        .Select(mailbox => mailbox.Address)
                        .ToArray(),
                    subject = message.Subject,
                    html = message.HtmlBody,
                    text = message.TextBody
                });

            var client = _httpClientFactory.CreateClient();

            using var response = await client.SendAsync(
                request,
                cancellationToken);

            if (!response.IsSuccessStatusCode)
            {
                var responseBody = await response.Content.ReadAsStringAsync(
                    cancellationToken);

                throw new HttpRequestException(
                    $"Resend returned HTTP {(int)response.StatusCode}: " +
                    responseBody);
            }
        }
        catch (OperationCanceledException)
        {
            throw;
        }
        catch (HttpRequestException ex)
        {
            throw new EmailDeliveryException(
                "Email delivery through Resend failed.",
                ex);
        }
    }

}
