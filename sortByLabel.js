/**
 * 根據 label 屬性對物件陣列進行排序
 * @param {Array} arr - 要排序的物件陣列
 * @returns {Array} - 排序後的物件陣列
 */
function sortByLabel(arr) {
    return [...arr].sort((a, b) => {
        // 確保兩個物件都有 label 屬性
        if (!a.label || !b.label) {
            return 0;
        }
        // 使用 localeCompare 進行字串比較，支援中文排序
        return a.label.localeCompare(b.label, 'zh-TW');
    });
}

// 檢查是否提供了檔案路徑參數
if (process.argv.length < 3) {
    console.error('請提供 JSON 檔案路徑');
    console.error('使用方式: node sortByLabel.js <json檔案路徑>');
    process.exit(1);
}

const fs = require('fs');
const path = require('path');

// 讀取並處理 JSON 檔案
try {
    const filePath = process.argv[2];
    const jsonData = fs.readFileSync(filePath, 'utf8');
    const data = JSON.parse(jsonData);

    // 檢查輸入是否為陣列
    if (!Array.isArray(data)) {
        console.error('錯誤：JSON 檔案必須包含一個陣列');
        process.exit(1);
    }

    // 排序資料
    const sortedData = sortByLabel(data);

    // 將排序後的結果寫入原始檔案
    fs.writeFileSync(filePath, JSON.stringify(sortedData, null, 2));
    console.log(`排序完成，結果已更新至：${filePath}`);

} catch (error) {
    console.error('錯誤：', error.message);
    process.exit(1);
}