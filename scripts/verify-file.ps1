param (
    [string]$Path,
    [string]$ETag
)

$location = Get-Location
Set-Location -Path $PSScriptRoot
try {
    if (!($ETag -match '^([0-9a-f]+)(?:-(\d+)){0,1}$')) {
        throw "Invalid ETag format: $ETag"
    }

    $chunkCount = $matches[2] ? [int]$matches[2] : 1
    $length = (Get-Item -Path $Path).Length

    $chunkSize = $length / $chunkCount / 1024 / 1024
    $chunkSize = [math]::Ceiling($chunkSize)

    Write-Host "123"
    $actualTag = ./etag.ps1 -Path $Path -PartSizeMB $chunkSize
    if ($actualTag -ne $ETag) {
        throw "ETag mismatch: $actualTag != $ETag"
    }
}
finally {
    Set-Location -Path $location
}
