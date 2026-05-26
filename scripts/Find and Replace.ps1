# This script updates all .xhtml files in the current directory by running the following replacements:
Get-ChildItem -Path "." -Filter "*.xhtml" | ForEach-Object {
    # Read the content of the file
    $content = Get-Content $_.FullName -Raw
    # Perform the modifications on the content
        # 1. Replaces any <p> tags that contain only a sequence of dashes
        # 2. Replaces any <p> tags that contain only three dots with <hr/>
        # 3. Replaces any <h2> tags with <h1> tags
    $newContent = $content `
        -replace '<p>\s*[\-_—–―─]+\s*</p>', '<hr class="hr-system" />' `
        -replace '<p>\.\.\.</p>', '<hr class="hr-scene" />' `
        -replace '<h2>(.*?)</h2>', '<h1>$1</h1>'
    # set the new content to the file
    Set-Content $_.FullName -Value $newContent -NoNewline
    # Output the name of the updated file to the console
    Write-Host "Updated: $($_.Name)" -ForegroundColor Green
}