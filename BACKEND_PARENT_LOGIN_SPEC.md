# Backend: Parent App Login Response Requirement

## Overview

The parent app sends `client: 'parent_app'` in the login request. To prevent non-parents from reaching the OTP screen, the backend must **either**:

1. **Include `user_type` in the response** (app blocks non-parents), OR  
2. **Reject non-parents with 403 before sending OTP** (backend blocks them)

**Both** is recommended for defense in depth.

## Problem (when backend does neither)

When a parent logs in, the backend returns OTP but may not include user type. The app allows proceeding when `user_type` is missing (trusting backend validation). If the backend does not reject non-parents, drivers/admins could reach the OTP screen.

## Backend Response Formats

**Admin (blocked by app):** Backend returns `user` with `user_type`:
```json
{
  "success": true,
  "requires_otp": true,
  "otp_id": 177,
  "user": { "user_type": "admin", "id": 3 },
  "delivery_methods": {...},
  ...
}
```
→ App detects `user_type: "admin"` and blocks before OTP ✓

**Parent (when backend omits user):** No `user` object → app allows (trusts backend).

**Recommendation:** Return `user: { user_type: "parent", id: N }` for parents too, so the app can block non-parents even when backend 403 is not implemented.

## Required: Add User Type to Login Response

The parent app sends `client: 'parent_app'` in the login request. The backend must include **one** of the following so the app can verify the user is a parent before showing the OTP screen:

### Option 1: Root-level (simplest)

```json
{
  "success": true,
  "user_type": "parent",
  "requires_otp": true,
  "otp_id": 169,
  ...
}
```

Or use `"role": "parent"` if your API uses that field.

### Option 2: User object

```json
{
  "success": true,
  "user": {
    "user_type": "parent",
    "id": 123,
    "email": "user@example.com",
    ...
  },
  "requires_otp": true,
  "otp_id": 169,
  ...
}
```

### Option 3: Parent object

```json
{
  "success": true,
  "parent": {
    "user_type": "parent",
    "id": 123,
    "email": "user@example.com",
    ...
  },
  "requires_otp": true,
  "otp_id": 169,
  ...
}
```

## Backend Access Control (REQUIRED to block non-parents)

**The backend MUST reject non-parents when `client: 'parent_app'`.** Without this, drivers and admins can reach the OTP screen.

```python
# In login view, BEFORE sending OTP:
if request.data.get('client') == 'parent_app':
    user_type = getattr(user, 'user_type', None) or getattr(user, 'role', None)
    if user_type not in ('parent', 'guardian'):
        return Response({
            'success': False,
            'message': 'Only parents can access the application. Contact your admin for further assistance.',
            'code': 'parent_app_restricted'
        }, status=status.HTTP_403_FORBIDDEN)
# ... only then send OTP for parents ...
```

| User type | Backend returns | App behavior |
|-----------|-----------------|--------------|
| Parent | 200 + otp_id | Proceeds to OTP |
| Driver/Admin/etc. | 403, no otp_id | Shows error, never reaches OTP |

## Summary

| Field        | Location              | Value   |
|-------------|----------------------|---------|
| `user_type` | Root, user, or parent | `"parent"` or `"guardian"` |
| `role`      | Same                 | Alternative to `user_type` |
| `role_type` | Same                 | Also supported (aligns with web) |
| `user_role` | Same                 | Also supported |
| `type`      | Same                 | Also supported |

The app checks the same fields as the web frontend (`extractUserType` in backofficeAuthUtils.js) for consistency.

Without this, the parent app will block all logins with: *"Unable to verify your account type. Please ask your administrator to ensure the login system includes user information for parent app access."*
