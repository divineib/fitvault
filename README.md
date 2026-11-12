# fitvault

a private health tracker for iphone. log workouts, meals, sleep, and body weight. everything stays on your phone, encrypted. no accounts, no servers.

## privacy

- all data is saved in an sqlite database encrypted with sqlcipher (256-bit aes).
- the database key is random, made on first launch, and kept in the ios keychain. it never leaves the device and is never in the code.

## what works so far

- encrypted storage, with a security screen in settings that shows the checks passing

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
