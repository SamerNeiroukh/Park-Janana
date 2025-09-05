# Park Janana Management App

## Overview
The **Park Janana App** is a full-stack mobile application developed in Flutter with a Firebase backend.  
It streamlines staff management, shift scheduling, task tracking, and reporting for **Park Janana**, a large multi-department recreational park in Jerusalem.

This project was selected among the **Top 5 Final Projects (2025)** at Azrieli College of Engineering.

---

## Problem Statement
Park Janana previously relied on WhatsApp, Excel, and Google Forms to manage:  
- Shifts  
- Worker communication  
- Attendance tracking  
- Task distribution  

These tools were insufficient, leading to:  
- Scheduling conflicts  
- Miscommunication  
- Lack of real-time data  
- No centralized reporting system  

---

## Requirements
Requirements were gathered from real park operations:  

- **Workers**: View shifts, request to join, clock in/out, track hours  
- **Shift Managers**: Approve/reject workers, assign tasks, monitor staff  
- **Department Managers**: Oversee departmental operations  
- **Park Manager**: Manage all departments, monitor resources  
- **Owner**: Full visibility and analytics  

---

## Solution – Application Features

### Authentication & User Management
- Secure Firebase Authentication (Email/Password)  
- Role-based access: Worker, Manager, Department Manager, Owner  
- New worker registration flow  

<div align="center">
  <img src="https://github.com/user-attachments/assets/81123351-357b-492f-beb6-2b93d2db275c" width="280" />
</div>

---

### Personalized Dashboards
- Worker dashboard: Tasks, shifts, attendance summary  
- Manager dashboard: Approvals, staff status, shift management  
- Owner dashboard: Analytics and reporting  

<div align="center">
  <img src="https://github.com/user-attachments/assets/727af802-722a-4d1a-a69e-d054a50438c2" width="250" />
  <img src="https://github.com/user-attachments/assets/8410ad61-f2ea-49b3-803c-6ad1d2543f3b" width="250" />
</div>

---

### Shift Management
- Workers request to join shifts  
- Managers approve or reject requests  
- Role-based worker assignment  
- Real-time updates with Firebase  

<div align="center">
  <img src="https://github.com/user-attachments/assets/c0c52538-f432-4c7d-bc35-3986e05d2884" width="250" />
  <img src="https://github.com/user-attachments/assets/4dd306c8-2d3a-49af-842e-3d06d6082833" width="250" />
</div>

---

### Task Management
- Create tasks for single or multiple workers  
- Track progress per worker  
- Worker dashboard: "My Tasks"  
- Manager dashboard: "All Tasks" with filtering  
- Edit and delete tasks  

<div align="center">
  <img src="https://github.com/user-attachments/assets/b09a7c80-7342-46b4-b74b-338bac02cc49" width="250" />
  <img src="https://github.com/user-attachments/assets/44246e50-7004-4661-b3c2-68287cb003da" width="250" />
</div>

---

### Attendance (Clock In/Out)
- Workers log attendance with one tap  
- Real-time session tracking  
- Automatic calculation of:  
  - Days worked (per month)  
  - Hours worked (decimal precision)  
- Motivational design with animations  

<div align="center">
  <img src="https://github.com/user-attachments/assets/f8edea74-ea21-4bd6-9935-f24a64324a6c" width="250" />
  <img src="https://github.com/user-attachments/assets/48a1b84a-1a16-4f9b-b86d-6c87340774b3" width="250" />
  <img src="https://github.com/user-attachments/assets/fa9f2004-3dd4-4948-91ce-3b9b969c07bf" width="250" />
</div>

---

### Reporting & Analytics
- Export Attendance Reports (PDF/Excel)  
- Export Task Reports (PDF)  
- Worker Shift Report with approval history  
- Data organized per month for historical records  

<div align="center">
  <img src="https://github.com/user-attachments/assets/90831832-63f3-4d1b-b38c-8f31445edf5f" width="250" />
  <img src="https://github.com/user-attachments/assets/076b0a41-1ae7-4bf8-aff4-17b39945b741" width="250" />
</div>

---

### Flow Process
<div align="center">
  <img src="https://github.com/user-attachments/assets/4e8ad6b2-fff9-4189-8b14-9e93f0825793" width="600" />
</div>

---

## Technical Stack
- **Frontend:** Flutter (Dart)  
- **Backend:** Firebase (Firestore, Auth, Cloud Functions)  
- **DevOps:** GitHub, Azure Pipelines  
- **Design Tools:** Figma, custom assets  

### Architecture Diagram
Flutter (UI)
↘ Firebase Auth
↘ Firestore (Realtime DB)
↘ Firebase Functions (triggers, logic)

<div align="center">
  <img src="https://github.com/user-attachments/assets/3b805a40-fb64-4a35-9de7-9f22b8c54269" width="500" />
</div>

---

## Setup Instructions

### Prerequisites
- Flutter SDK 3.5.4 or higher
- Dart SDK
- Firebase project with Authentication and Firestore enabled

### Firebase Configuration
1. **Create a Firebase project** at [Firebase Console](https://console.firebase.google.com/)
2. **Enable Authentication** (Email/Password provider)
3. **Enable Firestore Database** 
4. **Generate Firebase configuration**:
   - Run `flutter pub global activate flutterfire_cli`
   - Run `flutterfire configure`
   - This will create `lib/firebase_options.dart` with your project configuration
   
   **Alternative**: Copy `lib/firebase_options_template.dart` to `lib/firebase_options.dart` and manually configure with your Firebase project settings.

### Installation
```bash
# Clone the repository
git clone https://github.com/SamerNeiroukh/Park-Janana.git
cd Park-Janana

# Install dependencies
flutter pub get

# Configure Firebase (see Firebase Configuration above)

# Run the app
flutter run
```

### Running Tests
```bash
flutter test
```

---

## Future Enhancements
- Push notifications for shift and task updates  
- In-app chat between managers and workers  
- AI-based scheduling recommendations  
- Multi-language support (Hebrew, Arabic, English)  

---

## Achievements & Skills Gained

### Achievements
- Selected as Top 5 Final Project at Azrieli College (2025)  
- Tested in real-world environment at Park Janana  
- Designed modular and scalable architecture  

### Skills Gained
- Full-stack development with Flutter and Firebase  
- UI/UX design and animations  
- Role-based access control implementation  
- Real-time synchronization with Firestore  
- Exporting structured data (PDF/Excel)  
- CI/CD with Azure Pipelines  

---

## About the Developer
**Samer Neiroukh**  
- BSc in Software Engineering (2025), Azrieli College of Engineering  
- Full-Stack Developer | Mobile Developer (Flutter, React, Firebase)  
- Strong background in Java, C++, and Python  
- Fluent in Arabic, Hebrew, and English  
- GitHub: [github.com/SamerNeiroukh](https://github.com/SamerNeiroukh)  
- LinkedIn: [linkedin.com/in/samer-neiroukh-217ab1340](https://linkedin.com/in/samer-neiroukh-217ab1340)  
