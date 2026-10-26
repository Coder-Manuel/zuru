# Device checks

On-device checks for the QA fixes (BUG-002 payment sheet, BUG-005 audio
routing, BUG-006 screen-on). They need a running emulator or simulator and,
for some steps, someone at it (the Bluetooth permission dialog, the
simulator's on-screen keyboard). See the note at the top of each file.

The files end in `_check.dart`, not `_test.dart`, so `flutter test .` and
`./test.sh` skip them: Flutter can't run device tests and unit tests in one
invocation. Run each one by path:

```bash
fvm flutter test integration_test/payment_sheet_keyboard_check.dart -d <device-id>
```

The test runner uninstalls the app when it finishes, which signs the device
out.
