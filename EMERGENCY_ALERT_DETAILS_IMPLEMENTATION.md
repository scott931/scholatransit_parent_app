# Emergency Alert Details Implementation

## Overview

This document describes the comprehensive implementation of the emergency alert details functionality for the ScholaTransit driver app. The implementation includes improved data models, API integration, and a detailed UI screen for displaying emergency alert information.

## API Endpoint

**GET** `/api/v1/emergency/alerts/{id}/`

### Example Response Structure

```json
{
  "id": 2,
  "emergency_type": "accident",
  "emergency_type_display": "Accident",
  "severity": "low",
  "severity_display": "Low",
  "status": "reported",
  "status_display": "Reported",
  "title": "gfdgd",
  "description": "sdfsdf",
  "vehicle": {
    "id": 2,
    "license_plate": "KDC 458R",
    "make": "TOYOTA",
    "model": "X706",
    "year": 2025,
    "vin": "DSAFDSF23434",
    "vehicle_type": "bus",
    "type_display": "School Bus",
    "seating_capacity": 15,
    "status": "active",
    "status_display": "Active",
    "assigned_driver": 8,
    "driver_name": "ScottK Kariuki",
    "fuel_type": "diesel",
    "fuel_capacity": null,
    "current_latitude": null,
    "current_longitude": null,
    "last_location_update": null,
    "insurance_expiry": "2025-10-11",
    "registration_expiry": "2025-10-16",
    "created_at": "2025-10-09T15:38:04.424411+03:00",
    "updated_at": "2025-10-10T20:41:00.006070+03:00"
  },
  "route": {
    "id": 1,
    "name": "Syokimau Route",
    "description": "Syokimau Route",
    "route_type": "morning",
    "route_type_display": "Morning Route",
    "status": "active",
    "status_display": "Active",
    "estimated_duration": 45,
    "total_distance": "10.00",
    "max_capacity": 20,
    "assigned_vehicle": null,
    "assigned_driver": null,
    "is_fully_assigned": null,
    "current_student_count": 0,
    "stops": [...],
    "schedules": [...],
    "assignments": [...],
    "created_at": "2025-10-08T22:51:59.016087+03:00",
    "updated_at": "2025-10-13T18:34:37.592163+03:00"
  },
  "students": [...],
  "location": null,
  "location_display": null,
  "address": "Premier Bldg Suite 1, Along Katani Rd Syokimau, Kenya",
  "reported_by": {
    "id": 4,
    "first_name": "scott",
    "last_name": "Kariuki",
    "full_name": "scott Kariuki",
    "email": "scottmugo@gmail.com",
    "user_type": "admin"
  },
  "assigned_to": null,
  "reported_at": "2025-10-11T10:34:16.090681+03:00",
  "acknowledged_at": null,
  "resolved_at": null,
  "estimated_resolution": "2025-10-11T10:33:00+03:00",
  "affected_students_count": 1,
  "estimated_delay_minutes": 20,
  "notification_sent": false,
  "parent_notification_sent": false,
  "school_notification_sent": false,
  "metadata": {
    "traffic_conditions": "normal",
    "weather_conditions": "cloudy",
    "emergency_services_contacted": true
  },
  "duration_minutes": null,
  "is_active": true,
  "updates": [],
  "created_at": "2025-10-11T10:34:16.090734+03:00",
  "updated_at": "2025-10-13T22:16:28.696187+03:00"
}
```

## Implementation Details

### 1. Data Models

#### EmergencyAlert Class
The main model class that represents an emergency alert with all its associated data.

**Key Features:**
- Comprehensive field mapping for all API response fields
- Proper type safety with Dart's type system
- Support for nested objects (vehicle, route, students, etc.)
- Null safety throughout

#### Supporting Model Classes

- **EmergencyVehicle**: Vehicle information including license plate, make, model, driver details
- **EmergencyRoute**: Route information with stops, schedules, and assignments
- **EmergencyStudent**: Student details with current trip and parent information
- **EmergencyReporter**: Information about who reported the emergency
- **EmergencyAssignee**: Information about who the emergency is assigned to
- **EmergencyUpdate**: Timeline updates for the emergency
- **EmergencyStop**: Route stop information
- **EmergencySchedule**: Route schedule details
- **EmergencyAssignment**: Route assignment information
- **EmergencyCurrentTrip**: Current trip information for students
- **EmergencyUpcomingTrip**: Upcoming trip information
- **EmergencyParent**: Parent/guardian information

### 2. Provider Implementation

#### EmergencyNotifier
Enhanced with improved error handling and debugging:

