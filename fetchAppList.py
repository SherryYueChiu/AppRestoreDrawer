import subprocess
import os
import zipfile
import base64
import json
from pathlib import Path

# === 設定區 ===
aapt_path = r"C:\Users\sherr\AppData\Local\Android\Sdk\build-tools\33.0.2\aapt.exe"  # 修改成你的
apk_dir = Path("user_apks")
icon_dir = Path("icons")
output_json = Path("apps.json")

apk_dir.mkdir(exist_ok=True)
icon_dir.mkdir(exist_ok=True)

def get_user_packages():
    print("📦 抓取使用者安裝 App 清單中...")
    result = subprocess.run(["adb", "shell", "pm", "list", "packages", "-3"], capture_output=True, text=True)
    packages = []
    for line in result.stdout.strip().splitlines():
        if line.startswith("package:"):
            package = line.split("package:")[1].strip()
            packages.append(package)
    return packages

def get_apk_path(package_name):
    result = subprocess.run(["adb", "shell", "pm", "path", package_name], capture_output=True, text=True)
    lines = result.stdout.strip().splitlines()
    for line in lines:
        if line.startswith("package:"):
            return line.split("package:")[1].strip()
    return None

def pull_apk(remote_path, local_path):
    try:
        subprocess.run(
            ["adb", "pull", remote_path, str(local_path)],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            timeout=15  # 最多等 15 秒
        )
    except subprocess.TimeoutExpired:
        print(f"⏱️ ADB pull 超時：{remote_path}，略過")
        return False
    except Exception as e:
        print(f"❌ ADB pull 發生錯誤：{e}")
        return False
    return True

def parse_apk(apk_path):
    try:
        result = subprocess.run(
            [aapt_path, "dump", "badging", str(apk_path)],
            capture_output=True,
            text=True,
            encoding="utf-8",
            check=True
        )
        label = "Unknown"
        icon_rel_path = None

        for line in result.stdout.splitlines():
            if line.startswith("application-label:"):
                label = line.split(":", 1)[1].strip().strip("'")
            elif "application-icon-" in line or line.startswith("application-icon:"):
                icon_rel_path = line.split(":", 1)[1].strip().strip("'")
                break

        return label, icon_rel_path
    except subprocess.CalledProcessError:
        print(f"❌ 無法解析 APK：{apk_path}")
        return None, None

def extract_icon(apk_path, icon_rel_path, out_path):
    try:
        with zipfile.ZipFile(apk_path, 'r') as zip_ref:
            if icon_rel_path in zip_ref.namelist():
                with zip_ref.open(icon_rel_path) as icon_file:
                    data = icon_file.read()
                    with open(out_path, "wb") as f:
                        f.write(data)
                return True
    except Exception as e:
        print(f"⚠️ 抽圖失敗：{icon_rel_path} from {apk_path} → {e}")
    return False

def encode_icon_base64(path):
    with open(path, "rb") as f:
        return "data:image/png;base64," + base64.b64encode(f.read()).decode("utf-8")

def main():
    packages = get_user_packages()
    apps = []
    total = len(packages)
    print(f"📲 共找到 {total} 個使用者安裝 App")

    for i, package in enumerate(packages):
        print(f"\n🔍 [{i+1}/{total}] 處理 {package}")
        apk_path_remote = get_apk_path(package)
        if not apk_path_remote:
            print("⚠️ 無法取得 APK 路徑，略過")
            continue

        apk_path_local = apk_dir / f"{package}.apk"
        if not pull_apk(apk_path_remote, apk_path_local):
          continue

        label, icon_rel = parse_apk(apk_path_local)
        if not icon_rel:
            print("⚠️ 無圖示，略過")
            continue

        icon_path = icon_dir / f"{package}.png"
        if not extract_icon(apk_path_local, icon_rel, icon_path):
            print("⚠️ 抽圖失敗，略過")
            continue

        icon_b64 = encode_icon_base64(icon_path)
        apps.append({
            "package": package,
            "label": label,
            "icon": icon_b64
        })

    with open(output_json, "w", encoding="utf-8") as f:
        json.dump(apps, f, indent=2, ensure_ascii=False)

    print(f"\n✅ 完成！成功產出 {len(apps)} 個 App，結果寫入 {output_json}")

if __name__ == "__main__":
    main()
