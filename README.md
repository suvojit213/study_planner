# Study Planner - Flutter App

A modern and user-friendly Flutter study planner app designed specifically for Android devices. This app helps students track their study sessions, manage subjects, and monitor their learning progress with an intuitive timer system.

## Features

### 🏠 Home Screen
- **Study Overview**: View today's total study time and progress
- **Current Session Display**: Real-time timer display when studying
- **Subject Progress**: Track time spent on each subject today
- **Beautiful UI**: Clean and modern interface with gradient designs

### ⏱️ Study Timer
- **Start/Pause/Resume**: Full control over study sessions
- **Subject Selection**: Must select a subject before starting
- **Visual Feedback**: Animated timer with color-coded states
- **Session Management**: Automatic saving of study progress

### 📚 Subject Management
- **Add Subjects**: Create subjects with name, description, and target time
- **Edit/Delete**: Full CRUD operations for subjects
- **Subject Selection**: Choose which subject to study
- **Search & Sort**: Find and organize subjects easily
- **Target Setting**: Set study time goals for each subject

### 💾 Database Features
- **SQLite Integration**: Local data storage using SQFlite
- **Study Sessions**: Track all study sessions with timestamps
- **Progress Analytics**: View total time studied per subject
- **Data Persistence**: All data saved locally on device

## Technical Stack

- **Framework**: Flutter (Latest)
- **Database**: SQLite (SQFlite package)
- **State Management**: Provider pattern with ChangeNotifier
- **Platform**: Android (Primary target)
- **Architecture**: Clean architecture with separation of concerns

## Project Structure

```
lib/
├── main.dart                 # App entry point and navigation
├── models/
│   ├── subject.dart         # Subject data model
│   └── study_session.dart   # Study session data model
├── services/
│   ├── timer_service.dart   # Timer logic and session management
│   └── subject_service.dart # Subject CRUD operations
├── database/
│   └── database_helper.dart # SQLite database operations
└── screens/
    ├── home_screen.dart     # Home dashboard
    ├── timer_screen.dart    # Study timer interface
    └── subjects_screen.dart # Subject management
```

## Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  sqflite: ^2.3.3
  path_provider: ^2.1.3

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
```

## Installation & Setup

1. **Prerequisites**
   - Flutter SDK installed
   - Android Studio or VS Code with Flutter extensions
   - Android device or emulator

2. **Clone & Setup**
   ```bash
   # Extract the provided zip file
   unzip study_planner_app.zip
   cd study_planner
   
   # Get dependencies
   flutter pub get
   
   # Run the app
   flutter run
   ```

3. **Build for Android**
   ```bash
   # Debug build
   flutter build apk --debug
   
   # Release build
   flutter build apk --release
   ```

## App Usage

### Getting Started
1. **Add Subjects**: Go to the Subjects tab and add your study subjects
2. **Set Targets**: Define how many minutes you want to study each subject
3. **Select Subject**: Choose a subject before starting your study session
4. **Start Studying**: Use the Timer tab to start, pause, and end study sessions
5. **Track Progress**: Monitor your daily progress on the Home screen

### Study Session Workflow
1. Navigate to **Subjects** tab
2. Add a new subject or select an existing one
3. Go to **Timer** tab
4. Tap **Start** to begin studying
5. Use **Pause** to take breaks
6. Tap **End** when finished studying
7. View progress on **Home** screen

## Key Features Explained

### Timer States
- **Stopped** (Gray): Ready to start a new session
- **Running** (Blue/Purple): Currently studying with animated pulse
- **Paused** (Orange/Red): Session paused, can resume or end

### Database Schema
- **Subjects Table**: id, name, description, target_minutes, created_at
- **Study Sessions Table**: id, subject_id, start_time, end_time, duration_minutes, is_completed

### Navigation
- **Bottom Navigation Bar**: Smooth transitions between screens
- **Animated Icons**: Visual feedback for selected tabs
- **State Persistence**: App remembers your progress across sessions

## Customization

### Colors & Themes
The app uses a modern blue color scheme with gradients. You can customize colors in:
- `main.dart` - Primary theme colors
- Individual screen files - Gradient and accent colors

### Adding Features
The modular architecture makes it easy to add new features:
- Add new models in `models/` directory
- Extend services for new functionality
- Create new screens following the existing pattern

## Performance Optimizations

- **Efficient State Management**: Uses ChangeNotifier for minimal rebuilds
- **Database Optimization**: Indexed queries and efficient data structures
- **Memory Management**: Proper disposal of controllers and listeners
- **Smooth Animations**: Optimized animations for better user experience

## Troubleshooting

### Common Issues
1. **Database Errors**: Ensure proper permissions for file storage
2. **Timer Not Working**: Check if subject is selected before starting
3. **Build Errors**: Run `flutter clean` and `flutter pub get`

### Debug Mode
- Enable debug mode to see detailed logs
- Use Flutter Inspector for UI debugging
- Check database contents using SQLite browser tools

## Future Enhancements

- **Statistics Dashboard**: Detailed analytics and charts
- **Study Reminders**: Push notifications for study sessions
- **Export Data**: Backup and restore functionality
- **Dark Mode**: Theme switching capability
- **Study Goals**: Weekly and monthly targets
- **Pomodoro Timer**: Built-in break intervals

## Contributing

This is a complete Flutter study planner app ready for use. The code is well-documented and follows Flutter best practices for easy maintenance and extension.

## License

This project is created for educational purposes. Feel free to use and modify as needed.

---

**Happy Studying! 📚⏰**