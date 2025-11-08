# Функция для скачивания файла с помощью curl
function Download-Image {
    param (
        [string]$Url,
        [string]$DestinationPath
    )
    # Создаем директорию, если она не существует
    $DestinationDir = Split-Path -Path $DestinationPath -Parent
    if (!(Test-Path -Path $DestinationDir)) {
        New-Item -ItemType Directory -Path $DestinationDir -Force
    }

    # Используем curl для скачивания файла, если он не существует
    if (!(Test-Path -Path $DestinationPath)) {
        Write-Host "Скачивание $DestinationPath..."
        # curl может сам определить имя файла из заголовков, если указать -O и -J
        # Но для явного указания пути используем -o
        # Параметры: -L (follow redirects), -o (output file), --create-dirs (create dirs if needed)
        # Проверим, нужно ли извлекать имя файла из URL, если оно не задано в $DestinationPath
        # В данном случае $DestinationPath содержит полный путь, включая имя файла
        # Используем -f для получения ошибки при 4xx/5xx кодах
        # Используем -sS для тихого режима и показа ошибок
        # Используем -R для повторных попыток
        # curl -L -f -sS --create-dirs -o $DestinationPath $Url
        # Более простой вариант с -J (content-disposition), который указывает curl использовать имя файла из заголовка
        # curl -L -f -sS --create-dirs -J -o $DestinationPath $Url
        # Однако, если мы хотим, чтобы curl использовал имя файла из заголовка Content-Disposition и сохранял в нужную папку,
        # можно передать путь к папке в -o и добавить / в конец (но curl может не понять это напрямую).
        # Лучше сначала создать директорию, а потом передать полный путь к файлу в -o.
        # Используем -z для проверки файла на дату (но в данном случае просто проверим на существование)
        # Самый простой способ: указать полный путь к файлу в -o
        # Но Content-Disposition может переопределить имя. Для этого нужно указать только папку.
        # curl -L -f -sS --create-dirs -J -o "$DestinationDir/" $Url # -J использует Content-Disposition
        # Это может создать файл в $DestinationDir с именем из заголовка. Но нам нужно, чтобы имя файла было в $DestinationPath.
        # Поэтому проще указать полный путь и отключить -J, или вручную извлечь имя из заголовка.
        # Но для простоты и совместимости с оригинальным поведением wget --content-disposition,
        # будем использовать -J и указывать директорию в -o.
        # $DestDir = $DestinationDir + [System.IO.Path]::DirectorySeparatorChar
        # curl -L -f -sS --create-dirs -J -o "$DestDir" $Url
        # Это создаст файл в $DestinationDir с именем из Content-Disposition.
        # Но нам нужно, чтобы имя файла было в $DestinationPath.
        # Альтернатива: получить имя файла из Content-Disposition вручную или использовать Invoke-WebRequest.
        # Invoke-WebRequest проще в этом случае и не требует отдельной установки.
        # Однако, если уж использовать curl, то можно так:
        # curl -L -f -sS --create-dirs -J -o "$DestinationDir/" $Url
        # Но тогда имя файла может отличаться от ожидаемого в $DestinationPath.
        # В оригинальном скрипте wget --content-disposition использовался, чтобы получить имя файла из заголовка.
        # В PowerShell Invoke-WebRequest делает это автоматически, если не указан -OutFile.
        # Если указан -OutFile, он использует указанное имя.
        # Поэтому, чтобы точно использовать имя из заголовка, можно так:
        # Invoke-WebRequest -Uri $Url -OutFile "$DestinationDir/"
        # Но это не работает напрямую. Нужно указать полное имя файла или использовать временное имя.
        # Лучше всего: создать директорию и использовать curl с -J и указать директорию.
        # Но для соответствия оригинальному скрипту, где имя файла в $DestinationPath фиксировано,
        # будем использовать curl с -o и указывать полный путь. Content-Disposition будет проигнорирован.
        # Это не совсем то же самое, что wget --content-disposition, но проще.
        # Если важно использовать имя из Content-Disposition, нужно использовать Invoke-WebRequest или парсить заголовки вручную.
        # Для простоты и соответствия логике wget --directory-prefix, будем использовать curl с полным именем файла в -o.
        # curl -L -f -sS --create-dirs -o $DestinationPath $Url
        # Однако, если в URL есть Content-Disposition, и мы хотим его использовать, нужно использовать Invoke-WebRequest.
        # Проверим, как wget --content-disposition себя ведет: он сохраняет файл в указанную директорию с именем из заголовка.
        # Поэтому, чтобы эмулировать это поведение, нужно:
        # 1. Узнать имя файла из Content-Disposition (или из URL, если Content-Disposition нет).
        # 2. Создать директорию.
        # 3. Сохранить файл с этим именем.
        # Invoke-WebRequest делает это автоматически, если не указывать -OutFile.
        # Но нам нужно указать директорию.
        # $response = Invoke-WebRequest -Uri $Url -Method Head
        # $contentDisposition = $response.Headers.'Content-Disposition'
        # if ($contentDisposition -match 'filename="([^"]+)"') {
        #     $fileName = $matches[1]
        # } else {
        #     $fileName = Split-Path -Leaf ([System.Uri]$Url).LocalPath
        # }
        # $fullPath = Join-Path -Path $DestinationDir -ChildPath $fileName
        # Invoke-WebRequest -Uri $Url -OutFile $fullPath
        # Это правильный способ, но избыточный, если имя файла в $DestinationPath уже правильное.
        # В оригинальном bash-скрипте имена файлов были получены через wget --content-disposition и лежат в нужных папках.
        # В PowerShell-скрипте мы явно указываем путь к файлу, куда он должен быть сохранен.
        # Так как оригинальные имена файлов неизвестны из скрипта, и wget сам их вычислял,
        # мы не можем точно воссоздать их поведение, не зная этих имен.
        # Вместо этого, мы будем использовать `curl -J -L -f -sS --create-dirs -o "$DestinationDir/"` и указывать директорию.
        # Это заставит curl использовать имя файла из Content-Disposition и сохранить его в нужной папке.
        # Но тогда мы не можем проверить на существование конкретного файла по имени $DestinationPath.
        # Для простоты и надежности, будем использовать Invoke-WebRequest, который по умолчанию использует имя файла из Content-Disposition.
        # Он автоматически создает директории при указании -OutFile с полным путем.
        # Но имя файла будет взято из Content-Disposition.
        # Это означает, что $DestinationPath должен указывать на директорию, а не на файл, или мы игнорируем Content-Disposition.
        # Для соответствия wget --content-disposition, лучше использовать Invoke-WebRequest без -OutFile, но тогда нужно указать директорию.
        # Или использовать Invoke-WebRequest с -OutFile, но тогда имя файла фиксировано.
        # Выберем вариант с Invoke-WebRequest и фиксированным именем файла, как если бы оно было известно заранее.
        # Это означает, что Content-Disposition игнорируется, но имя файла предсказуемо.
        # Альтернативно, можно использовать curl с -J и указать директорию, но тогда имя файла будет неизвестно.
        # В оригинальном скрипте имена файлов были получены wget.
        # Мы не можем их знать, но можем использовать уникальные имена или временные.
        # Лучше всего: использовать Invoke-WebRequest и позволить ему использовать имя из Content-Disposition, сохранив в нужной папке.
        # Но тогда структура вызова должна быть такой: Invoke-WebRequest -Uri $Url -OutFile "$DestinationDir\$FileNameFromHeader"
        # Как получить имя файла из заголовка в PowerShell?
        # См. пример выше с HEAD-запросом.
        # Или использовать -OutFile с указанием директории и временным именем, а потом переименовать.
        # Или использовать curl с -J и указать директорию.
        # Или использовать -OutFile с указанным именем файла (как в wget --directory-prefix + фиксированное имя, что не совсем правильно).
        # Попробуем вариант с Invoke-WebRequest и именем файла из заголовка, как это делает wget --content-disposition.
        # Но для этого нужно либо получить HEAD-ответ, либо позволить Invoke-WebRequest самому получить имя файла, указав только директорию.
        # В документации Invoke-WebRequest не сказано напрямую, что он сохранит файл в директорию с именем из заголовка, если не указан OutFile.
        # Он сохраняет в текущую директорию с именем из заголовка, если не указан OutFile.
        # Если указан OutFile и это директория, поведение не определено.
        # Проверим: OutFile должен быть полным путем к файлу.
        # Поэтому, чтобы эмулировать wget --content-disposition --directory-prefix=,
        # нужно получить имя файла из заголовка Content-Disposition и соединить с директорией.
        # Это делает следующий код:

        # Отправляем HEAD-запрос для получения заголовка Content-Disposition
        try {
            $response = Invoke-WebRequest -Uri $Url -Method Head -ErrorAction Stop
            $contentDisposition = $response.Headers.'Content-Disposition'
            if ($contentDisposition -and $contentDisposition -match 'filename[^;]*=.*?["\s]?([^";\s]+)["\s]?') {
                $fileName = $matches[1]
            } else {
                # Если Content-Disposition нет, извлекаем имя из URL
                $fileName = Split-Path -Leaf ([System.Uri]$Url).LocalPath
                # Убираем параметры из строки запроса, если они есть
                $fileName = $fileName -replace '\?.*$', ''
            }
        } catch {
            Write-Warning "Не удалось получить заголовки для $Url. Используем имя из URL. Ошибка: $($_.Exception.Message)"
            $fileName = Split-Path -Leaf ([System.Uri]$Url).LocalPath
            $fileName = $fileName -replace '\?.*$', ''
        }

        $fullFilePath = Join-Path -Path $DestinationDir -ChildPath $fileName

        # Проверяем, существует ли файл с этим именем в директории
        if (Test-Path -Path $fullFilePath) {
            Write-Host "Файл $fullFilePath уже существует, пропускаем."
        } else {
            Write-Host "Скачивание $fullFilePath из $Url..."
            try {
                # Скачиваем файл
                Invoke-WebRequest -Uri $Url -OutFile $fullFilePath -ErrorAction Stop
            } catch {
                Write-Error "Ошибка при скачивании $Url в $fullFilePath`: $($_.Exception.Message)"
            }
        }
    } else {
        Write-Host "Файл $DestinationPath уже существует, пропускаем."
    }
}


