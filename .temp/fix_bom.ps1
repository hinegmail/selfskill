$files = @(
    "d:\Projects\selfskill\init.ps1",
    "d:\Projects\selfskill\init.sh"
)

foreach ($file in $files) {
    $content = [System.IO.File]::ReadAllText($file, [System.Text.Encoding]::UTF8)
    $utf8Bom = New-Object System.Text.UTF8Encoding($true)
    [System.IO.File]::WriteAllText($file, $content, $utf8Bom)
    Write-Host "Fixed BOM: $file"
}
