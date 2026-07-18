[CmdletBinding()]
param(
    [string]$SourceDirectory,
    [string]$OutputPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($SourceDirectory)) {
    $SourceDirectory = Join-Path $PSScriptRoot "..\package\PleasureLib"
}
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $PSScriptRoot "..\package\PleasureLib.zip"
}

$sourcePath = (Resolve-Path -LiteralPath $SourceDirectory).Path.TrimEnd(
    [System.IO.Path]::DirectorySeparatorChar,
    [System.IO.Path]::AltDirectorySeparatorChar
)
$outputFullPath = [System.IO.Path]::GetFullPath($OutputPath)
$outputDirectory = Split-Path -Parent $outputFullPath

if (-not (Test-Path -LiteralPath $sourcePath -PathType Container)) {
    throw "Package source directory does not exist: $sourcePath"
}
if (-not (Test-Path -LiteralPath $outputDirectory -PathType Container)) {
    throw "Package output directory does not exist: $outputDirectory"
}
if ((Split-Path -Leaf $sourcePath) -cne "PleasureLib") {
    throw "Package source directory must be named PleasureLib: $sourcePath"
}
if (Test-Path -LiteralPath $outputFullPath -PathType Container) {
    throw "Package output path is a directory: $outputFullPath"
}
$sourcePrefix = $sourcePath + [System.IO.Path]::DirectorySeparatorChar
if ($outputFullPath.StartsWith(
    $sourcePrefix,
    [System.StringComparison]::OrdinalIgnoreCase
)) {
    throw "Package output path must be outside the source directory"
}

$requiredFiles = @(
    "API.md"
    "enabled.txt"
    "readme.txt"
    "Scripts\main.lua"
    "Scripts\pleasure_lib.lua"
    "Scripts\pleasure_lib_settings.lua"
)
foreach ($relativePath in $requiredFiles) {
    $requiredPath = Join-Path $sourcePath $relativePath
    if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
        throw "Required package file is missing: $relativePath"
    }
}

$temporaryPath = Join-Path $outputDirectory (
    "{0}.{1}.next.zip" -f
        [System.IO.Path]::GetFileNameWithoutExtension($outputFullPath),
        [guid]::NewGuid().ToString("N")
)

try {
    Compress-Archive `
        -LiteralPath $sourcePath `
        -DestinationPath $temporaryPath `
        -CompressionLevel Optimal

    Add-Type -AssemblyName System.IO.Compression.FileSystem

    $sourceFiles = @(
        Get-ChildItem -LiteralPath $sourcePath -File -Recurse |
            Sort-Object FullName
    )
    $rootName = "PleasureLib"
    $expectedEntries = @{}
    foreach ($sourceFile in $sourceFiles) {
        $relativePath = $sourceFile.FullName.Substring($sourcePath.Length)
        $relativePath = $relativePath.TrimStart(
            [System.IO.Path]::DirectorySeparatorChar,
            [System.IO.Path]::AltDirectorySeparatorChar
        )
        $entryName = (
            $rootName + "/" + $relativePath.Replace("\", "/")
        )
        $expectedEntries[$entryName] = $sourceFile.FullName
    }

    $archive = [System.IO.Compression.ZipFile]::OpenRead($temporaryPath)
    try {
        $fileEntries = @(
            $archive.Entries |
                Where-Object { $_.Name -ne "" }
        )
        if ($fileEntries.Count -ne $expectedEntries.Count) {
            throw (
                "Package entry count mismatch: expected {0}, found {1}" -f
                    $expectedEntries.Count,
                    $fileEntries.Count
            )
        }

        $seenEntries = @{}
        foreach ($entry in $fileEntries) {
            $entryName = $entry.FullName.Replace("\", "/")
            if ($seenEntries.ContainsKey($entryName)) {
                throw "Duplicate package entry: $entryName"
            }
            if (-not $expectedEntries.ContainsKey($entryName)) {
                throw "Unexpected package entry: $entryName"
            }
            $seenEntries[$entryName] = $true

            $entryStream = $entry.Open()
            $sha256 = [System.Security.Cryptography.SHA256]::Create()
            try {
                $entryHashBytes = $sha256.ComputeHash($entryStream)
                $entryHash = (
                    [System.BitConverter]::ToString($entryHashBytes)
                ).Replace("-", "")
            }
            finally {
                $sha256.Dispose()
                $entryStream.Dispose()
            }

            $sourceHash = (
                Get-FileHash `
                    -LiteralPath $expectedEntries[$entryName] `
                    -Algorithm SHA256
            ).Hash
            if ($entryHash -ne $sourceHash) {
                throw "Package content mismatch: $entryName"
            }
        }

        foreach ($entryName in $expectedEntries.Keys) {
            if (-not $seenEntries.ContainsKey($entryName)) {
                throw "Missing package entry: $entryName"
            }
        }
    }
    finally {
        $archive.Dispose()
    }

    Move-Item `
        -LiteralPath $temporaryPath `
        -Destination $outputFullPath `
        -Force

    $outputHash = (
        Get-FileHash -LiteralPath $outputFullPath -Algorithm SHA256
    ).Hash
    Write-Output (
        "Built {0} with {1} files (SHA256 {2})" -f
            $outputFullPath,
            $expectedEntries.Count,
            $outputHash
    )
}
finally {
    if (Test-Path -LiteralPath $temporaryPath) {
        Remove-Item -LiteralPath $temporaryPath -Force
    }
}
