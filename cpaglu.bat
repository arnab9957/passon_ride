@echo off
setlocal
cd /d "D:\Desktop\Flutter\passon_ride"
echo =======================================================
echo  Starting PassionRide Flutter Web via cpaglu...
echo  URL: http://localhost:3000
echo =======================================================
flutter run -d chrome --web-port=3000 %*
