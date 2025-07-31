import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/home_viewmodel.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeViewModelProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Walkie'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.location_on,
              size: 60,
              color: Colors.blue,
            ),
            const SizedBox(height: 20),
            homeState.when(
              loading: () => const CircularProgressIndicator(),
              error: (error, _) => Text(
                'Error: $error',
                style: const TextStyle(color: Colors.red),
              ),
              data: (data) => Column(
                children: [
                  Text(
                    'Location Services Ready',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 10),
                  if (data.currentPosition != null)
                    Text(
                      'Lat: ${data.currentPosition!.latitude.toStringAsFixed(4)}, '
                      'Lng: ${data.currentPosition!.longitude.toStringAsFixed(4)}',
                    ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(homeViewModelProvider.notifier).getCurrentLocation();
              },
              icon: const Icon(Icons.my_location),
              label: const Text('Get Current Location'),
            ),
          ],
        ),
      ),
    );
  }
}