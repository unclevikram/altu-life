# Altu Health - Flutter Mobile App

A privacy-first health dashboard mobile app that unifies HealthKit and Screen Time data with AI-powered insights.

## Features

### 📊 Dashboard
- **Health Overview**: View average steps, sleep duration, and screen time
- **Steps Chart**: Interactive area chart with date range filtering (7D, 30D, All Time)
- **Energy Calendar**: 28-day heatmap showing your best days
- **Sleep Quality Analysis**: Correlation between sleep duration and activity
- **Digital Diet**: Screen time breakdown by category with donut chart
- **Trends Section**: Weekly health summaries and sleep stability with moving average
- **Correlations**: Sleep vs Screen Time quadrant scatter plot, app impact matrix
- **Comparisons**: Weekday vs Weekend behavior analysis
- **Rhythms**: Weekly pattern radar chart and app intensity heatmap
- **Goals**: Achievement streak calendar and wellness score tracking

### 💡 Insights
- **What's Working**: Discover positive correlations (e.g., music + workouts)
- **Opportunities**: Identify areas for improvement
- **Personal Bests**: Track your records for steps, workouts, sleep, and energy

### 🤖 Ask Altu (AI Chat)
- Powered by Google's Gemini AI
- Context-aware responses based on your health data
- Pre-built suggestion prompts for quick insights
- Privacy-focused: all analysis happens on-device

## Tech Stack

- **Framework**: Flutter 3.x
- **State Management**: Riverpod
- **Navigation**: GoRouter
- **Charts**: fl_chart
- **Icons**: Lucide Icons
- **Fonts**: Google Fonts (Inter)
- **AI**: Google Gemini API

## Project Structure

```
lib/
├── app/                    # App configuration
│   ├── router/            # Navigation routes
│   └── theme/             # Colors and theme
├── data/                   # Data layer
│   ├── models/            # Data models
│   ├── mock_data.dart     # Sample health data
│   └── data_processing.dart
├── features/              # Feature modules
│   ├── dashboard/         # Dashboard screen
│   ├── insights/          # Insights screen
│   ├── ask_altu/          # AI chat screen
│   └── home/              # Home with navigation
├── providers/             # Riverpod providers
├── services/              # External services (Gemini)
└── shared/                # Shared widgets
```

## Setup

### Prerequisites
- Flutter SDK ^3.9.2
- Xcode (for iOS)
- Android Studio (for Android)

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Create a `.env` file in the root directory:
   ```
   GEMINI_API_KEY=your_gemini_api_key_here
   ```

4. Run the app:
   ```bash
   flutter run
   ```

### Getting a Gemini API Key
1. Visit [Google AI Studio](https://aistudio.google.com/app/apikey)
2. Create a new API key
3. Add it to your `.env` file

## Design Principles

This app follows these design principles:

1. **Pixel-perfect UI**: Matches the React web app design exactly
2. **Clean Architecture**: Separation of concerns with feature-based folders
3. **Maintainable Code**: Comprehensive documentation and clear naming
4. **Performance**: Optimized charts and lazy loading
5. **Accessibility**: Proper color contrast and touch targets
6. **Privacy**: Local data processing with optional cloud AI

## Color Palette

- **Brand Green**: `#22C55E` (primary), `#16A34A` (dark)
- **Background**: `#F8FAFC` (slate-50)
- **Cards**: White with `#F1F5F9` border
- **Accents**: Violet, Rose, Amber, Blue

## Future Enhancements

- [ ] HealthKit integration for real data
- [ ] Screen Time API integration
- [ ] Data persistence with local database
- [ ] Push notifications for goals
- [ ] Widget support
- [ ] Apple Watch companion app

## License

Private - Altu Health
