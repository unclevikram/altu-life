# Altu Health - Flutter Mobile App

A privacy-first health dashboard mobile app that unifies HealthKit and Screen Time data with AI-powered insights.

## What’s Inside
- Loads 90 days of mock HealthKit + Screen Time JSON into one daily model so every chart and insight stays in sync.
- Dashboard, Insights, Ask Altu; all wired through Riverpod providers for lightweight, targeted rebuilds.
- Averages, buckets, moving averages, and Pearson correlations—chosen because they’re transparent, easy to verify, and also cheap to run on-device.
- Gemini first, OpenAI as backup; prompt shards keep token use low and answers consistent.

## Tech Stack

- **Framework**: Flutter 3.x
- **State Management**: Riverpod
- **Navigation**: GoRouter
- **Charts**: fl_chart
- **Icons**: Lucide Icons
- **Fonts**: Google Fonts (Inter)
- **AI**: Google Gemini API and OpenAI

## Project Structure

```
lib/
├── app/                     # Shell: theme, router, config
│   ├── config/              # Health constants/goals
│   ├── router/              # GoRouter setup
│   └── theme/               # Light/dark themes, colors
├── data/                    # Data layer
│   ├── models/              # HealthDay, ScreenTimeEntry, DailySummary
│   ├── processing/          # aggregation, statistics, sleep/activity/correlation/insights/calendar modules
│   ├── mock_data.dart       # Sample data + loader
│   └── data_processing.dart # Barrel export of processing modules
├── features/                # Feature slices
│   ├── dashboard/           # Dashboard screen + charts/widgets
│   ├── insights/            # Insights screen + cards
│   ├── ask_altu/            # Chat UI (providers, screen, widgets)
│   └── home/                # Bottom-nav shell
├── providers/               # Riverpod providers (health_providers.dart)
├── services/                # AI + orchestration (Gemini/OpenAI, context shards, intent router)
├── shared/                  # Reusable widgets (cards, bottom nav)
└── main.dart                # Entry point
```

## How each Dashboard section is calculated
- **Top stats**: Simple averages from `getAverage` on the current `DateRange`.
- **Steps Overview (area)**: plot steps per day; x = index, y = steps; labels adapt to range; curved line with gradient.
- **Energy Calendar (heatmap)**: `getEnergyCalendarData` scores 0–4 per day (+1 each for steps>10k, sleep>7h, workout>30m, entertainment<60m); pads to Sunday; “show more” collapses all-time to last 35 real days.
- **Sleep Duration vs Activity (bars)**: `getSleepQualityStats` buckets days (<7h, 7–8h, >8h) and averages steps + screen per bucket. Chosen for clarity over noisy per-day dots.
- **Digital Diet (donut + bars)**: `getCategoryBreakdown` sums screen minutes by category across the range; bars show % of total and relative magnitude; donut mirrors the same distribution.
- **Weekly Health Summary (lines)**: `getWeeklyStats` buckets by week (Sunday start), averages steps and sleep hours, sums workout minutes; shows last 8 weeks to keep it readable.
- **Sleep Stability (area + MA)**: `getSleepTrendMA` emits daily sleep hours plus a 7-day moving average to smooth noise.
- **Weekday vs Weekend**: `getWeekdayVsWeekend` averages steps, sleep, entertainment, productivity for weekdays vs weekends; stacked split bar for contrast.
- **Weekly Rhythm Radar**: `getWeeklyRhythm` averages steps/sleep/workout/energy per weekday; normalized to each metric’s max so shapes, not absolutes, stand out.
- **App Intensity Heatmap**: `getAppUsageByDay` averages minutes per app per weekday; cells shade up to a 60-minute cap to keep outliers from washing the grid.
- **Goals / Wellness Score**: `getGoalsAndScore` daily points (workout +10, steps>8k +5, sleep>7h +5) and cumulative total; chart shows running score and goal hits. Gamified to drive adherence with simple rules.
- **Correlation Flow**: `calculateWorkoutEnergyCorrelation` Pearson r on workout minutes vs active energy, labeled by strength; picked for explainable, unitless measure.

