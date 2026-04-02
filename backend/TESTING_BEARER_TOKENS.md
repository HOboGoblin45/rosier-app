# Bearer Token Authentication Testing Guide

## Overview

This guide demonstrates how to test the fixed bearer token authentication system in the Rosier API.

## Authentication Flow

### 1. Obtain Access Token

First, you need to authenticate and get an access token. There are multiple ways:

#### Email Registration
```bash
curl -X POST http://localhost:8000/api/v1/auth/email/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "SecurePassword123",
    "display_name": "John Doe"
  }'
```

Response:
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "expires_in": 900
}
```

#### Email Login
```bash
curl -X POST http://localhost:8000/api/v1/auth/email/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "SecurePassword123"
  }'
```

### 2. Use Token in Protected Endpoints

All protected endpoints require the Authorization header with Bearer token:

```bash
curl -H "Authorization: Bearer <access_token>" \
  http://localhost:8000/api/v1/profile
```

## Testing Examples

### Valid Request (200 OK)

```bash
TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

curl -X GET http://localhost:8000/api/v1/profile \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json"
```

Response:
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "email": "user@example.com",
  "display_name": "John Doe",
  "onboarding_completed": false,
  "created_at": "2026-04-01T12:00:00Z",
  "updated_at": "2026-04-01T12:00:00Z"
}
```

### Missing Authorization Header (401 Unauthorized)

```bash
curl -X GET http://localhost:8000/api/v1/profile \
  -H "Content-Type: application/json"
```

Response:
```json
{
  "detail": "Missing authorization header"
}
```

HTTP Status: 401 Unauthorized
Headers: `WWW-Authenticate: Bearer`

### Invalid Format (401 Unauthorized)

```bash
curl -X GET http://localhost:8000/api/v1/profile \
  -H "Authorization: InvalidFormat token123" \
  -H "Content-Type: application/json"
```

Response:
```json
{
  "detail": "Invalid authorization header format. Use: Bearer <token>"
}
```

HTTP Status: 401 Unauthorized

### Expired Token (401 Unauthorized)

```bash
# Token exists but expired
curl -X GET http://localhost:8000/api/v1/profile \
  -H "Authorization: Bearer expired_token_xyz" \
  -H "Content-Type: application/json"
```

Response:
```json
{
  "detail": "Invalid or expired token"
}
```

HTTP Status: 401 Unauthorized

### Case Insensitive Bearer Prefix

All of these are valid:

```bash
# Standard
curl -H "Authorization: Bearer $TOKEN" ...

# Lowercase
curl -H "Authorization: bearer $TOKEN" ...

# Mixed case
curl -H "Authorization: BeArEr $TOKEN" ...
```

## Testing All Protected Endpoints

### Profile Endpoints

```bash
# Get profile
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:8000/api/v1/profile

# Update profile
curl -X PUT http://localhost:8000/api/v1/profile \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "display_name": "New Name",
    "email": "newemail@example.com"
  }'

# Get Style DNA
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:8000/api/v1/profile/style_dna

# Share Style DNA
curl -X POST http://localhost:8000/api/v1/profile/style_dna/share \
  -H "Authorization: Bearer $TOKEN"
```

### Card Endpoints

```bash
# Get next cards
curl -H "Authorization: Bearer $TOKEN" \
  "http://localhost:8000/api/v1/cards/next?count=10"

# Submit swipe events
curl -X POST http://localhost:8000/api/v1/cards/events \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "session_id": "session-123",
    "events": [
      {
        "product_id": "product-1",
        "action": "LIKE",
        "dwell_time_ms": 500,
        "session_position": 1,
        "expanded": false
      }
    ]
  }'

# Get swipe history
curl -H "Authorization: Bearer $TOKEN" \
  "http://localhost:8000/api/v1/cards/events?limit=20"

# Clear queue
curl -X DELETE http://localhost:8000/api/v1/cards/queue \
  -H "Authorization: Bearer $TOKEN"
```

### Brand Discovery Endpoints

```bash
# Get next brand card
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:8000/api/v1/brands/discover

# Submit brand reaction
curl -X POST http://localhost:8000/api/v1/brands/discover/react \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "card_id": "card-123",
    "action": "like",
    "dwell_time_ms": 1000,
    "session_id": "session-123"
  }'

# Get trending brands
curl -H "Authorization: Bearer $TOKEN" \
  "http://localhost:8000/api/v1/brands/trending?limit=10"

# Get favorite brands
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:8000/api/v1/brands/favorites
```

### Dresser (Closet) Endpoints

