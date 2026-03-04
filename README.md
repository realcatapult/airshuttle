# Airshuttle

Airshuttle is a badminton ranking and match-tracking app inspired by SwimCloud and UTR-style workflows.

## Implemented Features

- User authentication (login + account registration)
- Player registration with school and team association
- Profile customization (avatar icon, avatar color, optional profile image + banner URL)
- Settings page (profile picture, banner, light/dark theme, logout)
- UTR-style dynamic badminton rating (`AirRating`) with reliability score
- Global / school / team leaderboards
- Head-to-head win probability forecast
- Match upload flow for singles and doubles
- Match review queue for admins (approve/reject pending uploads)
- Player profile pages with previous matches and stats
- Team pages with rosters and team average rating
- Player/team/school search (Discover page)
- Seeded veteran demo players with multi-year match history

## Demo Credentials

- Default player login: `noor@airshuttle.app` / `pass123`
- Admin: `admin@airshuttle.app` / `admin123`
- Sample players: `priya@airshuttle.app`, `hannah@airshuttle.app`, `lucas@airshuttle.app`, `diego@airshuttle.app`, `olivia@airshuttle.app`, `malik@airshuttle.app`, `zoe@airshuttle.app`, `ryan@airshuttle.app` with password `pass123`

## Run

```bash
flutter pub get
flutter run -d chrome
```

You can also run on mobile/desktop devices supported by your Flutter setup.

## Notes

- Match uploads from non-admin users are marked `Pending` until approved in the Admin tab.
- Admin uploads auto-approve and immediately update ratings.
- Ratings are recalculated incrementally from approved match submissions.
