import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/trainer_profile.dart';
import '../providers/trainer_discovery_provider.dart';

class TrainerDiscoveryScreen extends ConsumerStatefulWidget {
  const TrainerDiscoveryScreen({super.key});

  @override
  ConsumerState<TrainerDiscoveryScreen> createState() =>
      _TrainerDiscoveryScreenState();
}

class _TrainerDiscoveryScreenState
    extends ConsumerState<TrainerDiscoveryScreen> {
  double _radiusKm = 25;
  Position? _userPosition;
  String? _locationError;
  bool _loadingLocation = true;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        if (!mounted) return;
        setState(() {
          _loadingLocation = false;
          _locationError =
              AppLocalizations.of(context).trainerDiscoveryLocationDenied;
        });
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _userPosition = pos;
        _loadingLocation = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingLocation = false;
        _locationError = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_loadingLocation) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_locationError != null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.trainerDiscoveryTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_off, size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                Text(_locationError!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      _loadingLocation = true;
                      _locationError = null;
                    });
                    _fetchLocation();
                  },
                  child: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final params = NearbyParams(
      lat: _userPosition!.latitude,
      lng: _userPosition!.longitude,
      radiusKm: _radiusKm,
    );
    final asyncTrainers = ref.watch(nearbyTrainersProvider(params));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.trainerDiscoveryTitle)),
      body: Column(
        children: [
          // Radius slider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(l10n.trainerDiscoveryRadiusLabel(_radiusKm.round())),
                Expanded(
                  child: Slider(
                    value: _radiusKm,
                    min: 5,
                    max: 100,
                    divisions: 19,
                    onChanged: (v) => setState(() => _radiusKm = v),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: asyncTrainers.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(e.toString())),
              data: (trainers) => _TrainerResults(
                trainers: trainers,
                userLat: _userPosition!.latitude,
                userLng: _userPosition!.longitude,
                l10n: l10n,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrainerResults extends StatefulWidget {
  const _TrainerResults({
    required this.trainers,
    required this.userLat,
    required this.userLng,
    required this.l10n,
  });

  final List<TrainerProfile> trainers;
  final double userLat;
  final double userLng;
  final AppLocalizations l10n;

  @override
  State<_TrainerResults> createState() => _TrainerResultsState();
}

class _TrainerResultsState extends State<_TrainerResults>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.trainers.isEmpty) {
      return Center(child: Text(widget.l10n.trainerDiscoveryEmpty));
    }

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.map_outlined), text: 'Karte'),
            Tab(icon: Icon(Icons.list_outlined), text: 'Liste'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _MapView(
                trainers: widget.trainers,
                userLat: widget.userLat,
                userLng: widget.userLng,
              ),
              _ListView(trainers: widget.trainers, l10n: widget.l10n),
            ],
          ),
        ),
      ],
    );
  }
}

class _MapView extends StatelessWidget {
  const _MapView({
    required this.trainers,
    required this.userLat,
    required this.userLng,
  });

  final List<TrainerProfile> trainers;
  final double userLat;
  final double userLng;

  @override
  Widget build(BuildContext context) {
    final userLatLng = LatLng(userLat, userLng);

    return FlutterMap(
      options: MapOptions(
        initialCenter: userLatLng,
        initialZoom: 10,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.alexandermessinger.corejourney',
        ),
        MarkerLayer(
          markers: [
            // User location
            Marker(
              point: userLatLng,
              width: 20,
              height: 20,
              child: const Icon(Icons.my_location,
                  color: AppColors.info, size: 20),
            ),
            // Trainer pins (approximate)
            for (final t in trainers)
              if (t.publicLatitude != null && t.publicLongitude != null)
                Marker(
                  point: LatLng(t.publicLatitude!, t.publicLongitude!),
                  width: 36,
                  height: 36,
                  child: GestureDetector(
                    onTap: () => context.push(
                      '/trainers/${t.id}',
                      extra: t,
                    ),
                    child: const Icon(Icons.person_pin_circle,
                        color: AppColors.primary, size: 36),
                  ),
                ),
          ],
        ),
      ],
    );
  }
}

class _ListView extends StatelessWidget {
  const _ListView({required this.trainers, required this.l10n});

  final List<TrainerProfile> trainers;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: trainers.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final t = trainers[i];
        return ListTile(
          leading: t.photoUrl != null
              ? CircleAvatar(backgroundImage: NetworkImage(t.photoUrl!))
              : const CircleAvatar(child: Icon(Icons.person)),
          title: Row(
            children: [
              Text(t.displayName),
              if (t.verified) ...[
                const SizedBox(width: 4),
                const Icon(Icons.verified,
                    color: AppColors.primary, size: 16),
              ],
            ],
          ),
          subtitle: t.distanceKm != null
              ? Text(l10n.trainerDiscoveryDistanceLabel(t.distanceKm!))
              : null,
          onTap: () => context.push('/trainers/${t.id}', extra: t),
        );
      },
    );
  }
}
