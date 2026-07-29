# User Profile

## V1 implemented now

The first profile slice is local-only and optional. It does not add backend
auth, social auth SDKs, passwords, email codes, SMS codes, or cross-device sync.

Flow:

1. Home shows a banner while no local profile exists.
2. User taps the banner and opens the profile/login screen.
3. User taps "Criar conta".
4. User types a display name.
5. The app saves that display name locally and returns to Home.
6. Home hides the banner after the local profile exists.

The local profile is stored on this device under `economia.userProfile`. For
now it is only a personalization and migration foothold, not proof of identity.

## Full future account flow

The intended account system remains:

1. First app open shows a Home banner prompting login.
2. Login stays optional and should not block most app functionality.
3. Tapping the banner opens a login screen with:
   - existing account login
   - create account
   - Google login/create account
   - Meta/Facebook login/create account

Create account:

1. User types their email.
2. User types the code sent by email.
3. If the email code is correct, user types their phone number.
4. A code is sent via SMS.
5. User types the SMS code to confirm the phone number.
6. User types a password twice.
7. User types their display name and finishes account creation.

Manual login:

1. User types their name or cellphone in the same text field.
2. User types their password.

Social login:

1. User taps a platform button such as Google or Facebook.
2. After account confirmation/linking, user types their display name.

Future profile settings:

- customize profile photo
- change password
- enable two-factor authentication

## Implementation notes

V1 deliberately keeps the future buttons visible but non-authenticating. They
can show an "em breve" message until the app has a real account backend and
provider configuration.
