# fitvault product backlog

the full list of user stories for fitvault, in priority order within each sprint. each story is also tracked as an issue on the project board.

- **priority:** high means the app isn't usable without it, medium adds real value but can wait a sprint, low is nice to have.
- **points:** relative size on a 1, 3, 5 scale. sprint 1 finished 11 points.

---

## us01: encrypted storage

- priority: high
- points: 5
- sprint: sprint 1

as a user, i want my health data stored encrypted on my phone so that no one can read it if they get my device.

acceptance criteria:
- [ ] the database file can't be opened with a normal sqlite viewer
- [ ] no encryption key is hardcoded in the code or the repo. the key lives in the keychain
- [ ] saved data still loads after the app is closed and reopened

---

## us02: app lock with pin or face id

- priority: high
- points: 3
- sprint: sprint 1

as a user, i want to lock the app with a pin or face id so that people using my phone can't open my logs.

acceptance criteria:
- [ ] the app asks for the pin or face id on every launch and after 2 minutes in the background
- [ ] after 5 wrong pins, entry is blocked for 30 seconds
- [ ] the pin is stored as a salted hash, never as plain text

---

## us03: log a workout

- priority: high
- points: 3
- sprint: sprint 1

as a lifter, i want to log a workout with exercises, sets, reps, and weight so that i can track what i did.

acceptance criteria:
- [ ] a workout with 5 exercises can be logged in under 2 minutes
- [ ] each set saves its reps and weight
- [ ] workouts show in history newest first and can be edited or deleted

---

## us04: log meals

- priority: high
- points: 3
- sprint: sprint 2

as a user, i want to log my meals with calories and protein so that i know what i'm eating each day.

acceptance criteria:
- [ ] calories and protein are required. carbs and fat are optional
- [ ] daily totals update right after saving
- [ ] blank or negative calories are rejected with a clear message

---

## us05: food search

- priority: high
- points: 5 (to be confirmed by the usda api spike)
- sprint: sprint 2

as a user, i want to search for a food and pull its nutrition info so that i don't have to type the numbers in myself.

acceptance criteria:
- [ ] results come back within 3 seconds on a normal connection
- [ ] picking a result fills in calories and protein for the chosen serving
- [ ] if offline or the api fails, the app shows a message and still allows manual entry
- [ ] only the search term leaves the phone
- [ ] the api key is not committed to the public repo

---

## us06: daily goals

- priority: high
- points: 1
- sprint: sprint 2

as a user, i want to set daily goals for calories, protein, and sleep so that the app can tell me if i'm on track.

acceptance criteria:
- [ ] goals can be set and changed
- [ ] goals stay saved after restarting the app
- [ ] goals only accept positive numbers

---

## us07: home dashboard

- priority: high
- points: 5
- sprint: sprint 3

as a user, i want a home dashboard showing today's numbers compared to my goals so that i can check my day at a glance.

acceptance criteria:
- [ ] calories and protein show as current / goal with a progress bar
- [ ] shows whether a workout was logged today
- [ ] numbers update within 1 second of a new log

---

## us08: workout templates

- priority: medium
- points: 3
- sprint: sprint 2

as a lifter, i want to save workout templates for my weekly split so that i can start a session without rebuilding it.

acceptance criteria:
- [ ] templates can be created, renamed, and deleted
- [ ] starting from a template fills in all its exercises
- [ ] at least 7 templates can be saved

---

## us09: sleep log

- priority: medium
- points: 1
- sprint: sprint 3

as a user, i want to log my sleep and rate how well i slept so that i can see how sleep affects my training.

acceptance criteria:
- [ ] saves hours (0 to 24) and a rating from 1 to 5
- [ ] only one sleep entry per date. adding a second asks to replace the first

---

## us10: body weight log

- priority: medium
- points: 1
- sprint: sprint 3

as a user, i want to log my body weight so that i can see if i'm moving toward my goal.

acceptance criteria:
- [ ] saves weight with a date
- [ ] switching between lbs and kg converts all values correctly
- [ ] shows the change from the last entry

---

## us11: progress charts

- priority: medium
- points: 5
- sprint: sprint 4

as a user, i want charts of my calories, protein, sleep, and weight so that i can see trends over time.

acceptance criteria:
- [ ] charts can show the last 7 days or the last 30 days
- [ ] days with no data show as gaps, not zeros
- [ ] charts load in under 2 seconds with 90 days of data

---

## us12: personalized insights

- priority: medium
- points: 5
- sprint: sprint 4

as a user, i want personalized insights from my logs so that i know what to change.

acceptance criteria:
- [ ] at least 4 insight rules work, and they run on the phone
- [ ] insights only appear once there are 7 or more days of data
- [ ] every insight is worded as a suggestion, not medical advice

---

## us13: export or delete all data

- priority: medium
- points: 3
- sprint: sprint 3

as a user, i want to export or delete all my data so that i stay in control of it.

acceptance criteria:
- [ ] export creates a csv file for each log type
- [ ] delete-all asks for the pin first, then a final confirm
- [ ] after deleting, the database is empty and the app goes back to first-time setup

---

## us14: reminders

- priority: low
- points: 3
- sprint: sprint 4 (stretch goal, first thing cut if behind)

as a user, i want reminders to log my meals and sleep so that i don't forget.

acceptance criteria:
- [ ] each reminder can be turned on or off and given a time
- [ ] notifications never show health numbers on the lock screen
- [ ] reminders still work after the phone restarts
