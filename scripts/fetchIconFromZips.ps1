# 指定當前目錄，或者你可以指定一個特定的路徑
$currentDirectory = Get-Location

# 建立一個目錄來存放提取出來的icon.png
$outputFolder = Join-Path $currentDirectory "ExtractedIcons"
if (-not (Test-Path $outputFolder)) {
    New-Item -ItemType Directory -Path $outputFolder | Out-Null
}

# 獲取當前目錄下所有的zip文件
$zipFiles = Get-ChildItem -Path $currentDirectory -Filter "*.zip"

foreach ($zipFile in $zipFiles) {
    Write-Host "正在處理文件: $($zipFile.Name)"

    # 定義要提取的檔案名
    $fileToExtract = "icon.png"

    try {
        # 載入System.IO.Compression.FileSystem組件，用於處理ZIP文件
        Add-Type -AssemblyName System.IO.Compression.FileSystem

        $iconFound = $false
        $extractedFilePath = ""

        # 使用ZipFile類來讀取ZIP文件
        $zipArchive = [System.IO.Compression.ZipFile]::OpenRead($zipFile.FullName)
        foreach ($entry in $zipArchive.Entries) {
            if ($entry.FullName -eq $fileToExtract) {
                $iconFound = $true # 修正：將 'true' 改為 '$true'
                $extractedFilePath = Join-Path $outputFolder "$($zipFile.BaseName)_icon.png"

                # 檢查目標文件是否存在，如果存在則刪除以便覆蓋
                if (Test-Path $extractedFilePath) {
                    Remove-Item $extractedFilePath -Force
                }

                # 使用流的方式提取檔案，兼容性更好
                $inputStream = $entry.Open()
                $outputStream = [System.IO.File]::Create($extractedFilePath)
                $inputStream.CopyTo($outputStream)
                $outputStream.Dispose()
                $inputStream.Dispose()
                break
            }
        }
        # 關閉ZipArchive對象以釋放文件鎖定
        $zipArchive.Dispose()

        if ($iconFound) {
            Write-Host "已提取: $($extractedFilePath)"

            # 將提取出來的圖片轉換為Base64
            $bytes = [System.IO.File]::ReadAllBytes($extractedFilePath)
            $base64String = [System.Convert]::ToBase64String($bytes)

            # 將Base64字串輸出到控制台
            Write-Host "Base64 for $($zipFile.BaseName)_icon.png:"
            Write-Host $base64String
            Write-Host "---"

            # 將Base64字串保存到一個文件
            $base64OutputFilePath = Join-Path $outputFolder "$($zipFile.BaseName)_icon_base64.txt"
            Set-Content -Path $base64OutputFilePath -Value $base64String
            Write-Host "Base64字串已保存到: $($base64OutputFilePath)"
            Write-Host "---"

        } else {
            Write-Warning "在 $($zipFile.Name) 中找不到 icon.png。"
        }

    } catch {
        Write-Error "處理 $($zipFile.Name) 時發生錯誤: $($_.Exception.Message)"
        # 輸出詳細的錯誤信息，幫助調試
        Write-Error "錯誤詳細資訊: $($_.Exception.ToString())"
    }
}

Write-Host "所有ZIP文件處理完畢。"
