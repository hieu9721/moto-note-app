---
title: Privacy Policy — MotoNote
permalink: /privacy-policy-en
---

# Privacy Policy — MotoNote

*Last updated: 2026-09-02*

[Phiên bản tiếng Việt]({{ site.baseurl }}/privacy-policy)

## One-sentence summary

MotoNote has no server, no MotoNote account, and collects nothing about you
— all of your data lives on your own device, and the optional backup (only
if you turn it on) lives in your own Google Drive, not the developer's.

## 1. No account, no server

MotoNote does not require creating an account. There is no app-specific
sign-up email, no password, and no MotoNote server that stores your data.
The developer receives none of your data — there is no channel for it to
reach the developer at all.

## 2. Your data lives in a single file, on your own device

Everything you record in MotoNote — vehicles (name, plate, brand, model
year), maintenance items, service history (including cost and shop name if
you enter them), odometer readings, notes, and settings — is stored in one
JSON file on your phone's internal storage. The app reads and writes this
file directly as you use it; no screen waits on a network connection to
show your own data.

## 3. Two incidental pieces of information this file also holds

Beyond your maintenance data, that same file also stores two things you
might not expect — neither ever leaves your device or your own Google
account:

- **Your phone's model name** (e.g. "Redmi Note 12") — used only to label a
  backup, so you can tell two devices apart if you ever change phones.
- **The email address of the Google account you sign in with** (only if you
  turn on Google Drive backup) — used only so the Settings screen can show
  which account your backups are going to.

## 4. Google Drive backup — off by default

Google Drive backup is **off by default**. If you turn it on yourself, a
copy of the data file (section 2) is written to a private area of your own
Google Drive — the `appDataFolder` space, which only MotoNote can see.
MotoNote does not read or touch any other file in your Drive, and you
cannot see this backup file yourself in the regular Drive interface either
— that is a deliberate trade-off so MotoNote can request the narrowest
possible scope (`drive.appdata`, not the broader `drive` or
`drive.readonly` scopes).

Three things are always true about signing into Google inside MotoNote:

1. There is no MotoNote account.
2. You sign into Google only if and when you turn backup on.
3. The app can see exactly one file — its own — and nothing else in your
   Drive.

## 5. Photos are never backed up to Drive

If you attach a receipt photo to a service-history entry, or a photo for
your vehicle, that photo is stored only on your phone's internal storage —
the file path is recorded in the data file, but the photo itself is never
uploaded to Google Drive. "⚠ Receipt photos are not restored" is the
warning line you will see on the restore screen, precisely for this reason.

## 6. Reminder notifications are generated on your device

MotoNote reminds you when maintenance is due using local notifications that
your own phone schedules and displays. There is no push service in between,
and no server anywhere knows when you were reminded or what the reminder
said.

## 7. No behavioral analytics, no advertising, no data sold

MotoNote integrates no analytics tool and no advertising SDK of any kind.
None of your data is sold or shared with any third party — there simply is
no channel for that data to leave your device, other than your own Google
Drive when you have chosen to turn backup on (section 4).

## 8. Deleting all of your data

In Settings → Danger Zone, the "Delete all data" button erases the entire
data file on your device, every receipt photo, every scheduled
notification, and signs your Google account out of the app. Your Google
Drive backup is **only deleted if you actively tick the separate checkbox**
"Also delete the backup on Google Drive" inside the confirmation dialog —
that checkbox is **unchecked by default**, because the Drive copy is the
only place you could recover from if you deleted your local data by
mistake.

## 9. Contact

Questions about this policy or your data? Contact:
nguyenvantrungjieu@gmail.com

## 10. Changes to this policy

If MotoNote ever changes how it handles data, this policy will be updated
before that change takes effect, and the "Last updated" date at the top of
this page will reflect it. Storing data only on-device and in your own
Google Drive is a constraint on what the app is allowed to do, not the
other way around — if a future change would make that statement false,
that change is the wrong one to make.

---

*MotoNote — a maintenance-note and reminder app for motorcycles · No
account · Stored on your device · Optional Google Drive backup.*
