function Redact-Secrets {
    param(
        [Parameter(Mandatory=$false)]
        [string]$Text
    )

    if ([string]::IsNullOrEmpty($Text)) {
        return ""
    }

    $sanitized = $Text

    # 1. Private keys
    $sanitized = [regex]::Replace($sanitized, '-----BEGIN[ A-Z0-9_-]+KEY-----[\s\S]*?-----END[ A-Z0-9_-]+KEY-----', '[REDACTED_PRIVATE_KEY]')

    # 2. GitHub Tokens (ghp_, gho_, ghu_, ghb_, github_pat_)
    $sanitized = [regex]::Replace($sanitized, 'gh[pousr]_[A-Za-z0-9_]{36,255}', '[REDACTED_GITHUB_TOKEN]')
    $sanitized = [regex]::Replace($sanitized, 'github_pat_[A-Za-z0-9_]{22,255}', '[REDACTED_GITHUB_PAT]')

    # 3. OpenAI / Gemini / Google API Keys
    $sanitized = [regex]::Replace($sanitized, 'sk-[A-Za-z0-9]{32,100}', '[REDACTED_OPENAI_KEY]')
    $sanitized = [regex]::Replace($sanitized, 'AIzaSy[A-Za-z0-9_-]{33}', '[REDACTED_GOOGLE_API_KEY]')

    # 4. Bearer / Authorization headers
    $sanitized = [regex]::Replace($sanitized, '(?i)bearer\s+[A-Za-z0-9._~+/-]{15,}', 'Bearer [REDACTED_TOKEN]')
    $sanitized = [regex]::Replace($sanitized, '(?i)(authorization:\s*bearer\s*)[^\r\n]+', '$1[REDACTED_AUTH]')

    # 5. Passwords in URLs (http://user:password@host)
    $sanitized = [regex]::Replace($sanitized, '://([^:\s/]+):([^@\s/]+)@', '://$1:[REDACTED_PASSWORD]@')

    # 6. Password/secret parameters (password=..., pwd=..., secret=..., token=..., apiKey=...)
    $sanitized = [regex]::Replace($sanitized, '(?i)(password|passwd|pwd|secret|apiKey|api_key|token|access_token)\s*[:=]\s*["'']?([^"''\s,;&]+)["'']?', '$1=[REDACTED_SECRET]')

    return $sanitized
}

# Se eseguito direttamente come script da CLI
if ($MyInvocation.InvocationName -ne '.') {
    if ($args.Count -gt 0) {
        Redact-Secrets -Text ($args -join " ")
    }
}
