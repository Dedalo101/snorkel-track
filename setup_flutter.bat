@echo off
echo Setting up Flutter environment...
set PATH=%PATH%;C:\flutter\bin
echo Flutter added to PATH for this session.
echo.
echo Available commands:
echo   flutter devices       - List connected devices
echo   flutter run           - Run on default device  
echo   flutter run -d windows- Run on Windows (needs Visual Studio)
echo   flutter run -d edge   - Run in web browser
echo   flutter test          - Run tests
echo   flutter doctor        - Check Flutter setup
echo.
echo Your devices:
flutter devices
echo.
echo To test the Mark Spot fix, run:
echo   flutter run lib/main_debug.dart
echo.
pause