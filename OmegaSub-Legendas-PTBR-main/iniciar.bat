@echo off
cd /d "%~dp0"
if not exist .venv\Scripts\python.exe (
  py -3 -m venv .venv || goto :error
)
.venv\Scripts\python.exe -m pip install -r requirements.txt || goto :error
.venv\Scripts\python.exe main.py
pause
exit /b 0
:error
echo Falha ao preparar o ambiente. Instale Python 3.11 ou 3.12.
pause
exit /b 1
