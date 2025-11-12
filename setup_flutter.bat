@echo off
echo Setting up Flutter environment...
set PATH=%PATH%;C:\flutter\bin
echo Flutter added to PATH for this session.
echo.
flutter doctor
echo.
echo Flutter is ready! You can now run:
echo   flutter run
echo   flutter test
echo   flutter build
pause