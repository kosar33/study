<# :
@echo off
chcp 65001 >nul
echo ==================================================
echo Запуск скрипта поиска и копирования картинок...
echo ==================================================
powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-Command -ScriptBlock ([Scriptblock]::Create((Get-Content -LiteralPath '%~f0' -Raw)))"
echo.
pause
exit /b
#>

# --- НАСТРОЙКИ ПУТЕЙ ---
$mdFolder = "Физика"
$sourceAssets = "assets"
$destAssets = "Физика\assets"

# Создаем папку назначения, если её нет
if (!(Test-Path -LiteralPath $destAssets)) {
    New-Item -ItemType Directory -Force -Path $destAssets | Out-Null
    Write-Host "Создана папка: $destAssets" -ForegroundColor Green
}

# Ищем все .md файлы в папке Физика (включая подпапки)
$mdFiles = Get-ChildItem -Path $mdFolder -Filter "*.md" -Recurse -File
$imagesToCopy = @()

Write-Host "Анализ Markdown файлов в папке '$mdFolder'..."

foreach ($file in $mdFiles) {
    # Читаем файл в кодировке UTF-8
    $content = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
    
    if ([string]::IsNullOrWhiteSpace($content)) { continue }

    # 1. Стандартный Markdown формат: ![описание](assets/image.png) или ![описание](image.png)
    $regexStandard = '!\[.*?\]\((.*?)\)'
    $matchesStandard = [regex]::Matches($content, $regexStandard)
    foreach ($m in $matchesStandard) {
        $imgPath = $m.Groups[1].Value
        # Извлекаем только имя файла, отбрасывая путь (например, "assets/")
        $imagesToCopy += Split-Path $imgPath -Leaf
    }

    # 2. Формат Obsidian (Wikilinks): ![[image.png]] или ![[image.png|200]]
    $regexObsidian = '!\[\[(.*?)\]\]'
    $matchesObsidian = [regex]::Matches($content, $regexObsidian)
    foreach ($m in $matchesObsidian) {
        $imgName = $m.Groups[1].Value
        # Убираем параметры изменения размера в Obsidian (все что после знака |)
        $imgName = $imgName -replace '\|.*$', ''
        $imagesToCopy += $imgName
    }
}

# Оставляем только уникальные имена файлов, чтобы не копировать одно и то же дважды
$uniqueImages = $imagesToCopy | Select-Object -Unique

$copiedCount = 0
$notFoundCount = 0

Write-Host "Начало копирования..." -ForegroundColor Cyan

foreach ($img in $uniqueImages) {
    # Декодируем URL (например, заменяем %20 на пробел)
    $cleanImgName = $img -replace "%20", " "

    $sourcePath = Join-Path $sourceAssets $cleanImgName
    $destPath = Join-Path $destAssets $cleanImgName

    # Проверяем, существует ли файл в глобальной папке assets/
    if (Test-Path -LiteralPath $sourcePath) {
        Copy-Item -LiteralPath $sourcePath -Destination $destPath -Force
        Write-Host "[+] Скопировано: $cleanImgName" -ForegroundColor Green
        $copiedCount++
    } else {
        Write-Host "[-] Не найдено в assets/: $cleanImgName" -ForegroundColor Yellow
        $notFoundCount++
    }
}

Write-Host "`n=================================================="
Write-Host "Статистика:" -ForegroundColor Cyan
Write-Host "Уникальных картинок найдено в текстах: $($uniqueImages.Count)"
Write-Host "Успешно скопировано: $copiedCount" -ForegroundColor Green
if ($notFoundCount -gt 0) {
    Write-Host "Не удалось найти файлов: $notFoundCount" -ForegroundColor Red
}
Write-Host "=================================================="