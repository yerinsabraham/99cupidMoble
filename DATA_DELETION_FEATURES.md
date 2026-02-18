# Data Deletion Features - Native App vs Web

## ✅ Available in Native Mobile App (Recommended Method)

### 1. **Delete Photos**
- **Location:** Settings → Edit Profile
- **How:** Tap any photo → Delete button
- **Result:** Photo immediately removed from profile

### 2. **Delete Conversations/Messages**  
- **Location:** Chat screen (any conversation)
- **How:** Open chat → Menu (⋮) → Delete Chat
- **Result:** Entire conversation deleted, cannot be undone

### 3. **Block Users**
- **Location:** User profile → Menu → Block User
- **Also:** Settings → Privacy → Blocked Users (manage all)
- **Result:** User blocked, removed from matches, can't contact you

### 4. **Report Users**
- **Location:** User profile → Menu → Report User
- **Result:** Report submitted to moderation team

### 5. **Edit/Remove Profile Information**
- **Location:** Settings → Edit Profile
- **Can modify:** Bio, interests, preferences, age, location
- **Result:** Information updated or cleared immediately

### 6. **Export All Data**
- **Location:** Settings → Account Management → Export My Data
- **Result:** JSON file with all your account data

### 7. **Delete Entire Account**
- **Location:** Settings → Account Management → Delete My Account
- **Flow:** 
  1. Warning screen showing what will be deleted
  2. Password verification required
  3. Confirmation dialog
  4. Account deletion begins
- **Timeline:** 
  - Immediate: Profile invisible to others
  - 7 days: Active data deleted
  - 30 days: Complete removal from backups

## 🌐 Web Pages (For Users Without App Access)

These exist primarily for **Google Play Store compliance** and users who:
- Don't have the app installed anymore
- Can't log into the app
- Lost access to their phone
- Want to request deletion from a computer

### Web URLs:

1. **Delete Specific Data Request**
   - URL: `https://cupid-e5874.web.app/delete-data`
   - Purpose: Request deletion of photos, messages, location data, etc.
   - Method: Fill form with email, select data types, receive instructions

2. **Delete Account Request**
   - URL: `https://cupid-e5874.web.app/account-deletion`
   - Purpose: Request full account deletion
   - Method: Fill form with email, verify identity, complete deletion

3. **Data Deletion Policy**
   - URL: `https://cupid-e5874.web.app/data-deletion-policy`
   - Purpose: Read full policy on what data is deleted and retained

## 📱 Recommended User Flow

### For Data Deletion (Partial):
1. **Primary:** Use native app features (instant, better UX)
2. **Fallback:** Use web form if can't access app

### For Account Deletion:
1. **Primary:** Settings → Account Management → Delete My Account
2. **Fallback:** Web form at cupid-e5874.web.app/account-deletion

## 🔒 What Cannot Be Deleted (By Design)

These are retained for legal/safety reasons:

- **Safety Reports:** Records of reports/investigations (legal compliance)
- **Banned Users:** Prevent re-registration of bad actors
- **Financial Records:** Transaction history (7 years for tax compliance)
- **Anonymized Analytics:** Aggregated, non-identifiable usage stats

## 📋 Google Play Store Compliance

✅ **Partial Data Deletion URL:** `https://cupid-e5874.web.app/delete-data`  
✅ **Account Deletion URL:** `https://cupid-e5874.web.app/account-deletion`  
✅ **Policy URL:** `https://cupid-e5874.web.app/data-deletion-policy`

All URLs are:
- Public (no authentication required)
- Accessible without app installed
- Clearly explain deletion process
- Specify timelines and data types

## 🎯 Summary

- **Native app:** Full featured, instant deletion, better UX
- **Web pages:** Backup method, compliance requirement, accessible without app
- **Both methods lead to same result:** Data gets deleted per policy

Users should be directed to use the **native app features first** for the best experience. Web pages serve as a safety net for users who lost app access.
