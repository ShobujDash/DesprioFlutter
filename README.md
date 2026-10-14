# Deshprio Flutter

Android-focused Flutter app matching the existing `deshprio` web dashboard logic.

## Run

Flutter is not available in this machine's PATH right now. After installing Flutter or fixing PATH:

```powershell
cd C:\Users\Hp\Desktop\antar\deshprio_flutter
flutter create --platforms=android .
flutter pub get
flutter run
```

If the backend runs on the same computer, set the app API URL to:

```text
http://10.0.2.2:5000/api
```

For a real Android phone on the same Wi-Fi, use your computer LAN IP:

```text
http://YOUR_PC_IP:5000/api
```

## Rongta RPP02C Printing

1. Pair the Rongta printer from Android Bluetooth settings first.
2. Open this app, go to Printer, select the paired Rongta device.
3. Print from retail or wholesale sale screens.

Bangla receipts are rendered to a bitmap on Android and then sent with ESC/POS raster commands, so the printer does not need built-in Bangla font support.
