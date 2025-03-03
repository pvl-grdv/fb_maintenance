@echo off
chcp 866 > NUL
setlocal EnableDelayedExpansion

REM ===================================================================
REM Cкрипт обслуживания Firebird БД
REM ===================================================================

REM Параметры по умолчанию
SET ISC_USER=SYSDBA
SET ISC_PASSWORD=masterkey
SET DB_PATH=%CD%
SET PATTERN=*.ecodb
SET FIREBIRD_BIN=C:\PROGRA~2\Integral\FireBird\bin
SET BACKUP_DIR=%CD%\backup
SET LOG_DIR=%CD%\log
SET LOGFILE=%LOG_DIR%\log_%date:~6,4%%date:~3,2%%date:~0,2%.log

REM Обработка параметров командной строки
:param_loop
if "%~1"=="" goto param_done

if /i "%~1"=="-h" goto display_help
if /i "%~1"=="--help" goto display_help
if /i "%~1"=="-u" (
    set "ISC_USER=%~2"
    shift
    shift
    goto param_loop
)
if /i "%~1"=="-p" (
    set "ISC_PASSWORD=%~2"
    shift
    shift
    goto param_loop
)
if /i "%~1"=="-d" (
    set "DB_PATH=%~2"
    shift
    shift
    goto param_loop
)
if /i "%~1"=="-b" (
    set "BACKUP_DIR=%~2"
    shift
    shift
    goto param_loop
)
if /i "%~1"=="-l" (
    set "LOG_DIR=%~2"
    shift
    shift
    goto param_loop
)
if /i "%~1"=="-f" (
    set "PATTERN=%~2"
    shift
    shift
    goto param_loop
)
shift
goto param_loop

:display_help
echo.
echo Скрипт обслуживания баз данных Firebird
echo.
echo Использование: %~nx0 [ПАРАМЕТРЫ]
echo.
echo Параметры:
echo   -u USERNAME       Имя пользователя Firebird (по умолчанию: SYSDBA)
echo   -p PASSWORD       Пароль пользователя Firebird (по умолчанию: masterkey)
echo   -d PATH           Путь к директории с базами данных (по умолчанию: текущая директория)
echo   -f PATTERN        Шаблон файлов для обработки (по умолчанию: *.ecodb)
echo   -b PATH           Директория для резервных копий (по умолчанию: .\backup)
echo   -l PATH           Директория для логов (по умолчанию: .\log)
echo   -h, --help        Показать эту справку
echo.
echo Примеры: 
echo   %~nx0             # Обработать все .ecodb файлы в текущей директории
echo   %~nx0 -d C:\Data  # Обработать все .ecodb файлы в директории C:\Data
echo   %~nx0 -f db1.ecodb  # Обработать только файл db1.ecodb
echo.
exit /b 0

:param_done

IF NOT EXIST "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"
IF NOT EXIST "%LOG_DIR%" mkdir "%LOG_DIR%"

echo %date% %time%: Начало процесса > "%LOGFILE%"
echo Директория поиска баз данных: %DB_PATH% >> "%LOGFILE%"

REM Проверка наличия утилит Firebird
IF NOT EXIST "%FIREBIRD_BIN%\gfix.exe" (
    echo Ошибка: Утилиты Firebird не найдены в %FIREBIRD_BIN%
    echo Скрипт предполагает, что СУБД Firebird для УПРЗА Эколог была установлена в директории по умолчанию.
    echo Если это не так, следует изменить путь к директории с исполняемыми файлами, отредактировав переменную FIREBIRD_BIN в этом скрипте.
    echo.
    echo Ошибка: Утилиты Firebird не найдены в %FIREBIRD_BIN% >> "%LOGFILE%"
    pause
    exit /b 1
)

echo Поиск %PATTERN% файлов в директории %DB_PATH%...
echo Поиск %PATTERN% файлов в директории %DB_PATH%... >> "%LOGFILE%"

