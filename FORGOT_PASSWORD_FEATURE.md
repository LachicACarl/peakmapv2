# Forgot Password & Email Verification Feature

## Overview
Added comprehensive password recovery and email verification system for the Peak Map passenger application.

## Features Implemented

### 1. Forgot Password Screen (`passenger/forgot_password_screen.dart`)
- User enters email address
- System sends password reset link via email
- Shows confirmation message with email address
- User can try different email address

### 2. Email Verification Screen (`passenger/forgot_password_screen.dart`)
**Two Steps:**
- **Step 1 - OTP Verification**: User receives 6-digit code in email
- **Step 2 - New Password**: User creates new password with confirmation

**Features:**
- Email input validation
- 6-digit OTP code input
- Password strength validation (minimum 6 characters)
- Password match verification
- Show/hide password toggle

### 3. Backend Endpoints (FastAPI)

#### POST `/auth/forgot-password`
**Request:**
```json
{
  "email": "user@example.com"
}
```
**Response:**
```json
{
  "success": true,
  "message": "Password reset OTP sent to user@example.com"
}
```

#### POST `/auth/verify-email`
**Request:**
```json
{
  "email": "user@example.com",
  "otp": "123456"
}
```
**Response:**
```json
{
  "success": true,
  "message": "Email verified successfully"
}
```

#### POST `/auth/reset-password`
**Request:**
```json
{
  "email": "user@example.com",
  "new_password": "newpassword123",
  "token": "123456"
}
```
**Response:**
```json
{
  "success": true,
  "message": "Password reset successfully"
}
```

## Frontend Integration

### Login Screen Updates
- Added "Forgot Password?" link below password field
- Link visible only for passenger login (not driver)
- Pressing link navigates to `ForgotPasswordScreen`

### Auth Service Methods
Added three new methods to `lib/services/auth_service.dart`:

1. **`requestPasswordReset(email)`** - Sends password reset request
2. **`verifyEmail(email, otp)`** - Verifies email with OTP code
3. **`resetPassword(email, newPassword, token)`** - Updates password

## User Flow

```
Login Screen
    ↓
[Forgot Password Link]
    ↓
Forgot Password Screen
    ↓ [User enters email]
    ↓
Email Sent Confirmation
    ↓ [Auto-redirect after 3 seconds]
    ↓
Verify Email Screen
    ↓ [User enters OTP from email]
    ↓
Create New Password Step
    ↓ [User enters new password]
    ↓
Password Reset Success
    ↓ [Redirect to login] 
    ↓
Login Screen (with new password)
```

## Demo Mode Behavior

For testing without email service:
- **Request Password Reset**: Always succeeds, returns OTP (123456)
- **Verify Email**: Accepts any 6-digit code
- **Reset Password**: Always succeeds, allows any password (6+ chars)

## Production Considerations

To enable real email functionality:

1. **Email Service Integration**
   - Add email provider (SendGrid, AWS SES, Mailgun)
   - Update `forgot-password` endpoint to send actual emails
   - Include reset link or OTP in email body

2. **Token Management**
   - Store OTP with expiration (typically 15-30 minutes)
   - Use database or Redis for temporary storage
   - Validate token on each step

3. **Security**
   - Hash and salt passwords using bcrypt
   - Implement rate limiting on password reset requests
   - Add CAPTCHA to prevent abuse
   - Send password reset notification to email after successful reset

4. **Supabase Email Templates**
   - Configure custom email templates in Supabase
   - Customize "From" address and branding
   - Add link expiration timestamps

## Testing Checklist

- [x] Flutter compilation (no errors)
- [x] Login screen shows forgot password link
- [x] Click forgot password navigates correctly
- [x] Email validation works
- [x] OTP field accepts 6-digit input
- [x] New password requires minimum 6 characters
- [x] Passwords must match
- [x] Backend endpoints respond correctly

## Files Modified/Created

**Created:**
- `peak_map_mobile/lib/passenger/forgot_password_screen.dart` - Forgot password + verification screens

**Modified:**
- `peak_map_mobile/lib/auth/login_screen.dart` - Added forgot password link
- `peak_map_mobile/lib/services/auth_service.dart` - Added 3 new auth methods
- `peak-map-backend/app/routes/auth.py` - Added 3 new endpoints

## Next Steps

1. Integrate with actual email service provider
2. Set up OTP storage and expiration logic
3. Add rate limiting to prevent abuse
4. Implement password strength requirements
5. Add audit logging for security events
