# Refresh PATH in PowerShell session
# Run this script at the start of each PowerShell session, or add to your PowerShell profile

$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

Write-Host "PATH refreshed. Ruby and Bundler should now be available." -ForegroundColor Green
Write-Host "Ruby version: $(ruby --version)" -ForegroundColor Cyan
Write-Host "Bundler version: $(bundle --version)" -ForegroundColor Cyan

