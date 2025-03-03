@echo off
chcp 866 > NUL
setlocal EnableDelayedExpansion

REM ===================================================================
REM C�ਯ� ���㦨����� Firebird ��
REM ===================================================================

REM ��ࠬ���� �� 㬮�砭��
SET ISC_USER=SYSDBA
SET ISC_PASSWORD=masterkey
SET DB_PATH=%CD%
SET PATTERN=*.ecodb
SET FIREBIRD_BIN=C:\PROGRA~2\Integral\FireBird\bin
SET BACKUP_DIR=%CD%\backup
SET LOG_DIR=%CD%\log
SET LOGFILE=%LOG_DIR%\log_%date:~6,4%%date:~3,2%%date:~0,2%.log

REM ��ࠡ�⪠ ��ࠬ��஢ ��������� ��ப�
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
echo ��ਯ� ���㦨����� ��� ������ Firebird
echo.
echo �ᯮ�짮�����: %~nx0 [���������]
echo.
echo ��ࠬ����:
echo   -u USERNAME       ��� ���짮��⥫� Firebird (�� 㬮�砭��: SYSDBA)
echo   -p PASSWORD       ��஫� ���짮��⥫� Firebird (�� 㬮�砭��: masterkey)
echo   -d PATH           ���� � ��४�ਨ � ������ ������ (�� 㬮�砭��: ⥪��� ��४���)
echo   -f PATTERN        ������ 䠩��� ��� ��ࠡ�⪨ (�� 㬮�砭��: *.ecodb)
echo   -b PATH           ��४��� ��� १�ࢭ�� ����� (�� 㬮�砭��: .\backup)
echo   -l PATH           ��४��� ��� ����� (�� 㬮�砭��: .\log)
echo   -h, --help        �������� ��� �ࠢ��
echo.
echo �ਬ���: 
echo   %~nx0             # ��ࠡ���� �� .ecodb 䠩�� � ⥪�饩 ��४�ਨ
echo   %~nx0 -d C:\Data  # ��ࠡ���� �� .ecodb 䠩�� � ��४�ਨ C:\Data
echo   %~nx0 -f db1.ecodb  # ��ࠡ���� ⮫쪮 䠩� db1.ecodb
echo.
exit /b 0

:param_done

IF NOT EXIST "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"
IF NOT EXIST "%LOG_DIR%" mkdir "%LOG_DIR%"

echo %date% %time%: ��砫� ����� > "%LOGFILE%"
echo ��४��� ���᪠ ��� ������: %DB_PATH% >> "%LOGFILE%"

REM �஢�ઠ ������ �⨫�� Firebird
IF NOT EXIST "%FIREBIRD_BIN%\gfix.exe" (
    echo �訡��: �⨫��� Firebird �� ������� � %FIREBIRD_BIN%
    echo ��ਯ� �।��������, �� ���� Firebird ��� ����� ������ �뫠 ��⠭������ � ��४�ਨ �� 㬮�砭��.
    echo �᫨ �� �� ⠪, ᫥��� �������� ���� � ��४�ਨ � �ᯮ��塞묨 䠩����, ��।���஢�� ��६����� FIREBIRD_BIN � �⮬ �ਯ�.
    echo.
    echo �訡��: �⨫��� Firebird �� ������� � %FIREBIRD_BIN% >> "%LOGFILE%"
    pause
    exit /b 1
)

echo ���� %PATTERN% 䠩��� � ��४�ਨ %DB_PATH%...
echo ���� %PATTERN% 䠩��� � ��४�ਨ %DB_PATH%... >> "%LOGFILE%"

