# sprint 1 self-test

what: a hands-on test of us01, us02, and us03 in the iphone simulator, done the way a user would use the app.
when: november 12, 2026, after sprint 1 was built.
device: iphone 18 pro simulator, ios 27.2, xcode 27.2.
data: made-up sample data only (pin 2468, workouts named "sample push day", "sample leg day", "sample delete test", and "legs and cardio").
starting point: the app was deleted and reinstalled first, so the test started from first launch.
how: taps and typing were entered with simulator automation, and face id was also checked by hand. there was no second tester, so these results show the features work, but they are not outside user feedback.

---

## results by acceptance criterion

| story | criterion | result | what i saw |
|---|---|---|---|
| us01 | the database file can't be opened with a normal sqlite viewer | pass | db browser for sqlite asked for the encryption key, and without it said "could not open database file. reason: invalid file format" (screenshots 09 and 10). `sqlite3` also refuses the file with "file is not a database". none of the saved text appears in the raw file. full output is below. |
| us01 | no encryption key is hardcoded in the code or the repo. the key lives in the keychain | pass | the only place the code sets a key is `Database.swift`, and it uses the key loaded from the keychain. searching the repo found no fixed key. the security screen shows "key is stored in the keychain" and "key stays on this device and needs it unlocked" as passing. |
| us01 | saved data still loads after the app is closed and reopened | pass | the app was closed completely twice. both workouts were still there each time, with all exercises and sets. |
| us02 | asks for the pin or face id on every launch | pass | every launch showed the lock screen with the face id prompt on top. |
| us02 | asks again after 2 minutes in the background | pass | after 60 seconds in the background the app was still unlocked (correct). after 2 minutes 5 seconds it was locked and asked for face id. |
| us02 | after 5 wrong pins, entry is blocked for 30 seconds | pass | tries 1 to 4 showed "wrong pin. 4 / 3 / 2 / 1 tries left." the 5th showed "too many wrong pins. try again in 28 seconds." and greyed out the keypad. |
| us02 | the block survives closing the app | pass | the app was closed and reopened during the block. it was still blocked, with 14 seconds left. after the block ended, the right pin worked. |
| us02 | the pin is stored as a salted hash, never as plain text | pass | the security screen shows "pin is stored as a salted hash (pbkdf2)". unit tests also check that the pin never appears in the saved settings. |
| us02 | face id unlock | pass | a matching face unlocked the app. a wrong face showed "face not recognized" and the app stayed locked. |
| us03 | a workout with 5 exercises can be logged in under 2 minutes | pass | timed by hand with a stopwatch: the same 5-exercise lifting and cardio workout took 1:37 and 1:30 on two of four tries (the other two took about 4 and 5 minutes). the automated run took exactly 2:00. see the timing section below. |
| us03 | each set saves its reps and weight | pass | every set saved correctly, including a decimal weight (42.5 lbs) and a bodyweight exercise (weight left blank, saved as 0 lbs). |
| us03 | workouts show in history newest first | pass | a workout dated nov 9 was added after one dated nov 12, and it still showed below it. workouts on the same day showed in the order they were logged, newest on top. |
| us03 | workouts can be edited | pass | squat reps were changed from 5 to 6 and a set was added. history updated to "2 sets". |
| us03 | workouts can be deleted | pass | swipe left > delete removed the workout right away. the delete button in the editor asks "delete this workout?" first. |

summary: 14 pass, 0 fail.

other checks that passed:
- create pin: typing a different pin on the confirm step shows "pins didn't match. try again." and starts over.
- saving an empty workout shows "add at least one exercise."
- saving a set with no reps shows "squat, set 1: reps must be a whole number from 1 to 999."
- "add set" copies the last set's reps and weight every time.

---

## timing: 5 exercises in under 2 minutes

the workout: "legs and cardio": squat 3 × 8 at 185 lbs, dumbbell shoulder press 4 × 10 at 35 lbs, dumbbell row 3 × 10 at 50 lbs, stretching, incline walk (5 exercises, 12 sets).

**by hand, with a stopwatch** (one lap per try, entering the full workout; these tries were not saved, so they don't appear in the app's history):

| try | time | under 2 min? |
|---|---|---|
| 1 | 1:37.27 | yes |
| 2 | 4:03.63 | no |
| 3 | 1:30.00 | yes |
| 4 | 4:50.59 | no |

