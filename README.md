# fitvault

a private health tracker for iphone. log workouts, meals, sleep, and body weight. everything stays on your phone, encrypted. no accounts, no servers.

## privacy

- all data is saved in an sqlite database encrypted with sqlcipher (256-bit aes).
- the database key is random, made on first launch, and kept in the ios keychain. it never leaves the device and is never in the code.
- the app is locked with a 4 to 6 digit pin or face id / touch id. the pin is never saved, only a salted pbkdf2 hash of it.
- after 5 wrong pins, entry is blocked for 30 seconds, even if the app is closed and opened again.

## what works so far

- encrypted storage, with a security screen in settings that shows the checks passing
- app lock: create a pin on first launch, unlock with the pin or face id, auto-lock after 2 minutes in the background

## build and run

built with xcode 27. runs on ios 17 or later.

1. open `fitvault.xcodeproj` in xcode.
2. pick an iphone simulator and press run.

run the tests from the terminal:

```
xcodebuild test -project fitvault.xcodeproj -scheme fitvault -destination 'platform=iOS Simulator,name=iPhone 17'
```

## libraries

- [sqlcipher](https://github.com/sqlcipher/SQLCipher.swift) for the encrypted database (bsd-style license). everything else uses apple frameworks.
