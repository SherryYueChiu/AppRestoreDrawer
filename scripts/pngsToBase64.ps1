# 指定當前目錄，或者你可以指定一個特定的路徑
$currentDirectory = Get-Location

# 建立一個目錄來存放轉換後的Base64檔案
$outputFolder = Join-Path $currentDirectory "ConvertedBase64"
if (-not (Test-Path $outputFolder)) {
    New-Item -ItemType Directory -Path $outputFolder | Out-Null
}

# 獲取當前目錄下所有的png文件
$pngFiles = Get-ChildItem -Path $currentDirectory -Filter "*.png"

foreach ($pngFile in $pngFiles) {
    Write-Host "正在處理圖片文件: $($pngFile.Name)"

    try {
        # 讀取圖片文件的所有字節
        $bytes = [System.IO.File]::ReadAllBytes($pngFile.FullName)

        # 將字節數組轉換為Base64字串
        $base64String = [System.Convert]::ToBase64String($bytes)

        # 定義Base64字串的輸出檔案路徑
        # 檔案名稱會是原始圖片檔名 (不含副檔名) 加上 '_base64.txt'
        $base64OutputFilePath = Join-Path $outputFolder "$($pngFile.BaseName)_base64.txt"

        # 將Base64字串保存到檔案
        Set-Content -Path $base64OutputFilePath -Value $base64String

        Write-Host "Base64字串已保存到: $($base64OutputFilePath)"
        Write-Host "---"

    } catch {
        Write-Error "處理 $($pngFile.Name) 時發生錯誤: $($_.Exception.Message)"
        # 輸出詳細的錯誤信息，幫助調試
        Write-Error "錯誤詳細資訊: $($_.Exception.ToString())"
    }
}

Write-Host "所有PNG圖片處理完畢。"
