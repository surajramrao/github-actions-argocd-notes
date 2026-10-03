$repo = "C:\Users\Neha Atkari\Downloads\GA-notes"

Set-Location $repo

Write-Host "===================================="
Write-Host " Git Auto Push Started"
Write-Host " Repository: $repo"
Write-Host " Checking every 5 seconds..."
Write-Host "===================================="

while ($true) {

    # Check if there are changes
    $changes = git status --porcelain

    if ($changes) {

        Write-Host ""
        Write-Host "Changes detected!" -ForegroundColor Yellow

        git add .

        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

        git commit -m "Auto update: $timestamp"

        Write-Host "Pushing to GitHub..." -ForegroundColor Cyan

        git push origin main

        Write-Host "Push completed!" -ForegroundColor Green
        Write-Host ""
    }

    Start-Sleep -Seconds 5
}