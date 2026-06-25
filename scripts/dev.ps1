$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$backendProject = Join-Path $repoRoot 'src/AgentGate.App/AgentGate.App.csproj'
$frontendRoot = Join-Path $repoRoot 'src/AgentGate.Web'

$backend = Start-Process `
    -FilePath 'dotnet' `
    -ArgumentList @('run', '--project', $backendProject, '--launch-profile', 'http') `
    -WorkingDirectory $repoRoot `
    -NoNewWindow `
    -PassThru

try {
    Push-Location $frontendRoot
    npm run dev

    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}
finally {
    Pop-Location

    if (-not $backend.HasExited) {
        Stop-Process -Id $backend.Id
    }
}
