# Token Server

Tiny local server for the assessment.

```powershell
copy .env.example .env
node server.js
```

Endpoints:

- `GET /health`
- `GET /token?userId=&role=&roomId=`
- `GET /messages`
- `POST /messages`
- `POST /messages/read`
- `GET /requests`
- `POST /requests`
- `POST /requests/approve`
- `POST /requests/decline`
- `GET /rooms`
- `GET /logs`
- `POST /logs`
- `POST /logs/member-notes`
- `POST /logs/trainer-notes`

When `HMS_APP_ACCESS_KEY` and `HMS_APP_SECRET` are set, `/token` returns a signed 100ms-style JWT. Without credentials, it returns a mock token and the Flutter app uses its demo fallback.