# --- Загрузка изображений ---

# Home
Download-Image -Url "https://unsplash.com/photos/wRuhOOaG-Z4/download?&force=true&w=1920" -DestinationPath "content\home_image.jpg" # Укажите ожидаемое имя файла

# Animals
Download-Image -Url "https://unsplash.com/photos/UC1pzyJFyvs/download?&force=true&w=1920" -DestinationPath "content\animals\animals_image.jpg" # Укажите ожидаемое имя файла

# Animals/Cats
Download-Image -Url "https://unsplash.com/photos/gKXKBY-C-Dk/download?force=true&w=1920" -DestinationPath "content\animals\cats\cat1.jpg" # Укажите ожидаемое имя файла
Download-Image -Url "https://unsplash.com/photos/75715CVEJhI/download?force=true&w=1920" -DestinationPath "content\animals\cats\amber-kipp-75715CVEJhI-unsplash.jpg"
Download-Image -Url "https://unsplash.com/photos/mJaD10XeD7w/download?&force=true&w=1920" -DestinationPath "content\animals\cats\alexander-london-mJaD10XeD7w-unsplash.jpg"
# Добавьте остальные изображения для Cats, указав ожидаемые имена файлов
Download-Image -Url "https://unsplash.com/photos/CEx86maLUSc/download?&force=true&w=1920" -DestinationPath "content\animals\cats\cat4.jpg"
Download-Image -Url "https://unsplash.com/photos/yMSecCHsIBc/download?&force=true&w=1920" -DestinationPath "content\animals\cats\cat5.jpg"
Download-Image -Url "https://unsplash.com/photos/rW-I87aPY5Y/download?&force=true&w=1920" -DestinationPath "content\animals\cats\cat6.jpg"
Download-Image -Url "https://unsplash.com/photos/p6yH8VmGqxo/download?&force=true&w=1920" -DestinationPath "content\animals\cats\cat7.jpg"
Download-Image -Url "https://unsplash.com/photos/LEpfefQf4rU/download?&force=true&w=1920" -DestinationPath "content\animals\cats\cat8.jpg"
Download-Image -Url "https://unsplash.com/photos/nKC772R_qog/download?&force=true&w=1920" -DestinationPath "content\animals\cats\cat9.jpg"

