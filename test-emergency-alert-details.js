const axios = require('axios');

// Configuration
const API_BASE_URL = 'https://schooltransit-backend-staging-ixld.onrender.com/api/v1';
const ALERT_ID = 2; // The alert ID from your example

// Test the emergency alert details endpoint
async function testEmergencyAlertDetails() {
  try {
    console.log('🚨 Testing Emergency Alert Details API...');
    console.log(`📡 Endpoint: ${API_BASE_URL}/emergency/alerts/${ALERT_ID}/`);

    const response = await axios.get(`${API_BASE_URL}/emergency/alerts/${ALERT_ID}/`);

    console.log('✅ API Response Status:', response.status);
    console.log('📊 Response Data Structure:');
    console.log(JSON.stringify(response.data, null, 2));

    // Validate the response structure
    const alert = response.data;

    console.log('\n🔍 Validating Response Structure:');

    // Check required fields
    const requiredFields = [
      'id', 'emergency_type', 'emergency_type_display', 'severity', 'severity_display',
      'status', 'status_display', 'title', 'description', 'address', 'reported_at',
      'estimated_resolution', 'affected_students_count', 'estimated_delay_minutes',
      'notification_sent', 'parent_notification_sent', 'school_notification_sent',
      'metadata', 'is_active', 'created_at', 'updated_at'
    ];

    const missingFields = requiredFields.filter(field => !(field in alert));
    if (missingFields.length > 0) {
      console.log('❌ Missing required fields:', missingFields);
    } else {
      console.log('✅ All required fields present');
    }

    // Check nested objects
    console.log('\n🏗️ Checking Nested Objects:');

    if (alert.vehicle) {
      console.log('✅ Vehicle object present');
      console.log(`   - License Plate: ${alert.vehicle.license_plate}`);
      console.log(`   - Make/Model: ${alert.vehicle.make} ${alert.vehicle.model}`);
      console.log(`   - Driver: ${alert.vehicle.driver_name}`);
    } else {
      console.log('⚠️ Vehicle object missing');
    }

    if (alert.route) {
      console.log('✅ Route object present');
      console.log(`   - Route Name: ${alert.route.name}`);
      console.log(`   - Type: ${alert.route.route_type_display}`);
      console.log(`   - Duration: ${alert.route.estimated_duration} min`);
      console.log(`   - Distance: ${alert.route.total_distance} km`);
    } else {
      console.log('⚠️ Route object missing');
    }

    if (alert.students && alert.students.length > 0) {
      console.log(`✅ Students array present (${alert.students.length} students)`);
      alert.students.forEach((student, index) => {
        console.log(`   Student ${index + 1}: ${student.full_name} (Grade ${student.grade})`);
        if (student.current_trip) {
          console.log(`     - Current Trip: ${student.current_trip.trip_id} (${student.current_trip.status})`);
        }
        if (student.parents && student.parents.length > 0) {
          console.log(`     - Parents: ${student.parents.map(p => p.parent_name).join(', ')}`);
        }
      });
    } else {
      console.log('⚠️ Students array missing or empty');
    }

    if (alert.reported_by) {
      console.log('✅ Reporter object present');
      console.log(`   - Name: ${alert.reported_by.full_name}`);
      console.log(`   - Email: ${alert.reported_by.email}`);
      console.log(`   - Type: ${alert.reported_by.user_type}`);
    } else {
      console.log('⚠️ Reporter object missing');
    }

    // Check timeline information
    console.log('\n⏰ Timeline Information:');
    console.log(`   - Reported: ${alert.reported_at}`);
    if (alert.acknowledged_at) {
      console.log(`   - Acknowledged: ${alert.acknowledged_at}`);
    }
    if (alert.resolved_at) {
      console.log(`   - Resolved: ${alert.resolved_at}`);
    }
    console.log(`   - Estimated Resolution: ${alert.estimated_resolution}`);

    // Check metadata
    if (alert.metadata && Object.keys(alert.metadata).length > 0) {
      console.log('\n📋 Metadata:');
      Object.entries(alert.metadata).forEach(([key, value]) => {
        console.log(`   - ${key}: ${value}`);
      });
    }

    // Check updates
    if (alert.updates && alert.updates.length > 0) {
      console.log(`\n📝 Updates (${alert.updates.length}):`);
      alert.updates.forEach((update, index) => {
        console.log(`   Update ${index + 1}: ${update.title} (${update.status})`);
        console.log(`     - Description: ${update.description}`);
        console.log(`     - Created: ${update.created_at}`);
      });
    } else {
      console.log('\n📝 No updates available');
    }

    console.log('\n🎉 Emergency Alert Details API test completed successfully!');

  } catch (error) {
    console.error('❌ Error testing Emergency Alert Details API:');
    if (error.response) {
      console.error('   Status:', error.response.status);
      console.error('   Data:', error.response.data);
    } else {
      console.error('   Message:', error.message);
    }
  }
}

// Test the emergency alerts list endpoint
async function testEmergencyAlertsList() {
  try {
    console.log('\n🚨 Testing Emergency Alerts List API...');
    console.log(`📡 Endpoint: ${API_BASE_URL}/emergency/alerts/`);

    const response = await axios.get(`${API_BASE_URL}/emergency/alerts/`);

    console.log('✅ API Response Status:', response.status);
    console.log(`📊 Found ${response.data.results?.length || 0} emergency alerts`);

    if (response.data.results && response.data.results.length > 0) {
      console.log('\n📋 Available Emergency Alerts:');
      response.data.results.forEach((alert, index) => {
        console.log(`   ${index + 1}. ID: ${alert.id} - ${alert.title} (${alert.severity_display})`);
        console.log(`      Status: ${alert.status_display} | Type: ${alert.emergency_type_display}`);
        console.log(`      Affected Students: ${alert.affected_students_count}`);
        console.log(`      Reported: ${alert.reported_at}`);
        console.log('');
      });
    }

  } catch (error) {
    console.error('❌ Error testing Emergency Alerts List API:');
    if (error.response) {
      console.error('   Status:', error.response.status);
      console.error('   Data:', error.response.data);
    } else {
      console.error('   Message:', error.message);
    }
  }
}

// Run the tests
async function runTests() {
  console.log('🚀 Starting Emergency Alert API Tests...\n');

  await testEmergencyAlertsList();
  await testEmergencyAlertDetails();

  console.log('\n🏁 All tests completed!');
}

// Execute the tests
runTests().catch(console.error);