SET FILE_FOUND=0
FOR %%F IN ("%DB_PATH%\%PATTERN%") DO (
    SET FILE_FOUND=1
    SET CURRENT_DB=%%~fF
    SET DB_NAME=%%~nF
    SET DB_DIR=%%~dpF
    
    echo Найдена база данных: %%~nxF
    echo Найдена база данных: %%~nxF >> "%LOGFILE%"
    
    REM Проверка, не используется ли база данных в данный момент
    echo Проверка использования базы данных...
    echo Проверка использования базы данных... >> "%LOGFILE%"
    
    "%FIREBIRD_BIN%\gfix.exe" -shut -tran 1 "!CURRENT_DB!" >nul 2>&1
    if !ERRORLEVEL! NEQ 0 (
        echo ОШИБКА: База данных !DB_NAME! используется другими пользователями и не может быть обработана.
        echo ОШИБКА: База данных !DB_NAME! используется другими пользователями и не может быть обработана. >> "%LOGFILE%"
        goto :continue
    )
    
    "%FIREBIRD_BIN%\gfix.exe" -online "!CURRENT_DB!" >nul 2>&1
    
    REM Задаем имена файлов для бэкапа и восстановленной базы
    SET BACKUP_FILE=%BACKUP_DIR%\%%~nF_%date:~6,4%%date:~3,2%%date:~0,2%.backup
    SET NEW_DB=!DB_DIR!%%~nF_new.ecodb
    
    echo Обработка базы данных: %%~nxF
    echo Обработка базы данных: %%~nxF >> "%LOGFILE%"
    
    echo Шаг 1: Восстановление и ремонт базы данных...
    "%FIREBIRD_BIN%\gfix.exe" -mend "!CURRENT_DB!" >> "%LOGFILE%" 2>&1
    IF !ERRORLEVEL! NEQ 0 (
        echo ОШИБКА: Восстановление базы данных не удалось >> "%LOGFILE%"
        echo ОШИБКА: Восстановление базы данных не удалось
        goto :continue
    ) ELSE (
        echo Восстановление базы данных выполнено успешно >> "%LOGFILE%"
        echo Восстановление базы данных выполнено успешно
    )
    
    echo Шаг 2: Создание резервной копии...
    "%FIREBIRD_BIN%\gbak.exe" -b -v -ig "!CURRENT_DB!" "!BACKUP_FILE!" >> "%LOGFILE%" 2>&1
    IF !ERRORLEVEL! NEQ 0 (
        echo ОШИБКА: Создание резервной копии не удалось >> "%LOGFILE%"
        echo ОШИБКА: Создание резервной копии не удалось
        goto :continue
    ) ELSE (
        echo Резервная копия создана успешно >> "%LOGFILE%"
        echo Резервная копия создана успешно
    )

    echo Шаг 3: Восстановление из резервной копии...
    "%FIREBIRD_BIN%\gbak.exe" -c -v "!BACKUP_FILE!" "!NEW_DB!" >> "%LOGFILE%" 2>&1
    IF !ERRORLEVEL! NEQ 0 (
        echo ОШИБКА: Восстановление из резервной копии не удалось >> "%LOGFILE%"
        echo ОШИБКА: Восстановление из резервной копии не удалось
        goto :continue
    ) ELSE (
        echo Восстановление из резервной копии выполнено успешно >> "%LOGFILE%"
        echo Восстановление из резервной копии выполнено успешно
    )

    echo Шаг 4: Выполнение транзакций...
    "%FIREBIRD_BIN%\gfix.exe" -commit all "!NEW_DB!" >> "%LOGFILE%" 2>&1
    IF !ERRORLEVEL! NEQ 0 (
        echo ОШИБКА: Выполнение транзакций не удалось >> "%LOGFILE%"
        echo ОШИБКА: Выполнение транзакций не удалось
        goto :continue
    ) ELSE (
        echo Транзакции выполнены успешно >> "%LOGFILE%"
        echo Транзакции выполнены успешно
    )

    echo Шаг 5: Проведение sweep операции...
    "%FIREBIRD_BIN%\gfix.exe" -sweep "!NEW_DB!" >> "%LOGFILE%" 2>&1
    IF !ERRORLEVEL! NEQ 0 (
        echo ОШИБКА: Sweep операция не удалась >> "%LOGFILE%"
        echo ОШИБКА: Sweep операция не удалась
        goto :continue
    ) ELSE (
        echo Sweep операция выполнена успешно >> "%LOGFILE%"
        echo Sweep операция выполнена успешно
    )
    
    echo Шаг 6: Проверка базы данных...
    "%FIREBIRD_BIN%\gfix.exe" -v -full "!NEW_DB!" >> "%LOGFILE%" 2>&1
    IF !ERRORLEVEL! NEQ 0 (
        echo ОШИБКА: Проверка базы данных не удалась >> "%LOGFILE%"
        echo ОШИБКА: Проверка базы данных не удалась
        goto :continue
    ) ELSE (
        echo Проверка базы данных выполнена успешно >> "%LOGFILE%"
        echo Проверка базы данных выполнена успешно
    )
    
    echo Шаг 7: Анализ статистики базы данных...
    echo Шаг 7: Анализ статистики базы данных... >> "%LOGFILE%"
    echo Database header information: >> "%LOGFILE%"
    "%FIREBIRD_BIN%\gstat.exe" -h -user %ISC_USER% -password %ISC_PASSWORD% "!NEW_DB!" >> "%LOGFILE%" 2>&1
    echo Database table statistics: >> "%LOGFILE%"
    "%FIREBIRD_BIN%\gstat.exe" -user %ISC_USER% -password %ISC_PASSWORD% "!NEW_DB!" >> "%LOGFILE%" 2>&1
    
    echo Шаг 8: Замена исходной базы данных...
    echo Шаг 8: Замена исходной базы данных... >> "%LOGFILE%"
    
    REM Проверяем, что старая база данных не используется
    "%FIREBIRD_BIN%\gfix.exe" -shut -force 1 "!CURRENT_DB!" >nul 2>&1
    
    REM Заменяем старую базу данных новой
    move /Y "!NEW_DB!" "!CURRENT_DB!" >> "%LOGFILE%" 2>&1
    IF !ERRORLEVEL! NEQ 0 (
        echo ОШИБКА: Замена базы данных не удалась >> "%LOGFILE%"
        echo ОШИБКА: Замена базы данных не удалась
        echo Новая база данных сохранена как: !NEW_DB! >> "%LOGFILE%"
        echo Новая база данных сохранена как: !NEW_DB!
    ) ELSE (
        echo База данных успешно заменена >> "%LOGFILE%"
        echo База данных успешно заменена
    )
    
    echo База данных %%~nxF обработана
    echo =============================== >> "%LOGFILE%"
    echo База данных %%~nxF обработана >> "%LOGFILE%"
    echo =============================== >> "%LOGFILE%"
    
    :continue
    echo.
    echo. >> "%LOGFILE%"
)

IF "%FILE_FOUND%"=="0" (
    echo %PATTERN% файлы не найдены в директории %DB_PATH%
    echo %PATTERN% файлы не найдены в директории %DB_PATH% >> "%LOGFILE%"
)

echo.
echo %date% %time%: Процесс завершен >> "%LOGFILE%"
echo Процесс завершен. Смотрите лог-файл для подробностей: %LOGFILE%
pause

endlocal