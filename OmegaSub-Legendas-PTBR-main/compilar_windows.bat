@echo off
cd /d "%~dp0"
if not exist .venv\Scripts\python.exe (
  py -3 -m venv .venv || goto :error
)
.venv\Scripts\python.exe -m pip install -r requirements.txt || goto :error
.venv\Scripts\python.exe -m PyInstaller --noconfirm --clean --onefile --windowed --name OmegaSub --icon assets/omegasub.ico --add-data "assets/omegasub.png;assets" --collect-all subliminal --collect-all babelfish --collect-all guessit --collect-all enzyme main.py || goto :error
echo Executavel criado em dist\OmegaSub.exe
pause
exit /b 0
:error
echo Erro na compilacao.
pause
exit /b 1
