import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../complaints/presentation/bloc/complaints_bloc.dart';
import '../../../../shared/widgets/common_widgets.dart';
import '../../../../shared/models/complaint_model.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/services/injection.dart';

/// Map page showing complaints
class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  final Set<Marker> _markers = {};
  bool _isLoading = true;
  Complaint? _selectedComplaint;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }

      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (_mapController != null && _currentPosition != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          ),
        );
      }
    } catch (e) {
      debugPrint('Location error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_currentPosition != null) {
      controller.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        ),
      );
    }
  }

  void _updateMarkers(List<Complaint> complaints) {
    _markers.clear();
    for (final complaint in complaints) {
      _markers.add(
        Marker(
          markerId: MarkerId(complaint.id),
          position: LatLng(
            complaint.location.latitude,
            complaint.location.longitude,
          ),
          infoWindow: InfoWindow(
            title: complaint.title,
            snippet: complaint.category.displayName,
          ),
          icon: _getMarkerIcon(complaint.category),
          onTap: () {
            setState(() => _selectedComplaint = complaint);
          },
        ),
      );
    }
  }

  BitmapDescriptor _getMarkerIcon(ComplaintCategory category) {
    switch (category) {
      case ComplaintCategory.waterLeakage:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
      case ComplaintCategory.streetLight:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
      case ComplaintCategory.garbage:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      case ComplaintCategory.lawAndOrder:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      case ComplaintCategory.roadDamage:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
      default:
        return BitmapDescriptor.defaultMarker;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ComplaintsBloc>()
        ..add(ComplaintsLoadNearby(
          latitude: _currentPosition?.latitude ?? AppConfig.defaultLatitude,
          longitude: _currentPosition?.longitude ?? AppConfig.defaultLongitude,
          radiusKm: AppConfig.defaultRadiusKm,
        )),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Issues Map'),
          actions: [
            IconButton(
              icon: const Icon(Icons.my_location),
              onPressed: _getCurrentLocation,
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.filter_list),
              onSelected: (value) {
                // Filter by category
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'all',
                  child: Text('All Issues'),
                ),
                const PopupMenuItem(
                  value: 'water_leakage',
                  child: Text('Water Leakage'),
                ),
                const PopupMenuItem(
                  value: 'street_light',
                  child: Text('Street Light'),
                ),
                const PopupMenuItem(
                  value: 'garbage',
                  child: Text('Garbage'),
                ),
                const PopupMenuItem(
                  value: 'road_damage',
                  child: Text('Road Damage'),
                ),
              ],
            ),
          ],
        ),
        body: BlocConsumer<ComplaintsBloc, ComplaintsState>(
          listener: (context, state) {
            if (state is ComplaintsLoaded) {
              _updateMarkers(state.complaints);
            }
          },
          builder: (context, state) {
            if (_isLoading) {
              return const LoadingIndicator(message: 'Loading map...');
            }

            return Stack(
              children: [
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      _currentPosition?.latitude ?? AppConfig.defaultLatitude,
                      _currentPosition?.longitude ?? AppConfig.defaultLongitude,
                    ),
                    zoom: 14,
                  ),
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                ),

                // Loading overlay
                if (state is ComplaintsLoading)
                  Positioned(
                    top: 16,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text('Loading issues...'),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Legend
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _LegendItem(color: AppColors.waterLeakage, label: 'Water'),
                        _LegendItem(color: AppColors.streetLight, label: 'Light'),
                        _LegendItem(color: AppColors.garbage, label: 'Garbage'),
                        _LegendItem(color: AppColors.lawAndOrder, label: 'Law'),
                        _LegendItem(color: AppColors.roadDamage, label: 'Road'),
                      ],
                    ),
                  ),
                ),

                // Selected complaint card
                if (_selectedComplaint != null)
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: _ComplaintCard(
                      complaint: _selectedComplaint!,
                      onClose: () => setState(() => _selectedComplaint = null),
                    ),
                  ),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            final bloc = context.read<ComplaintsBloc>();
            bloc.add(ComplaintsLoadNearby(
              latitude: _currentPosition?.latitude ?? AppConfig.defaultLatitude,
              longitude: _currentPosition?.longitude ?? AppConfig.defaultLongitude,
              radiusKm: AppConfig.defaultRadiusKm,
            ));
          },
          child: const Icon(Icons.refresh),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _ComplaintCard extends StatelessWidget {
  final Complaint complaint;
  final VoidCallback onClose;

  const _ComplaintCard({
    required this.complaint,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    complaint.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onClose,
                ),
              ],
            ),
            Text(
              complaint.category.displayName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              complaint.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                StatusChip(
                  label: complaint.status.displayName,
                  color: _getStatusColor(complaint.status),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    // Navigate to detail
                  },
                  child: const Text('View Details'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(ComplaintStatus status) {
    switch (status) {
      case ComplaintStatus.pending:
        return AppColors.pending;
      case ComplaintStatus.inProgress:
        return AppColors.inProgress;
      case ComplaintStatus.resolved:
        return AppColors.resolved;
      default:
        return AppColors.textSecondary;
    }
  }
}
