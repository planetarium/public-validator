param (
    [string]$Path,
    [int]$PartSizeMB = 8
)

if ($PartSizeMB -ge 5) {
    $partSizeBytes = $PartSizeMB * 1024 * 1024
    $fileStream = [System.IO.File]::OpenRead($Path)
    $buffer = New-Object byte[] $partSizeBytes
    $md5 = [System.Security.Cryptography.MD5]::Create()
    $chunkCount = 0
    $stringAsStream = [System.IO.MemoryStream]::new()

    while ($true) {
        $bytesRead = $fileStream.Read($buffer, 0, $buffer.Length)
        if ($bytesRead -le 0) { break }

        $hash = $md5.ComputeHash($buffer, 0, $bytesRead)
        $stringAsStream.Write($hash, 0, $hash.Length)
        $chunkCount++
    }

    $fileStream.Close()
    $stringAsStream.Position = 0
    $fileHash = Get-FileHash -InputStream $stringAsStream -Algorithm MD5
    $stringAsStream.Close()
    $hash = $fileHash.Hash.ToLower()
    $chunkCount -ge 2 ? "$hash-$chunkCount" : $hash
}
else {
    $fileHash = Get-FileHash -Path $Path -Algorithm MD5
    $fileHash.Hash.ToLower()
}