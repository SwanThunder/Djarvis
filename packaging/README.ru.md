# Сборка

[English version](README.md)

Скрипты собирают рабочую папку приложения со встроенными средами. Архивы и собранная папка в репозиторий не попадают.

## Что делает

- `runtimes.json` закрепляет каждый архив среды: имя, версию, https-адрес, имя файла, размер, SHA-256 и что распаковывать.
- `build-app.ps1` проверяет, что каждый архив лежит в `cache/build/runtimes/` с закреплёнными размером и SHA-256 (если его нет — скачивает; повреждённый файл сохраняет и отклоняет), распаковывает нужные части через временную папку внутри `build/`, отклоняет элементы архива, ведущие за пределы целевой папки, и заменяет `build/app/` целиком:
  - `runtime/python/` — встроенный Python 3.12; запускатель `python.exe` переименован в `djarvis-core.exe`, `pythonw.exe` не включается;
  - `runtime/pgsql/` — только `bin`, `lib` и `share` PostgreSQL, без StackBuilder, файлов для разработки, тестов и документации (см. `exclude` в манифесте); в `bin` добавляются три закреплённые x64 release DLL Visual C++ из пакета Microsoft;
  - `licenses/<среда>/` — файлы лицензий из архивов;
  - интерфейс Windows (`Djarvis.exe` и его файлы), если есть `ui/build/windows/x64/runner/Release`; иначе эта часть пропускается с сообщением.
- `smoke-runtimes.ps1` запускает из `build/app` команды `djarvis-core.exe -I`, `postgres --version`, `initdb --version` и `pg_ctl --version` с `PATH`, сокращённым до системной папки Windows, и сверяет версии с манифестом. Кластер базы не создаётся.

## Запуск

```powershell
powershell -File packaging/build-app.ps1        # -Offline: только из кэша
powershell -File packaging/smoke-runtimes.ps1
powershell -File scripts/check.ps1 -Build -Runtimes   # всё сразу, как в CI
```

`scripts/check.ps1` без `-Runtimes` ничего не скачивает. Первая сборка скачивает около 0,40 ГБ; следующие берут архивы из кэша.

## Обновление среды

1. Измените `version`, `url`, `file` и `size` в `runtimes.json`.
2. Python: возьмите SHA-256 из пакета Sigstore, опубликованного рядом с архивом на python.org, и проверьте, что MD5 файла совпадает со страницей выпуска. PostgreSQL: производитель не публикует контрольную сумму, поэтому скачайте архив дважды отдельными запросами и закрепите хеш, только если результаты совпали.
3. Обновите `sha256` и `sha256_source`, затем запустите сборку и смоук. При расхождении сборка останавливается до распаковки.

Каталог Microsoft Visual Studio указывает закреплённые URL и SHA-256 CRT VSIX, но размер 3 394 118 байт. Две отдельные загрузки из одного источника Microsoft имели тот же SHA-256 и размер 3 380 682 байта; именно этот размер проверяет сборка. Из `Contents/VC/Redist/MSVC/14.52.37025/x64/Microsoft.VC145.CRT/` извлекаются только `msvcp140.dll`, `vcruntime140.dll` и `vcruntime140_1.dll`. Их SHA-256 закреплены и проверяются; VSIX сохраняется в кэше и не входит в приложение. Файлы `debug_nonredist` не используются. Смоук требует наличия этих DLL рядом с PostgreSQL, но не заменяет проверку на чистой Windows.

Распространение этих неизменённых DLL разрешено только лицензированным пользователям Visual Studio на условиях соответствующей лицензии; см. [список распространяемых файлов Visual Studio 2026](https://learn.microsoft.com/en-us/visualstudio/releases/2026/redistribution) и [руководство Microsoft по Visual C++](https://learn.microsoft.com/en-us/cpp/windows/redistributing-visual-cpp-files). Перед выпуском проверьте применимую лицензию и условия распространения. В VSIX нет текста лицензии; на DLL распространяются условия Microsoft.
