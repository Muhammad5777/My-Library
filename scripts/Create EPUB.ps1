param(
    [string]$SourceFolder,
    [string]$OutputEpub
)

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

if (-not $SourceFolder) {
    Write-Host "Source folder path: " -NoNewline
    $SourceFolder = $Host.UI.ReadLine().Trim('"').Trim("'")
}

if (-not $OutputEpub) {
    Write-Host "Output .epub path: " -NoNewline
    $OutputEpub = $Host.UI.ReadLine().Trim('"').Trim("'")
}

# Validate inputs before doing anything destructive
if (-not (Test-Path $SourceFolder -PathType Container)) {
    Write-Error "Source folder not found: $SourceFolder"
    exit 1
}

if (-not $OutputEpub.EndsWith(".epub")) {
    Write-Error "Output path must end with .epub"
    exit 1
}

$sourceFolder = (Resolve-Path $SourceFolder).Path
$outputEpub = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputEpub)

$mimetypePath = Join-Path $sourceFolder "mimetype"
if (-not (Test-Path $mimetypePath)) {
    Write-Error "Missing mimetype file in source folder."
    exit 1
}

if (Test-Path $outputEpub) { Remove-Item $outputEpub }

$stream = [System.IO.File]::Open($outputEpub, [System.IO.FileMode]::Create)
$zip = [System.IO.Compression.ZipArchive]::new($stream, [System.IO.Compression.ZipArchiveMode]::Create)

try {
    # 1. mimetype FIRST, NO compression
    $entry = $zip.CreateEntry("mimetype", [System.IO.Compression.CompressionLevel]::NoCompression)
    $entryStream = $entry.Open()
    $bytes = [System.IO.File]::ReadAllBytes($mimetypePath)
    $entryStream.Write($bytes, 0, $bytes.Length)
    $entryStream.Close()

    # 2. Everything else, with normal compression
    $files = Get-ChildItem -Path $sourceFolder -Recurse -File |
    Where-Object { $_.Name -ne "mimetype" -and $_.FullName -ne $outputEpub }

    foreach ($file in $files) {
        $relativePath = $file.FullName.Substring($sourceFolder.Length + 1).Replace("\", "/")
        $entry = $zip.CreateEntry($relativePath, [System.IO.Compression.CompressionLevel]::Optimal)
        $entryStream = $entry.Open()
        $fileStream = $file.OpenRead()
        $fileStream.CopyTo($entryStream)
        $fileStream.Close()
        $entryStream.Close()
    }
}
finally {
    $zip.Dispose()
    $stream.Dispose()
}

Write-Host "Done: $outputEpub"