## How each Insights card is calculated
- **Personal Bests**: `getPersonalBests` finds max steps/sleep/workout/energy; `getBestDayStats` scores days (steps vs goal, sleep vs optimal, workout bonus, entertainment penalty) and compares top 10% to baseline.
- **Sleep after workouts**: `getSleepAfterWorkoutStats` compares next-night sleep after workout vs rest days.
- **Sleep consistency**: `getSleepConsistencyStats` std dev of nightly minutes; score 100→0 where 60m std dev ≈ 50pts. Chosen for intuitive “variability hurts score” framing.
- **Recovery sleep**: `getRecoverySleepStats` builds exertion = steps/10k + workout/60 + energy/1000; compares next-night sleep after high vs low exertion.
- **Weekend sleep**: `getWeekendSleepStats` weekday vs weekend averages.
- **Productivity vs Sleep**: `getProductivityVsSleepData` pairs productivity minutes with sleep hours; text compares high- vs low-productivity days for a nudge on boundaries.
- **Low vs High Steps**: `getLowStepStats` contrasts screen time and energy for <5k vs ≥5k steps; highlights tradeoffs.
- **Workout momentum**: `getWorkoutMomentum` compares next-day steps/sleep after workout days (≥30m) vs rest.
- **Activity momentum**: `getActivityMomentumStats` compares same-day steps on workout vs rest days.
- **Workout streaks**: `getWorkoutStreakStats` max/avg/count of consecutive workout days.
- **App–Health correlations**: `getAppHealthCorrelations` + `calculateAppHealthCorrelation` run Pearson r for target apps vs sleep/steps/energy/workout; keep |r| ≥ 0.3; sorted strongest-first. Chosen for simplicity and interpretability.
- **Scatter / quadrant (screen vs sleep)**: `getScreenVsSleepScatter` maps screen hours vs sleep hours with quadrant labels (Ideal, Weekend Mode, Productive, Warning).

## How Ask Altu works (chat)
- **UI**: `AskAltuScreen` renders history, loading dots, suggestion chips, send bar; warns if no API key so dashboards still work.
- **State**: `chat_provider.dart` seeds a friendly greeting, debounces sends, and passes full data context once.
- **Intent routing**: `IntentRouter` keyword-maps to sleep/activity/screen/correlations/goals/general—deterministic and dependency-free to stay light on-device.
- **Context shards**: `ContextShardBuilder` slices data into small, reusable sections (persona, stats, sleep, activity, correlations, recency, weekly rhythm, app usage, table, goals) to keep prompts short and relevant.
- **Prompt build**: `AskAltuOrchestrator` orders shards per intent, trims history to last 3 exchanges, applies date filters if the user mentions them, and uses `ResponseGuard` to ensure an actionable takeaway even if the model is terse.
- **Providers & fallback**: `AIServiceManager` tries Gemini first, then OpenAI; both share the same prompt. `GeminiService` caches the full data context on first use to avoid resending 90 days every turn; short backoff on rate limits.
- **Why this shape**: Shards + intent routing cut token cost and reduce hallucination; fallback keeps chat alive under rate limits; guard enforces user-facing usefulness.

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
   (Optional) Add `OPENAI_API_KEY` for fallback.

4. Run the app:
   ```bash
   flutter run
   ```

### Getting a Gemini API Key
1. Visit [Google AI Studio](https://aistudio.google.com/app/apikey)
2. Create a new API key
3. Add it to your `.env` file

## Why these choices
- **Transparent math**: Pearson correlations, moving averages, and simple thresholds are easy to audit and explain; avoids opaque ML while still being insightful.
- **Small, focused modules**: Keeps testability high and avoids another monolithic `data_processing.dart`.
- **Many narrow providers**: Minimizes widget rebuilds in a chart-heavy UI.
- **Prompt shards**: Lower latency and cost versus shipping the whole dataset every turn; improves relevance by intent.

## Design Principles

This app follows these design principles:

- Separation of concerns with feature-based folders
- Optimized charts and lazy loading
- Proper color contrast and touch targets

## Color Palette

- **Brand Green**: `#22C55E` (primary), `#16A34A` (dark)
- **Background**: `#F8FAFC` (slate-50)
- **Cards**: White with `#F1F5F9` border
- **Accents**: Violet, Rose, Amber, Blue