# Animals/Dogs
Download-Image -Url "https://unsplash.com/photos/Sg3XwuEpybU/download?&force=true&w=1920" -DestinationPath "content\animals\dogs\dog1.jpg"
Download-Image -Url "https://unsplash.com/photos/Mv9hjnEUHR4/download?&force=true&w=1920" -DestinationPath "content\animals\dogs\dog2.jpg"
Download-Image -Url "https://unsplash.com/photos/2l0CWTpcChI/download?&force=true&w=1920" -DestinationPath "content\animals\dogs\dog3.jpg"
Download-Image -Url "https://unsplash.com/photos/WX4i1Jq_o0Y/download?&force=true&w=1920" -DestinationPath "content\animals\dogs\dog4.jpg"

# Fashion & Beauty
Download-Image -Url "https://unsplash.com/photos/FkxXePJJH5g/download?force=true&w=1920" -DestinationPath "content\fashion-beauty\fashion1.jpg"
Download-Image -Url "https://unsplash.com/photos/63obHScZWZw/download?&force=true&w=1920" -DestinationPath "content\fashion-beauty\fashion2.jpg"
Download-Image -Url "https://unsplash.com/photos/7gqnlnCTvlg/download?&force=true&w=1920" -DestinationPath "content\fashion-beauty\fashion3.jpg"
Download-Image -Url "https://unsplash.com/photos/V94CguEmeos/download?&force=true&w=1920" -DestinationPath "content\fashion-beauty\fashion4.jpg"

