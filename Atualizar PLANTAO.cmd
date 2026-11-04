@echo off
rem Atualiza (ou instala) a extensao PLANTAO em C:\PLANTAO\extensao. Com "agendar", tambem cria
rem a tarefa do Windows que atualiza sozinha ao entrar no usuario.
if /i "%~1"=="agendar" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Atualizar-PLANTAO.ps1" -Agendar
) else (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Atualizar-PLANTAO.ps1"
)
pause
