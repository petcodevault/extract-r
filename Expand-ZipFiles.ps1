# Путь к установленному 7-Zip (может потребоваться изменить)
$zipExe = "C:\Program Files\7-Zip\7z.exe"

# Функция для распаковки zip-файла с помощью 7-Zip и удаления исходного zip-файла
function Expand-ZipFile {
    param(
        [string]$zipFile
    )

    # Путь для распаковки, используем имя архива + "_auto_unzip"
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($zipFile)
    $extractPath = (Join-Path -Path (Split-Path -Parent $zipFile) -ChildPath "$baseName`_auto_unzip")

    if (Test-Path -LiteralPath "$extractPath") {
        Remove-Item -LiteralPath "$extractPath" -Recurse -Force
    }

    New-Item -Path "$extractPath" -ItemType Directory | Out-Null

    # Распаковываем zip-файл
    & $zipExe x "$zipFile" -o"$extractPath" -y -pwrong_password

    # Проверяем результат распаковки
    if ($LastExitCode -eq 0) {
        Write-Output "Распаковка успешно завершена для: $zipFile"
        
        # Удаляем исходный zip-файл после успешной распаковки
        Remove-Item -LiteralPath "$zipFile" -Force
    } else {
        Write-Output "Ошибка при распаковке для: $zipFile"
    }
}

# Рекурсивная функция для обхода каталогов
function Process-Folder {
    param(
        [string]$folderPath
    )

    # Получаем все файлы и папки в текущей директории
    $items = Get-ChildItem -LiteralPath "$folderPath" -Force | Sort-Object Name

    foreach ($item in $items) {
        if ($item.PSIsContainer) {
            # Если это папка, рекурсивно обрабатываем её

            #Write-Output $item.FullName
            Process-Folder $item.FullName
        }
    }

    foreach ($item in $items) {
        if ($item.PSIsContainer) {
        } elseif ($item.Extension -eq ".zip") {
            # Если это zip-файл, распаковываем его
            Expand-ZipFile $item.FullName
        }
    }
}

# Основной скрипт начинается здесь

# Получаем аргументы командной строки (имя папки)
if ($args.Length -ne 1) {
    Write-Output "Использование: `n`n Expand-ZipFiles.ps1 <путь_к_папке>"
    exit 1
}

# Путь к папке с zip-файлами
$folderPath = $args[0]


# Проверяем, существует ли указанная папка
if (-not (Test-Path $folderPath -PathType Container)) {
    Write-Output "Указанная папка не существует: $folderPath"
    exit 1
}

# Начинаем обработку с указанной папки
Process-Folder $folderPath