```dart
Future<void> loadEmergencyAlertDetails(int alertId) async {
  state = state.copyWith(isLoading: true, error: null);

  try {
    print('🚨 DEBUG: Loading emergency alert details for ID: $alertId');

    final response = await ApiService.get<Map<String, dynamic>>(
      '${AppConfig.emergencyAlertsEndpoint}$alertId/',
    );

    if (response.success && response.data != null) {
      final alert = EmergencyAlert.fromJson(response.data!);
      state = state.copyWith(
        isLoading: false,
        selectedAlert: alert,
        error: null,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: response.error ?? 'Failed to load emergency alert details',
      );
    }
  } catch (e) {
    state = state.copyWith(
      isLoading: false,
      error: 'Failed to load emergency alert details: $e',
    );
  }
}
```

### 3. UI Implementation

#### EmergencyAlertDetailsScreen
A comprehensive screen that displays all emergency alert information in an organized, user-friendly format.

**Key Features:**
- **Responsive Design**: Uses ScreenUtil for consistent sizing across devices
- **Error Handling**: Displays appropriate error states and retry functionality
- **Loading States**: Shows loading indicators during data fetching
- **Comprehensive Information Display**:
  - Alert header with severity and status indicators
  - Vehicle information with driver details
  - Route information with stops and schedules
  - Affected students with current trip status
  - Location information
  - Reporter details
  - Timeline with key events
  - Updates and metadata

**UI Sections:**

1. **Alert Header**
   - Title and description
   - Severity and status badges
   - Emergency type indicator

2. **Alert Status**
   - Affected students count
   - Estimated delay
   - Notification status

3. **Vehicle Information**
   - License plate, make, model
   - Driver information
   - Vehicle status

4. **Route Information**
   - Route name and type
   - Duration and distance
   - Capacity information

5. **Affected Students**
   - Student cards with photos/initials
   - Current trip status
   - Parent information

6. **Location Information**
   - Address and coordinates
   - Location display

7. **Reporter Information**
   - Reporter name and contact
   - User type

8. **Timeline**
   - Visual timeline of events
   - Reported, acknowledged, resolved times
   - Estimated resolution

9. **Updates**
   - List of emergency updates
   - Status changes and messages

10. **Metadata**
    - Additional information
    - Traffic and weather conditions

### 4. Error Handling

The implementation includes comprehensive error handling:

- **Network Errors**: Connection timeouts and network failures
- **API Errors**: HTTP status codes and error messages
- **Data Parsing Errors**: Invalid JSON or missing fields
- **User-Friendly Messages**: Clear error messages for users
- **Retry Functionality**: Users can retry failed requests

### 5. Testing

#### Test Script
A comprehensive test script (`test-emergency-alert-details.js`) is provided to validate the API implementation:

- Tests the emergency alert details endpoint
- Validates response structure
- Checks for required fields
- Verifies nested objects
- Tests the emergency alerts list endpoint

#### Usage
```bash
node test-emergency-alert-details.js
```

## Usage

### 1. Navigation to Emergency Alert Details

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => EmergencyAlertDetailsScreen(
      alertId: 2, // The emergency alert ID
    ),
  ),
);
```

### 2. Provider Usage

```dart
// Watch the emergency state
final emergencyState = ref.watch(emergencyProvider);

// Load emergency alert details
ref.read(emergencyProvider.notifier).loadEmergencyAlertDetails(alertId);

// Access the selected alert
final alert = emergencyState.selectedAlert;
```

### 3. Error Handling

```dart
if (emergencyState.error != null) {
  // Handle error state
  showErrorDialog(emergencyState.error!);
}

if (emergencyState.isLoading) {
  // Show loading indicator
  return CircularProgressIndicator();
}
```

## Benefits

1. **Comprehensive Data Display**: Shows all relevant emergency information in an organized manner
2. **Type Safety**: Strong typing prevents runtime errors
3. **Error Handling**: Graceful error handling with user-friendly messages
4. **Responsive Design**: Works well on different screen sizes
5. **Real-time Updates**: Can refresh data to get latest information
6. **Accessibility**: Clear visual hierarchy and readable text
7. **Performance**: Efficient data loading and rendering

## Future Enhancements

1. **Real-time Updates**: WebSocket integration for live updates
2. **Push Notifications**: Real-time notifications for emergency updates
3. **Offline Support**: Cache emergency data for offline viewing
4. **Analytics**: Track user interactions with emergency alerts
5. **Accessibility**: Enhanced accessibility features for screen readers
6. **Internationalization**: Multi-language support for emergency alerts

## Conclusion

The emergency alert details implementation provides a comprehensive, user-friendly interface for viewing detailed emergency information. The implementation follows Flutter best practices with proper state management, error handling, and responsive design. The modular approach allows for easy maintenance and future enhancements.
