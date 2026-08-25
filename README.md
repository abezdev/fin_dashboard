# finance dashboard

A Flutter dashboard for balances, recurring bills, and upcoming paydays. The
screen currently runs in clearly labeled demo mode so it can be previewed
without Plaid credentials.

## Plaid setup

Plaid Link must be initialized with a short-lived link token created by a
trusted server. Never put Plaid client secrets in this Flutter app.

The client boundary is in `lib/plaid_service.dart`. Start your backend with an
endpoint that accepts `POST /api/plaid/link-token` and returns:

```json
{ "link_token": "link-sandbox-..." }
```

Run Flutter with the backend URL:

```text
flutter run --dart-define=PLAID_API_BASE_URL=https://your-api.example.com
```

The backend should create the token using the Plaid `/link/token/create`
endpoint, exchange the resulting public token with `/item/public_token/exchange`,
and proxy normalized balance, transaction, and income data to the app. Plaid
data access should be authorized and refreshed server-side.