```bash
# Get dresser
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:8000/api/v1/dresser

# Create drawer
curl -X POST http://localhost:8000/api/v1/dresser/drawers \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "My Favorites",
    "description": "Items I love"
  }'

# Add item to drawer
curl -X POST http://localhost:8000/api/v1/dresser/items \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "drawer_id": "drawer-123",
    "product_id": "product-456"
  }'
```

### Wallpaper Endpoints

```bash
# Get current wallpaper
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:8000/api/v1/wallpaper/current

# Get available wallpapers
curl -H "Authorization: Bearer $TOKEN" \
  "http://localhost:8000/api/v1/wallpaper/patterns?limit=20"

# Record wallpaper impression
curl -X POST http://localhost:8000/api/v1/wallpaper/impressions \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "pattern_id": "pattern-123",
    "dwell_ms": 2000,
    "session_id": "session-123",
    "swipe_position": 1
  }'
```

### Referral Endpoints

```bash
# Get referral code
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:8000/api/v1/referral/code

# Get referral stats
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:8000/api/v1/referral/stats

# Get referral link
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:8000/api/v1/referral/link

# Apply referral code
curl -X POST http://localhost:8000/api/v1/referral/apply \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "code": "INVITE123",
    "source": "imessage"
  }'

# Get leaderboard
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:8000/api/v1/referral/leaderboard
```

### Onboarding Endpoints

```bash
# Submit quiz
curl -X POST http://localhost:8000/api/v1/onboarding/quiz \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "responses": {
      "preferred_categories": ["dresses", "shoes"],
      "preferred_subcategories": ["casual", "formal"],
      "preferred_tags": {"color": "black", "style": "minimalist"},
      "price_point": 75.0
    }
  }'

# Get onboarding status
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:8000/api/v1/onboarding/status
```

### Account Management

```bash
# Delete account
curl -X DELETE http://localhost:8000/api/v1/auth/account \
  -H "Authorization: Bearer $TOKEN"
```

## Token Refresh Flow

Tokens expire after 15 minutes by default (configurable). Use refresh token to get new access token:

```bash
curl -X POST http://localhost:8000/api/v1/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{
    "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }'
```

Response:
```json
{
  "access_token": "new_eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "new_eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "expires_in": 900
}
```

## Common Testing Tools

### Using curl

```bash
# Save token to variable
TOKEN=$(curl -s -X POST http://localhost:8000/api/v1/auth/email/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"pass"}' \
  | jq -r '.access_token')

# Use it
curl -H "Authorization: Bearer $TOKEN" http://localhost:8000/api/v1/profile
```

### Using Postman

1. Create new request
2. Set method to GET
3. Set URL to `http://localhost:8000/api/v1/profile`
4. Go to "Authorization" tab
5. Select "Bearer Token" from Type dropdown
6. Paste your access token in Token field
7. Click Send

### Using Python (requests)

```python
import requests

token = "your_access_token_here"
headers = {"Authorization": f"Bearer {token}"}

response = requests.get(
    "http://localhost:8000/api/v1/profile",
    headers=headers
)
print(response.json())
```

### Using JavaScript (fetch)

```javascript
const token = "your_access_token_here";

fetch("http://localhost:8000/api/v1/profile", {
  headers: {
    "Authorization": `Bearer ${token}`,
    "Content-Type": "application/json"
  }
})
  .then(r => r.json())
  .then(data => console.log(data));
```

## Security Notes

1. **Always use HTTPS** in production - tokens are sensitive credentials
2. **Store tokens securely** - use secure storage, not localStorage in web apps
3. **Set appropriate token expiry** - 15 minutes for access tokens is standard
4. **Rotate refresh tokens** - automatic on refresh endpoint
5. **Revoke tokens on logout** - server-side revocation supported
6. **Never expose tokens in URLs** - always use Authorization header
7. **Implement token refresh** - refresh before expiry for better UX

## Troubleshooting

### "Missing authorization header"
- Ensure you're sending the Authorization header
- Use format: `Authorization: Bearer <token>`

### "Invalid authorization header format"
- Check header format is exactly: `Bearer <token>` (case insensitive)
- Ensure there's a space between Bearer and token

### "Invalid or expired token"
- Token may have expired - use refresh token to get new one
- Token signature might be invalid - regenerate
- JWT secret configuration might differ between environments

### Header not recognized
- Some HTTP clients convert header names - check capitalization
- Verify header is actually being sent with curl `-v` flag

## References

- [RFC 6750 - OAuth 2.0 Bearer Token Usage](https://tools.ietf.org/html/rfc6750)
- [FastAPI Security Documentation](https://fastapi.tiangolo.com/tutorial/security/)
- [JWT.io - JWT Introduction](https://jwt.io/introduction)