# Nature
Download-Image -Url "https://unsplash.com/photos/ZS_XuDZmxpM/download?&force=true&w=1920" -DestinationPath "content\nature\nature1.jpg"
Download-Image -Url "https://unsplash.com/photos/U7BG3FOT5r8/download?&force=true&w=1920" -DestinationPath "content\nature\nature2.jpg"
Download-Image -Url "https://unsplash.com/photos/TUzsO59UFpo/download?&force=true&w=1920" -DestinationPath "content\nature\nature3.jpg"
Download-Image -Url "https://unsplash.com/photos/P45gR9kH0SM/download?&force=true&w=1920" -DestinationPath "content\nature\nature4.jpg"
Download-Image -Url "https://unsplash.com/photos/k_PbdrEs79g/download?force=true&w=1920" -DestinationPath "content\nature\nature5.jpg"
Download-Image -Url "https://unsplash.com/photos/4f8u5mFGKjw/download?&force=true&w=1920" -DestinationPath "content\nature\nature6.jpg"
Download-Image -Url "https://unsplash.com/photos/f_C_lFxqThI/download?&force=true&w=1920" -DestinationPath "content\nature\nature7.jpg"
Download-Image -Url "https://unsplash.com/photos/x7CyIC2jUaE/download?&force=true&w=1920" -DestinationPath "content\nature\nature8.jpg"
Download-Image -Url "https://unsplash.com/photos/RuaRTaKi-D4/download?force=true&w=1920" -DestinationPath "content\nature\nature9.jpg"

# Private
Download-Image -Url "https://unsplash.com/photos/gRknIewfaBs/download?force=true&w=1920" -DestinationPath "content\private\private1.jpg"
Download-Image -Url "https://unsplash.com/photos/QQ0naV2n-mg/download?force=true&w=1920" -DestinationPath "content\private\private2.jpg"
Download-Image -Url "https://unsplash.com/photos/_lQgFjsTgEs/download?force=true&w=1920" -DestinationPath "content\private\private3.jpg"
Download-Image -Url "https://unsplash.com/photos/7pYqHNp37Pg/download?force=true&w=1920" -DestinationPath "content\private\private4.jpg"
Download-Image -Url "https://unsplash.com/photos/6dH1__uRYtg/download?force=true&w=1920" -DestinationPath "content\private\private5.jpg"
Download-Image -Url "https://unsplash.com/photos/t2WImwH1Fa0/download?force=true&w=1920" -DestinationPath "content\private\private6.jpg"

# Featured
Download-Image -Url "https://unsplash.com/photos/fcwZsjyqp0s/download?force=true&w=1920" -DestinationPath "content\featured-album\featured1.jpg"
Download-Image -Url "https://unsplash.com/photos/IFlBNNOLHUo/download?force=true&w=1920" -DestinationPath "content\featured-album\featured2.jpg"
Download-Image -Url "https://unsplash.com/photos/pjszS6Q2g_Y/download?force=true&w=1920" -DestinationPath "content\featured-album\featured3.jpg"


# --- Добавление описаний с помощью exiftool ---

# Проверяем, установлен ли exiftool
if (Get-Command C:\Users\addmi\Documents\exiftool-13.41_64\exiftool(-k).exe -ErrorAction SilentlyContinue) {
    # exiftool найден, выполняем команды
    # Убедитесь, что имена файлов совпадают с теми, что были скачаны
    $cat1Path = "content\animals\cats\alexander-london-mJaD10XeD7w-unsplash.jpg"
    $cat2Path = "content\animals\cats\amber-kipp-75715CVEJhI-unsplash.jpg"

    if (Test-Path $cat1Path) {
        Write-Host "Установка описания для $cat1Path"
        C:\Users\addmi\Documents\exiftool-13.41_64\exiftool(-k).exe -overwrite_original -ImageDescription="Brown tabby cat on white stairs by Alexander London" $cat1Path
    } else {
        Write-Warning "Файл $cat1Path не найден для установки описания."
    }

    if (Test-Path $cat2Path) {
        Write-Host "Установка описания для $cat2Path"
        C:\Users\addmi\Documents\exiftool-13.41_64\exiftool(-k).exe -overwrite_original -ImageDescription="selective focus photography of orange and white cat on brown table by Amber Kipp" $cat2Path
    } else {
        Write-Warning "Файл $cat2Path не найден для установки описания."
    }
} else {
    Write-Error "exiftool не найден. Убедитесь, что он установлен и добавлен в PATH."
}