# Parent-Student Linking Implementation

## Overview

This document describes the implementation of parent-student linking during registration. The implementation supports both:

1. **Option 1**: Explicit student information provided during registration
2. **Option 3**: Backend auto-matching by email address and phone number

## Implementation Details

### 1. Registration Request Model Updates

The `RegistrationRequest` model (`lib/core/models/registration_request.dart`) has been updated to include optional student linking fields:

```dart
final String? studentId;      // Student ID for direct linking
final String? studentEmail;  // Student email for auto-matching
final String? studentPhone;   // Student phone for auto-matching
```

These fields are:
- **Optional**: Parents can register without providing student information
- **Included in API request**: Sent to backend via `toJson()` method
- **Used for auto-matching**: Backend can use these to automatically link parents to students

### 2. Registration Screen UI Updates

The registration screen (`lib/features/auth/screens/register_screen.dart`) now includes:

- **Optional Student Information Section**: A clearly labeled section with divider
- **Three input fields**:
  - Student ID (text input)
  - Student Email (email input with validation)
  - Student Phone (phone input with +254 prefix, same format as parent phone)
- **User-friendly messaging**: Explains that linking can be done later if not provided

### 3. Data Flow

```
Registration Form
    ↓
RegistrationRequest (with optional student fields)
    ↓
parentAuthProvider.registerWithOtp()
    ↓
API POST /api/v1/users/otp/register/
    ↓
Backend receives:
  - Parent information (required)
  - Student linking fields (optional):
    * student_id
    * student_email
    * student_phone
```

## Backend Requirements for Auto-Matching

The backend should implement the following logic when processing registration requests:

### Auto-Matching Priority

1. **Direct Student ID Match** (if `student_id` provided):
   - Find student by ID
   - Create parent-student relationship
   - Set as primary contact if first parent

2. **Email Matching** (if `student_email` provided):
   - Find student(s) with matching email
   - If single match: Create relationship
   - If multiple matches: May need additional verification or link to all

3. **Phone Matching** (if `student_phone` provided):
   - Find student(s) with matching phone number
   - If single match: Create relationship
   - If multiple matches: May need additional verification or link to all

4. **Parent Email/Phone Matching** (automatic, no user input needed):
   - Match parent's email with student's parent email field
   - Match parent's phone with student's parent phone field
   - Create relationship if match found

### Backend API Request Format

When a parent registers, the backend will receive:

```json
{
  "username": "parent_username",
  "email": "parent@example.com",
  "password": "password123",
  "password_confirm": "password123",
  "first_name": "John",
  "last_name": "Doe",
  "user_type": "parent",
  "phone_number": "+254712345678",
  "address": "123 Main St",
  "emergency_contact_name": "Jane Doe",
  "emergency_contact_phone": "+254798765432",
  "source": "mobile",
  "device_info": {
    "user_agent": "Flutter (ios)",
    "device_type": "mobile"
  },
  // Optional student linking fields:
  "student_id": "STU001",           // Optional
  "student_email": "student@school.com",  // Optional
  "student_phone": "+254712345679"        // Optional
}
```

### Backend Response

The backend should:
1. Create the parent account
2. Attempt to link students using the provided information
3. Return success even if no students were linked (parents can link later)
4. Optionally include linked students in the response for confirmation

## Usage

### For Parents

1. **During Registration**:
   - Fill in parent information (required)
   - Optionally provide student information:
     - Student ID (if known)
     - Student Email (for auto-matching)
     - Student Phone (for auto-matching)
   - Complete registration

2. **After Registration**:
   - If students were linked automatically, they will appear in the parent's student list
   - If not linked, parents can contact school administrator to link manually
   - Parents can also use a separate "Link Student" feature if implemented

### For Developers

The implementation is backward compatible:
- Existing registration flows continue to work
- Student fields are optional
- No breaking changes to existing API contracts

## Testing

To test the implementation:

1. **Test with Student ID**:
   ```dart
   RegistrationRequest(
     // ... parent fields ...
     studentId: "STU001",
   )
   ```

2. **Test with Student Email**:
   ```dart
   RegistrationRequest(
     // ... parent fields ...
     studentEmail: "student@school.com",
   )
   ```

3. **Test with Student Phone**:
   ```dart
   RegistrationRequest(
     // ... parent fields ...
     studentPhone: "+254712345679",
   )
   ```

4. **Test without Student Info** (should still work):
   ```dart
   RegistrationRequest(
     // ... parent fields only ...
   )
   ```

## Future Enhancements

Potential improvements:
1. **Student Search**: Add a search feature to find students by name/ID
2. **Multiple Students**: Support linking multiple students during registration
3. **Verification**: Add verification step for student linking
4. **Admin Approval**: Require admin approval for student linking
5. **Relationship Type**: Allow specifying relationship type (parent, guardian, etc.)

## Notes

- All student linking fields are optional to maintain flexibility
- The backend should handle cases where:
  - No student information is provided (normal registration)
  - Student information is provided but no match is found (log for admin review)
  - Multiple students match (may need admin intervention)
- The parent's own email and phone are automatically available for matching even if not explicitly provided in student fields
