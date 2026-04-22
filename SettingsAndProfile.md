# Technical Specification: Profile & Settings View

## 1. View Architecture
The Profile section is a dedicated tab within the iOS application. It is divided into two primary visual components: the **Identity Header** and the **Settings List**.

---

## 2. Identity Header Components
This section represents the user's social presence within the app.

### **Avatar (Profile Picture)**
- **UI:** Circular image container with a 1:1 aspect ratio.
- **Interactions:**
    - Tapping triggers `PHPicker` (iOS Photo Library) or Camera access.
    - Overlay "Edit" icon (pencil) visible during edit mode.
- **Fallback:** Default system placeholder (e.g., `person.circle.fill` from SF Symbols).

### **User Identifiers**
- **Display Name:**
    - Primary label; supports Unicode/Emojis.
    - Editable via an "Edit Profile" flow.
- **Username (@handle):**
    - Unique system identifier.
    - Secondary text style (smaller, gray/secondary color).

### **Social Metrics**
- **Friend Count:** - Displayed as a button/label (e.g., "124 Friends").
    - **Action:** Navigation to `FriendsListView`, filtering for the current user's connections and pending requests.

---

## 3. Settings List (Grouped)
The settings should be implemented as a standard iOS `List` or `Form` using grouped sections for native feel.

### **Section: Account**
- [ ] **Email:** Display current email; link to "Change Email" flow.
- [ ] **Password:** Trigger "Reset Password" workflow.
- [ ] **Security:** Toggle for Biometric Login (FaceID/TouchID) if applicable.

### **Section: Privacy**
- [ ] **Profile Visibility:** Picker (Options: `Public`, `Friends Only`, `Private`).
- [ ] **Activity Sharing:** Toggle for broadcasting "Started Reading" or "Finished Book" events to the friend feed.
- [ ] **Blocked Users:** Navigation to a list of blocked accounts with "Unblock" functionality.

### **Section: Notifications**
- [ ] **Push Notifications:** Toggle for global push alerts.
- [ ] **Social Alerts:** Granular toggles for `Friend Requests` and `New Reviews`.
- [ ] **Reminders:** Toggle for daily/weekly reading reminders.

### **Section: Appearance**
- [ ] **Theme Mode:** Segmented control or Picker (Options: `Light`, `Dark`, `System`).
- [ ] **App Icon:** (Optional) Support for `setAlternateIconName` to allow custom icons.

### **Section: Support & Legal**
- [ ] **Rate App:** External link to the iOS App Store product page.
- [ ] **Contact Support:** Deep link to mail client or internal feedback form.
- [ ] **Privacy Policy:** Link to external URL or local Markdown view (App Store Requirement).
- [ ] **Terms of Service:** Link to external URL or local Markdown view.

### **Section: Danger Zone (Compliance)**
- [ ] **Sign Out:** Standard button; clears local session/tokens.
- [ ] **Delete Account:** - **Requirement:** Mandatory for App Store Review.
    - **UI:** Destructive red text.
    - **Flow:** Must include a "Double Confirmation" alert warning that data deletion is irreversible.
    - **Backend Action:** Must trigger a cascading delete of user data (profile, reviews, relationships).