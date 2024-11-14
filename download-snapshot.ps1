param(
    [Parameter(Mandatory = $true)]
    [Uri]$Url,
    [string]$OutputPath = "store"
)

$OutputPath = New-Item $OutputPath -ItemType Directory -Force -ErrorAction SilentlyContinue
$baseUrl = $Url[-1] -eq '/' ? $Url : [Uri]"$Url/"
$tempPath = Join-Path -Path $PSScriptRoot -ChildPath ".temp"
$tempPath = New-Item -Path $tempPath -ItemType Directory -Force -ErrorAction SilentlyContinue

function DownloadEpoch {
    param(
        [string]$Name
    )

    $jsonName = "$Name.json"
    $jsonUrl = "$($baseUrl)$jsonName"
    $jsonOutputPath = ./scripts/download-file.ps1 -Url $jsonUrl -OutputPath $tempPath

    Get-Content -Path $jsonOutputPath
    | ConvertFrom-Json
    | Select-Object -Property BlockEpoch, TxEpoch, PreviousBlockEpoch, PreviousTxEpoch
}

function DownloadZip {
    param(
        [string]$Name
    )

    $zipName = "$Name.zip"
    $zipUrl = "$($baseUrl)$zipName"
    ./scripts/download-file.ps1 -Url $zipUrl -OutputPath $tempPath
}

function ExtractZip {
    param(
        [string]$Name
    ) 

    $zipName = "$Name.zip"
    $zipOutputPath = Join-Path -Path $tempPath -ChildPath $zipName
    Expand-Archive -Path $zipOutputPath -DestinationPath $OutputPath -Force -Verbose
}

$epoches = @()
$epoch = DownloadEpoch -Name "latest"
$epochName = "snapshot-$($epoch.BlockEpoch)-$($epoch.TxEpoch)"

$epoches += "state_latest"

while ($epoch.PreviousBlockEpoch -ne 0) {
    Write-Host $epochName
    $epoch = DownloadEpoch -Name $epochName
    $epoches += $epochName
    $epochName = "snapshot-$($epoch.PreviousBlockEpoch)-$($epoch.PreviousBlockEpoch)"
}

for ($i = 0; $i -lt $epoches.Length; $i++) {
    $item = $epoches[$i]
    Write-Host "Downloading: $zipName"
    DownloadZip -Name $item
    Write-Host "Downloaded: $zipName"
}

for ($i = $epoches.Length - 1; $i -ge 0; $i--) {
    $item = $epoches[$i]
    Write-Host "Extracting: $zipName"
    ExtractZip($epoches[$i])
    Write-Host "Extracted: $zipName"
}