SET FILE_FOUND=0
FOR %%F IN ("%DB_PATH%\%PATTERN%") DO (
    SET FILE_FOUND=1
    SET CURRENT_DB=%%~fF
    SET DB_NAME=%%~nF
    SET DB_DIR=%%~dpF
    
    echo ������� ���� ������: %%~nxF
    echo ������� ���� ������: %%~nxF >> "%LOGFILE%"
    
    REM �஢�ઠ, �� �ᯮ������ �� ���� ������ � ����� ������
    echo �஢�ઠ �ᯮ�짮����� ���� ������...
    echo �஢�ઠ �ᯮ�짮����� ���� ������... >> "%LOGFILE%"
    
    "%FIREBIRD_BIN%\gfix.exe" -shut -tran 1 "!CURRENT_DB!" >nul 2>&1
    if !ERRORLEVEL! NEQ 0 (
        echo ������: ���� ������ !DB_NAME! �ᯮ������ ��㣨�� ���짮��⥫ﬨ � �� ����� ���� ��ࠡ�⠭�.
        echo ������: ���� ������ !DB_NAME! �ᯮ������ ��㣨�� ���짮��⥫ﬨ � �� ����� ���� ��ࠡ�⠭�. >> "%LOGFILE%"
        goto :continue
    )
    
    "%FIREBIRD_BIN%\gfix.exe" -online "!CURRENT_DB!" >nul 2>&1
    
    REM ������ ����� 䠩��� ��� ���� � ����⠭�������� ����
    SET BACKUP_FILE=%BACKUP_DIR%\%%~nF_%date:~6,4%%date:~3,2%%date:~0,2%.backup
    SET NEW_DB=!DB_DIR!%%~nF_new.ecodb
    
    echo ��ࠡ�⪠ ���� ������: %%~nxF
    echo ��ࠡ�⪠ ���� ������: %%~nxF >> "%LOGFILE%"
    
    echo ��� 1: ����⠭������� � ६��� ���� ������...
    "%FIREBIRD_BIN%\gfix.exe" -mend "!CURRENT_DB!" >> "%LOGFILE%" 2>&1
    IF !ERRORLEVEL! NEQ 0 (
        echo ������: ����⠭������� ���� ������ �� 㤠���� >> "%LOGFILE%"
        echo ������: ����⠭������� ���� ������ �� 㤠����
        goto :continue
    ) ELSE (
        echo ����⠭������� ���� ������ �믮����� �ᯥ譮 >> "%LOGFILE%"
        echo ����⠭������� ���� ������ �믮����� �ᯥ譮
    )
    
    echo ��� 2: �������� १�ࢭ�� �����...
    "%FIREBIRD_BIN%\gbak.exe" -b -v -ig "!CURRENT_DB!" "!BACKUP_FILE!" >> "%LOGFILE%" 2>&1
    IF !ERRORLEVEL! NEQ 0 (
        echo ������: �������� १�ࢭ�� ����� �� 㤠���� >> "%LOGFILE%"
        echo ������: �������� १�ࢭ�� ����� �� 㤠����
        goto :continue
    ) ELSE (
        echo ����ࢭ�� ����� ᮧ���� �ᯥ譮 >> "%LOGFILE%"
        echo ����ࢭ�� ����� ᮧ���� �ᯥ譮
    )

    echo ��� 3: ����⠭������� �� १�ࢭ�� �����...
    "%FIREBIRD_BIN%\gbak.exe" -c -v "!BACKUP_FILE!" "!NEW_DB!" >> "%LOGFILE%" 2>&1
    IF !ERRORLEVEL! NEQ 0 (
        echo ������: ����⠭������� �� १�ࢭ�� ����� �� 㤠���� >> "%LOGFILE%"
        echo ������: ����⠭������� �� १�ࢭ�� ����� �� 㤠����
        goto :continue
    ) ELSE (
        echo ����⠭������� �� १�ࢭ�� ����� �믮����� �ᯥ譮 >> "%LOGFILE%"
        echo ����⠭������� �� १�ࢭ�� ����� �믮����� �ᯥ譮
    )

    echo ��� 4: �믮������ �࠭���権...
    "%FIREBIRD_BIN%\gfix.exe" -commit all "!NEW_DB!" >> "%LOGFILE%" 2>&1
    IF !ERRORLEVEL! NEQ 0 (
        echo ������: �믮������ �࠭���権 �� 㤠���� >> "%LOGFILE%"
        echo ������: �믮������ �࠭���権 �� 㤠����
        goto :continue
    ) ELSE (
        echo �࠭���樨 �믮����� �ᯥ譮 >> "%LOGFILE%"
        echo �࠭���樨 �믮����� �ᯥ譮
    )

    echo ��� 5: �஢������ sweep ����樨...
    "%FIREBIRD_BIN%\gfix.exe" -sweep "!NEW_DB!" >> "%LOGFILE%" 2>&1
    IF !ERRORLEVEL! NEQ 0 (
        echo ������: Sweep ������ �� 㤠���� >> "%LOGFILE%"
        echo ������: Sweep ������ �� 㤠����
        goto :continue
    ) ELSE (
        echo Sweep ������ �믮����� �ᯥ譮 >> "%LOGFILE%"
        echo Sweep ������ �믮����� �ᯥ譮
    )
    
    echo ��� 6: �஢�ઠ ���� ������...
    "%FIREBIRD_BIN%\gfix.exe" -v -full "!NEW_DB!" >> "%LOGFILE%" 2>&1
    IF !ERRORLEVEL! NEQ 0 (
        echo ������: �஢�ઠ ���� ������ �� 㤠���� >> "%LOGFILE%"
        echo ������: �஢�ઠ ���� ������ �� 㤠����
        goto :continue
    ) ELSE (
        echo �஢�ઠ ���� ������ �믮����� �ᯥ譮 >> "%LOGFILE%"
        echo �஢�ઠ ���� ������ �믮����� �ᯥ譮
    )
    
    echo ��� 7: ������ ����⨪� ���� ������...
    echo ��� 7: ������ ����⨪� ���� ������... >> "%LOGFILE%"
    echo Database header information: >> "%LOGFILE%"
    "%FIREBIRD_BIN%\gstat.exe" -h -user %ISC_USER% -password %ISC_PASSWORD% "!NEW_DB!" >> "%LOGFILE%" 2>&1
    echo Database table statistics: >> "%LOGFILE%"
    "%FIREBIRD_BIN%\gstat.exe" -user %ISC_USER% -password %ISC_PASSWORD% "!NEW_DB!" >> "%LOGFILE%" 2>&1
    
    echo ��� 8: ������ ��室��� ���� ������...
    echo ��� 8: ������ ��室��� ���� ������... >> "%LOGFILE%"
    
    REM �஢��塞, �� ���� ���� ������ �� �ᯮ������
    "%FIREBIRD_BIN%\gfix.exe" -shut -force 1 "!CURRENT_DB!" >nul 2>&1
    
    REM �����塞 ����� ���� ������ �����
    move /Y "!NEW_DB!" "!CURRENT_DB!" >> "%LOGFILE%" 2>&1
    IF !ERRORLEVEL! NEQ 0 (
        echo ������: ������ ���� ������ �� 㤠���� >> "%LOGFILE%"
        echo ������: ������ ���� ������ �� 㤠����
        echo ����� ���� ������ ��࠭��� ���: !NEW_DB! >> "%LOGFILE%"
        echo ����� ���� ������ ��࠭��� ���: !NEW_DB!
    ) ELSE (
        echo ���� ������ �ᯥ譮 �������� >> "%LOGFILE%"
        echo ���� ������ �ᯥ譮 ��������
    )
    
    echo ���� ������ %%~nxF ��ࠡ�⠭�
    echo =============================== >> "%LOGFILE%"
    echo ���� ������ %%~nxF ��ࠡ�⠭� >> "%LOGFILE%"
    echo =============================== >> "%LOGFILE%"
    
    :continue
    echo.
    echo. >> "%LOGFILE%"
)

IF "%FILE_FOUND%"=="0" (
    echo %PATTERN% 䠩�� �� ������� � ��४�ਨ %DB_PATH%
    echo %PATTERN% 䠩�� �� ������� � ��४�ਨ %DB_PATH% >> "%LOGFILE%"
)

echo.
echo %date% %time%: ����� �����襭 >> "%LOGFILE%"
echo ����� �����襭. ������ ���-䠩� ��� ���஡���⥩: %LOGFILE%
pause

endlocal