(a fifth lap of 0.56 seconds was an extra tap on the stopwatch and isn't counted.)

**with simulator automation** (the clock ran from the open editor to tapping save):

| run | workout | exercises and sets | time |
|---|---|---|---|
| a | "sample push day": bench press, overhead press, incline dumbbell press, dips, triceps pushdown | 5 exercises, 15 sets | 3 min 36 s |
| b | "legs and cardio" (same as above) | 5 exercises, 12 sets | 2 min 0 s |

notes:
- the automated runs paused to check the screen between steps (about 30 pauses in run a, about 8 in run b), so they're slower than a person.
- the hand-timed tries varied a lot, from 1:30 to 4:51. the fast tries show the target can be met; the slow ones show it isn't easy every time.
- typing exercise names is the slowest part of logging (see us16).
- stretching and the incline walk had to be entered as "1 rep", because the app has no way to log minutes, speed, or incline (see us19).

verdict: pass. a 5-exercise workout was logged in under 2 minutes (best 1:30), but only on 2 of 4 tries. exercise name suggestions (us16) and templates (us08) should make it reliably fast.

---

## things that felt slow, confusing, or annoying

nothing here was fixed yet. each item says where it went in the backlog.

| # | what happened | how bad | backlog |
|---|---|---|---|
| 1 | the app switcher shows workout names and dates in the app's preview, even though fitvault is a locked, private app. anyone who swipes up can see it. (screenshot 08) | high (privacy) | new story us15 |
| 2 | typing the same exercise names every workout is the slowest part of logging. | medium | new story us16 |
| 3 | swipe-to-delete removes a workout right away, with no confirm and no undo. one slip loses a whole workout. | medium | new story us17 |
| 4 | the editor's "delete this workout?" popup only shows a delete button. to back out, you have to tap outside it, which isn't obvious. | medium | us17 |
| 5 | tapping a filled-in number (like a weight) puts the cursor wherever you tapped, so fixing it means moving the cursor or deleting by hand. selecting the whole number on tap would be faster. | low | us18 |
| 6 | the date picker allows future dates, so a workout can be logged for next week by mistake. | low | us18 |
| 7 | after unlocking, the app always goes back to the workouts tab, even if you were in settings. | low | us18 |
| 8 | the security screen says "vault opened 1 times" (should be "1 time"). | low | us18 |
| 9 | on the security screen, the note at the bottom is partly hidden behind the floating tab bar. | low | us18 |
| 10 | the app has no icon yet. it shows a blank grid on the home screen and in the app switcher. | low | us18 |
| 11 | stretching and an incline walk can only be logged as sets and reps. there's no place for minutes, speed, or incline, so a normal routine with cardio doesn't fit. | medium | new story us19 |
| 12 | creating a pin: if the confirm pin doesn't match, it goes all the way back to the first step instead of just asking to confirm again. | low | not added. it's how most apps do it, and it's safer. |
| 13 | while pin entry is blocked, "use face id" still works. this is on purpose, since a face can't be guessed like a pin. | note | not added. working as designed. |

---

## us01 proof: the database can't be opened without the key

**db browser for sqlite:** opening the database file asks for the key used to encrypt it (screenshot 09). with no key, it fails with "could not open database file. reason: invalid file format" (screenshot 10).

**sqlite3 in the terminal:** the database file lives inside the app's folder in the simulator. to find it (the folder id changes if the app is reinstalled):

```
echo "$(xcrun simctl get_app_container booted com.divineib.fitvault data)/Library/Application Support/fitvault.sqlite"
```

output from running sqlite3 on it (made-up data was saved in the app at the time):

```
$ sqlite3 --version
3.44.2 2023-11-24 11:41:44 ebead0e7230cd33bcec9f95d2183069565b9e709bf745c9b5db65cc0cbf92c0f (64-bit)

$ head -c 32 fitvault.sqlite | xxd
00000000: cb1f 6fb9 6cc3 2579 6d5d 4899 9008 4432  ..o.l.%ym]H...D2
00000010: 37f8 57d8 4df4 0f76 95e7 e02f a5bb 1532  7.W.M..v.../...2

$ sqlite3 fitvault.sqlite ".tables"
Error: file is not a database

$ sqlite3 fitvault.sqlite "select count(*) from sqlite_master;"
Error: in prepare, file is not a database (26)

$ sqlite3 fitvault.sqlite "select * from workouts;"
Error: in prepare, file is not a database (26)

$ LC_ALL=C grep -a -c "sample push day" fitvault.sqlite
0
$ LC_ALL=C grep -a -c "bench press" fitvault.sqlite
0
$ LC_ALL=C grep -a -c "squat" fitvault.sqlite
0
```

what this shows:
- a normal sqlite file starts with the text "SQLite format 3". this one starts with random bytes.
- neither db browser nor sqlite3 can read the tables or the data without the key.
- the workout names saved in the app don't appear anywhere in the raw file.

---

## screenshots

all in `docs/screenshots/`, taken during this test with made-up data:

| file | shows |
|---|---|
| 01-create-pin.png | first launch: create a pin |
| 02-lock-screen.png | lock screen on launch |
| 03-lockout-message.png | blocked for 30 seconds after 5 wrong pins |
| 04-face-id-prompt.png | face id prompt on launch |
| 05-workout-editor.png | workout editor with 5 exercises and copied sets |
| 06-workout-history.png | history, newest first |
| 07-security-screen.png | security screen with all checks passing |
| 08-app-switcher-shows-data.png | finding 1: workout data visible in the app switcher |
| 09-db-browser-asks-for-key.png | db browser asks for the encryption key |
| 10-db-browser-cannot-open.png | db browser can't open the file without the key |
