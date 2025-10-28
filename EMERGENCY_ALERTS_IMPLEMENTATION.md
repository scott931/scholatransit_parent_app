# Emergency Alerts Implementation

## Overview

This implementation provides a comprehensive emergency alerts system for parents in the ScholaTransit app. The system allows parents to view real-time emergency alerts affecting their children's bus routes, with detailed information about incidents, affected students, and resolution updates.

## Features

### 🚨 Emergency Alerts Screen
- **Real-time Alert Display**: Shows all active and recent emergency alerts
- **Advanced Filtering**: Filter by status (reported, in progress, resolved) and type (accident, breakdown, etc.)
- **Search Functionality**: Search alerts by title, description, or emergency type
- **Visual Status Indicators**: Color-coded severity and status indicators
- **Refresh Capability**: Manual refresh to get latest alerts

### 📱 Alert Details Screen
- **Comprehensive Information**: Complete details about each emergency alert
- **Vehicle Information**: Details about the affected vehicle and driver
- **Route Information**: Information about the affected route
- **Student Impact**: List of affected students with their details
- **Location Details**: Address and coordinates of the incident
- **Updates Timeline**: Chronological updates about the emergency

### 🎨 UI/UX Features
- **Modern Design**: Clean, intuitive interface following Material Design principles
- **Responsive Layout**: Optimized for different screen sizes using ScreenUtil
- **Color-coded System**:
  - Red for high severity/active alerts
  - Orange for medium severity/in progress
  - Green for low severity/resolved
- **Empty States**: Informative empty states with helpful guidance
- **Error Handling**: Comprehensive error states with retry options

## API Integration

### Endpoint
```
GET /api/v1/emergency/alerts/
```

### Response Structure
```json
{
  "count": 2,
  "next": null,
  "previous": null,
  "results": [
    {
      "id": 2,
      "emergency_type": "accident",
      "emergency_type_display": "Accident",
      "severity": "low",
      "severity_display": "Low",
      "status": "reported",
      "status_display": "Reported",
      "title": "Bus Accident on Route 5",
      "description": "Bus #1234 involved in minor accident...",
      "vehicle": { ... },
      "route": { ... },
      "students": [ ... ],
      "location": "SRID=4326;POINT (-74.0059 40.7128)",
      "location_display": "40.712800, -74.005900",
      "address": "123 Main Street, New York, NY",
      "reported_by": { ... },
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
      "metadata": { ... },
      "duration_minutes": null,
      "is_active": true,
      "updates": [ ... ],
      "created_at": "2025-10-11T10:34:16.090734+03:00",
      "updated_at": "2025-10-13T22:16:28.696187+03:00"
    }
  ]
}
```

## File Structure

```
lib/features/parent/screens/
├── emergency_alerts_screen.dart          # Main emergency alerts screen
└── parent_notifications_screen.dart      # Existing parent notifications

lib/core/providers/
└── emergency_provider.dart               # Emergency alerts state management

test-emergency-alerts-api.js              # API testing script
```

## Implementation Details

### State Management
- Uses Riverpod for state management
- Integrates with existing `EmergencyProvider`
- Handles loading, error, and success states
- Automatic data refresh capabilities

### Data Models
- `EmergencyAlert`: Main alert model with all properties
- `EmergencyVehicle`: Vehicle information
- `EmergencyRoute`: Route details
- `EmergencyStudent`: Student information
- `EmergencyUpdate`: Alert updates timeline

### Navigation
- Seamless navigation between alerts list and details
- Proper back navigation handling
- State preservation during navigation

## Usage

### Adding to Navigation
```dart
// In your navigation setup
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const EmergencyAlertsScreen(),
  ),
);
```

### Integration with Parent Dashboard
```dart
// Add emergency alerts button to parent dashboard
ElevatedButton.icon(
  onPressed: () => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const EmergencyAlertsScreen(),
    ),
  ),
  icon: const Icon(Icons.emergency),
  label: const Text('Emergency Alerts'),
  style: ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFFDC2626),
    foregroundColor: Colors.white,
  ),
)
```

## Testing

### API Testing
Run the test script to verify API connectivity:
```bash
node test-emergency-alerts-api.js
```

### Manual Testing
1. Navigate to Emergency Alerts screen
2. Verify loading state appears
3. Check that alerts are displayed correctly
4. Test filtering and search functionality
5. Tap on an alert to view details
6. Verify all information is displayed correctly

## Error Handling

### Network Errors
- Connection timeout handling
- Retry mechanisms
- User-friendly error messages

### Data Errors
- Invalid response handling
- Missing data graceful degradation
- Fallback UI for missing information

### State Management
- Loading state management
- Error state clearing
- State persistence

## Performance Considerations

### Optimization
- Efficient list rendering with proper item builders
- Image loading optimization
- Memory management for large datasets

### Caching
- Local caching of alert data
- Offline capability considerations
- Data refresh strategies

## Security Considerations

### Data Protection
- Secure API communication
- Authentication token handling
- Sensitive information masking

### Privacy
- Student information protection
- Location data handling
- Parent notification preferences

## Future Enhancements

### Planned Features
- Push notifications for new alerts
- Real-time updates via WebSocket
- Alert acknowledgment by parents
- Emergency contact integration
- Location-based alert filtering

### Technical Improvements
- Offline data synchronization
- Advanced filtering options
- Alert history and analytics
- Integration with school systems

## Troubleshooting

### Common Issues
1. **Alerts not loading**: Check API endpoint and authentication
2. **Filter not working**: Verify filter logic and data structure
3. **Details not showing**: Check navigation and data passing
4. **Performance issues**: Optimize list rendering and image loading

### Debug Information
- Enable debug logging in `AppConfig`
- Check network requests in browser dev tools
- Verify API response structure
- Test with different data scenarios

## Support

For technical support or questions about this implementation:
- Check the API documentation
- Review the error logs
- Test with the provided test script
- Verify network connectivity and authentication

---

**Note**: This implementation is designed to work with the existing ScholaTransit backend API. Ensure proper authentication and API endpoint configuration before deployment.
