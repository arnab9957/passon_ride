<#
.SYNOPSIS
    Starts the PassionRide Flutter Web app on port 3000.
#>
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Args
)

$projectDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectDir

Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host " Starting PassionRide Flutter Web via cpaglu..." -ForegroundColor Green
Write-Host " URL: http://localhost:3000" -ForegroundColor Yellow
Write-Host "=======================================================" -ForegroundColor Cyan

flutter run -d chrome --web-port=3000 @Args
