using Microsoft.Extensions.Configuration;
using PaceUp.Application.Abstractions.Communication;
using Resend;

namespace PaceUp.Infrastructure.Communication;

public class EmailService : IEmailService
{
    private readonly IResend _resend;
    private readonly IConfiguration _configuration;

    public EmailService(
        IResend resend,
        IConfiguration configuration)
    {
        _resend = resend;
        _configuration = configuration;
    }

    public async Task SendPasswordResetEmailAsync(
        string email,
        string resetToken,
        CancellationToken cancellationToken)
    {
        var baseUrl =
            _configuration["PasswordReset:BaseUrl"]
            ?? "http://192.168.0.109:5095/api/auth/reset-password-link";

        var resetUrl =
            $"{baseUrl}?token={Uri.EscapeDataString(resetToken)}";

        var message = new EmailMessage();

        message.From =
            _configuration["Resend:FromEmail"]
            ?? "PaceUp <onboarding@resend.dev>";

        message.To.Add(email);

        message.Subject = "Reset your PaceUp password";

        message.HtmlBody = $"""
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

        message.TextBody =
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

        await _resend.EmailSendAsync(
            message,
            cancellationToken);
    }
}