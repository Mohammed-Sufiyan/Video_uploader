# 🎥 Flutter Video Uploader

A robust and automated **Flutter Android application** designed to seamlessly upload videos from the **ImouLife app** to **S3-compatible storage**.  
It runs continuously as a **background service**, handling uploads intelligently with retry mechanisms, notifications, and cleanup automation.

---

## ✨ Features

### 🔄 Automatic Background Uploads
Continuously monitors a target directory for new video files and uploads them automatically to your configured S3-compatible storage.

### 📱 Foreground Notifications
Displays live upload progress, completion, and error states through system notifications.

### 🗂️ Queue Management
Manages uploads sequentially with automatic retry and resume capabilities to ensure data consistency.

### 🗑️ Auto Cleanup
Deletes local video files after successful upload to save storage space.

### 🔐 Secure Uploads
Uses **presigned URLs** from a backend API — no AWS or storage credentials are stored in the app.

### 📊 Dashboard UI
Includes a Flutter-based dashboard with upload progress, logs, and manual controls.

### ⚡ Background Service
Operates silently in the background even when the app is closed — built with WorkManager for reliability.

---

## 🧩 Requirements

| Component | Requirement |
|------------|--------------|
| **Flutter SDK** | 3.10.0 or higher |
| **Android API** | 21+ (Android 5.0+) |
| **Storage** | Any S3-compatible service (E2E Networks Object Store, AWS S3, etc.) |
| **Backend API** | Required for generating presigned upload URLs |

---

## 📸 App Preview

| App Interface |
|----------------|

<p align="center">
  <img width="500" alt="Video Uploader App Preview" src="https://github.com/user-attachments/assets/7ad2c20b-63b0-4b7b-bb21-bca13cb74e29" />
</p>

---

## 🧱 Project Structure

<p align="center">
  <img width="500" alt="Project Structure" src="https://github.com/user-attachments/assets/f92c4379-1ab9-4e67-a7e9-0930d8f5bfc6" />
</p>

---

## 🔐 Security Highlights

- ✅ **Presigned URLs Only** – No stored credentials  
- ✅ **HTTPS** – Encrypted data transfers  
- ✅ **File Integrity Checks** – Prevents corrupted uploads  
- ✅ **Minimal Permissions** – Secure and efficient  

---

## 🧾 Troubleshooting

| Issue | Solution |
|--------|-----------|
| **Permission Denied** | Grant `MANAGE_EXTERNAL_STORAGE` in settings |
| **Files Not Found** | Ensure path `/Download/ImouLife/` is correct |
| **Upload Failures** | Check network connection and backend status |
| **Service Stops** | Disable battery optimization for the app |

---

## 👨‍💻 Author

<p align="center">
  <img src="https://github.com/user-attachments/assets/40cce1ce-65b3-4e13-9a44-8ad5dc4ab513" width="120" height="120" alt="Author Profile" style="border-radius: 50%;"/>
</p>

### **Mohammed Sufiyan**

If you found this project helpful, please consider giving it a ⭐ on GitHub to show your support and help others discover it!

---



## 🪪 License

**MIT License** — See the `LICENSE` file for details.

---

> 💡 *The Flutter Video Uploader app is built for reliable and secure automation of video uploads from ImouLife cameras to any S3-compatible storage.  
Feel free to customize and extend it for your workflow!*
