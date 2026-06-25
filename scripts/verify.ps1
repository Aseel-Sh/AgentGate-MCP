$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$frontendRoot = Join-Path $repoRoot 'src/AgentGate.Web'
$publishRoot = Join-Path $repoRoot 'artifacts/publish'

Push-Location $repoRoot

try {
    dotnet restore AgentGate.slnx
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    dotnet format AgentGate.slnx --verify-no-changes --no-restore
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    dotnet build AgentGate.slnx --configuration Release --no-restore
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    dotnet test AgentGate.slnx --configuration Release --no-build
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    Push-Location $frontendRoot
    try {
        npm ci
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

        npm run lint
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

        npm run typecheck
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

        npm run test:run
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

        npm run build
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    }
    finally {
        Pop-Location
    }

    dotnet publish src/AgentGate.App/AgentGate.App.csproj `
        --configuration Release `
        --output $publishRoot
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    $indexFile = Join-Path $publishRoot 'wwwroot/index.html'
    if (-not (Test-Path $indexFile)) {
        throw "Published React entry point was not found at $indexFile"
    }
}
finally {
    Pop-Location
}
