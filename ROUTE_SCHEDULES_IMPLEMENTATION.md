# Route Schedules Implementation

This document describes the implementation of route schedules functionality using the API endpoint `api/v1/routes/routes/{id}/schedules/`.

## Overview

The route schedules feature allows the app to fetch and display schedule information for specific routes, including:
- Day of the week
- Start and end times
- Active status
- Creation and update timestamps

## API Endpoint

**Endpoint:** `GET /api/v1/routes/routes/{id}/schedules/`

**Example Response:**
```json
[
    {
        "id": 2,
        "route": 1,
        "day_of_week": "monday",
        "day_of_week_display": "Monday",
        "start_time": "07:00:00",
        "end_time": "08:30:00",
        "is_active": true,
        "created_at": "2025-10-13T18:33:57.300707+03:00",
        "updated_at": "2025-10-13T18:33:57.300730+03:00"
    }
]
```

## Implementation Details

### 1. API Endpoints Configuration

**File:** `lib/core/config/api_endpoints.dart`

Added route-related endpoints:
```dart
/// GET /api/v1/routes/routes/{id}/schedules/
/// Get route schedules
static String routeSchedules(int routeId) => '/api/v1/routes/routes/$routeId/schedules/';
```

### 2. Data Model

**File:** `lib/core/models/route_model.dart`

Created `RouteSchedule` class:
```dart
class RouteSchedule {
  final int id;
  final int route;
  final String dayOfWeek;
  final String dayOfWeekDisplay;
  final String startTime;
  final String endTime;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Constructor, fromJson, toJson methods...
}
```

### 3. State Management

**File:** `lib/core/providers/route_provider.dart`

Updated `RouteState` to include schedules:
```dart
class RouteState {
  // ... existing fields
  final List<RouteSchedule> schedules;

  // ... constructor and copyWith method
}
```

Added `loadRouteSchedules` method to `RouteNotifier`:
```dart
Future<void> loadRouteSchedules(int routeId) async {
  // Implementation to fetch schedules from API
}
```

### 4. UI Components

**File:** `lib/features/routes/widgets/route_schedules_widget.dart`

Created `RouteSchedulesWidget` that:
- Displays loading state
- Shows error messages
- Renders schedule cards
- Handles empty state

## Usage Examples

### Basic Usage with Provider

```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routeState = ref.watch(routeProvider);

    // Load schedules for route ID 1
    ref.read(routeProvider.notifier).loadRouteSchedules(1);

    return ListView.builder(
      itemCount: routeState.schedules.length,
      itemBuilder: (context, index) {
        final schedule = routeState.schedules[index];
        return ListTile(
          title: Text(schedule.dayOfWeekDisplay),
          subtitle: Text('${schedule.startTime} - ${schedule.endTime}'),
        );
      },
    );
  }
}
```

### Direct API Usage

```dart
// Load schedules directly without provider
final response = await ApiService.get<List<dynamic>>(
  ApiEndpoints.routeSchedules(routeId),
);

if (response.success && response.data != null) {
  final schedules = response.data!
      .map((s) => RouteSchedule.fromJson(s))
      .toList();
}
```

### Filtering and Sorting

```dart
// Get only active schedules
final activeSchedules = schedules.where((s) => s.isActive).toList();

// Get schedules for specific day
final mondaySchedules = schedules
    .where((s) => s.dayOfWeek == 'monday')
    .toList();

// Sort by start time
schedules.sort((a, b) => a.startTime.compareTo(b.startTime));
```

## Features

### 1. Loading States
- Shows loading indicator while fetching data
- Handles network errors gracefully
- Provides retry functionality

### 2. Data Display
- Day of week with visual indicators
- Time range display
- Active/inactive status badges
- Clean card-based layout

### 3. Error Handling
- Network error messages
- Empty state handling
- Retry mechanisms

### 4. State Management
- Integrated with existing RouteProvider
- Reactive UI updates
- Efficient state management

## File Structure

```
lib/
├── core/
│   ├── config/
│   │   └── api_endpoints.dart          # API endpoint definitions
│   ├── models/
│   │   └── route_model.dart            # RouteSchedule model
│   └── providers/
│       └── route_provider.dart         # State management
└── features/
    └── routes/
        └── widgets/
            └── route_schedules_widget.dart  # UI components
```

## Testing

The implementation includes comprehensive error handling and loading states that can be tested:

1. **Loading State**: Verify loading indicator appears
2. **Success State**: Verify schedules are displayed correctly
3. **Error State**: Verify error messages and retry functionality
4. **Empty State**: Verify empty state message when no schedules

## Future Enhancements

1. **Caching**: Implement local caching for offline access
2. **Real-time Updates**: Add WebSocket support for live updates
3. **Filtering**: Add UI filters for day of week, active status
4. **Sorting**: Add sorting options for schedules
5. **Pagination**: Support for large numbers of schedules

## Dependencies

- `flutter_riverpod`: State management
- `http`: API communication
- `flutter`: UI framework

## Notes

- The API returns schedules as an array, not wrapped in a results object
- All times are in HH:MM:SS format
- Day of week uses lowercase format (monday, tuesday, etc.)
- The implementation is fully integrated with the existing app architecture
