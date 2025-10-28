import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/parent_provider.dart';
import '../../map/screens/map_screen.dart';

class ParentTrackingScreen extends ConsumerWidget {
  const ParentTrackingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parentState = ref.watch(parentProvider);

    print('🔍 DEBUG: ParentTrackingScreen building...');
    print('🔍 DEBUG: parentState.isLoading: ${parentState.isLoading}');
    print(
      '🔍 DEBUG: parentState.activeTrips: ${parentState.activeTrips.length}',
    );

    if (parentState.isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading...'),
            ],
          ),
        ),
      );
    }

    print('🔍 DEBUG: Returning MapScreen (ignoring activeTrips check)...');
    return const MapScreen();
  }
}
