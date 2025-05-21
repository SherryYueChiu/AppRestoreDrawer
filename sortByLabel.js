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

// 使用範例
const data = [
    { label: 'app1', value: 1 },
    { label: 'app2', value: 2 },
    { label: 'app3', value: 3 }
];

console.log('排序後：', sortByLabel(data));