param(
    [Uri]$Url,
    [ValidateScript({ Test-Path -Path $_ -PathType Container })]
    [string]$OutputPath
)

$name = Split-Path -Path $Url.PathAndQuery -Leaf
$fileUrl = $Url
$filePath = Join-Path -Path $OutputPath -ChildPath "$name"
$tempPath = Join-Path -Path $OutputPath -ChildPath "$name.temp"
$infoPath = Join-Path -Path $OutputPath -ChildPath "$name.head.json"

$info = @{}
if (Test-Path -Path $infoPath -PathType Leaf) {
    $info = Get-Content -Path $infoPath | ConvertFrom-Json -AsHashtable
}

if (Test-Path -Path $filePath -PathType Leaf) {
    $headLength = $info ? $info["Length"] : $null
    $headTime = $info ? $info["LastWriteTime"] : $null
    $headTime = $headTime ? (Get-Date $headTime) : $null
    $actualLength = (Get-Item -Path $filePath).Length
    $actualTime = (Get-Item -Path $filePath).LastWriteTime
    if (($headLength -ne $actualLength) -or ($headTime -ne $actualTime)) {
        Remove-Item -Path $filePath
    }
}

if (Test-Path -Path $tempPath -PathType Leaf) {
    Invoke-WebRequest -Uri $fileUrl -OutFile $tempPath -Resume
    Move-Item -Path $tempPath -Destination $filePath
}
elseif (!(Test-Path -Path $filePath -PathType Leaf)) {
    Invoke-WebRequest -Uri $fileUrl -OutFile $tempPath
    Move-Item -Path $tempPath -Destination $filePath
}

if (!$info["Length"]) {
    $info["Length"] = (Get-Item -Path $filePath).Length
}

if (!$info["LastWriteTime"]) {
    $lastWriteTime = (Get-Item -Path $filePath).LastWriteTime
    $info["LastWriteTime"] = ($lastWriteTime | ConvertTo-Json).Trim("`"")
}

if (!$info["ETag"]) {
    $head = Invoke-WebRequest -Uri $fileUrl -Method HEAD
    $info["ETag"] = ($head.BaseResponse.Headers.Etag.Tag).Trim("`"")
    ./scripts/verify-file.ps1 -Path $filePath -ETag $info["ETag"]
}
    
Set-Content -Path $infoPath -Value ($info | ConvertTo-Json)

$filePath
