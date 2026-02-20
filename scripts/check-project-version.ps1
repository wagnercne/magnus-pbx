Set-Location (Split-Path -Parent $PSScriptRoot)

$versionFile = Join-Path $PWD 'VERSION'
if (-not (Test-Path $versionFile)) {
  Write-Error 'VERSION file not found.'
  exit 1
}

$expected = (Get-Content $versionFile -Raw).Trim()
if ([string]::IsNullOrWhiteSpace($expected)) {
  Write-Error 'VERSION file is empty.'
  exit 1
}

$targets = @(
  'asterisk_etc/extensions.conf',
  'docker-compose.optimized.yml',
  'sql/01_init_schema.sql',
  'sql/02_sample_data.sql'
)

$errors = 0
foreach ($file in $targets) {
  if (-not (Test-Path $file)) {
    Write-Warning "Skipping missing file: $file"
    continue
  }

  $content = Get-Content $file -Raw

  switch ($file) {
    'asterisk_etc/extensions.conf' {
      if ($content -notmatch "MAGNUS_VERSION=$([regex]::Escape($expected))") {
        Write-Error "Version mismatch in $file"
        $errors++
      }
    }
    'docker-compose.optimized.yml' {
      if ($content -notmatch "# Versao: $([regex]::Escape($expected))|# Versão: $([regex]::Escape($expected))") {
        Write-Error "Version mismatch in $file"
        $errors++
      }
    }
    'sql/01_init_schema.sql' {
      if ($content -notmatch "-- Versao: $([regex]::Escape($expected))|-- Versão: $([regex]::Escape($expected))") {
        Write-Error "Version mismatch in $file"
        $errors++
      }
    }
    'sql/02_sample_data.sql' {
      if ($content -notmatch "-- Versao: $([regex]::Escape($expected))|-- Versão: $([regex]::Escape($expected))") {
        Write-Error "Version mismatch in $file"
        $errors++
      }
    }
  }
}

if ($errors -gt 0) {
  Write-Host "Version check failed with $errors error(s)." -ForegroundColor Red
  exit 1
}

Write-Host "Version check OK ($expected)." -ForegroundColor Green
exit 0
