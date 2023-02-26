
del build.log
@echo %CD%
pause
"C:\Program Files (x86)\Microsoft Visual Studio 10.0\VC\vcvarsall.bat" x64
devenv /Build Release Premake4.sln
pause
