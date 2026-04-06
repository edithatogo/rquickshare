# rename_build.ps1
# Cross-platform build rename script for Windows CI
# Usage: .\rename_build.ps1 -BaseDirectory "path\to\bundle" -TauriVersion "main" [-DebugMode]

param(
    [Parameter(Mandatory = $true)]
    [string]$BaseDirectory,

    [Parameter(Mandatory = $true)]
    [string]$TauriVersion,

    [switch]$DebugMode
)

# Find all relevant files in the base directory
$extensions = @("*.msi", "*.exe", "*.appx")
$files = @()
foreach ($ext in $extensions) {
    $files += Get-ChildItem -Path $BaseDirectory -Recurse -Filter $ext -File
}

if ($files.Count -eq 0) {
    Write-Host "No Windows build artifacts found in $BaseDirectory"
    exit 0
}

Write-Host "Found $($files.Count) Windows build artifact(s)"

# Loop through each file
foreach ($file in $files) {
    $dir = $file.DirectoryName
    $filename = $file.Name
    $extension = $file.Extension.TrimStart('.')

    # Extract version and variant from filename
    # Patterns: r-quick-share_0.11.5_x64.msi, RQuickShare-0.11.5-1-x64.exe, etc.
    $versionPattern = '([Rr](-[_]?)[Qq]uick([_-][Ss]hare))[_-]?([0-9]+\.[0-9]+\.[0-9]+)[_-]?(.*)\.' + [regex]::Escape($extension)

    if ($filename -match $versionPattern) {
        $version = "v$($Matches[4])"
        $anything = $Matches[5].Trim('_-')
    }
    else {
        # Fallback: use filename without extension as-is
        $version = ""
        $anything = $filename
        Write-Host "Filename does not match expected pattern: $filename, using fallback"
    }

    # Construct new filename
    $debugSuffix = if ($DebugMode) { "-debug" } else { "" }

    if (-not [string]::IsNullOrEmpty($version)) {
        $newFilename = "r-quick-share-${TauriVersion}${debugSuffix}_${version}_${anything}.${extension}"
    }
    else {
        $newFilename = "r-quick-share-${TauriVersion}${debugSuffix}_${anything}.${extension}"
    }

    $newPath = Join-Path $dir $newFilename

    # Rename the file
    Rename-Item -Path $file.FullName -NewName $newFilename
    Write-Host "Renamed $filename to $newPath"
}

Write-Host "Windows build renaming completed."
