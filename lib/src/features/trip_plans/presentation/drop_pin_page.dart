import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Mapbox exports its own `Size`; this file means Flutter's.
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;

import '../../../core/counties/county_boundary_resolver.dart';
import '../../../core/design/app_type_scale.dart';
import '../../../core/services/app_config_provider.dart';
import '../../../core/services/app_mapbox_telemetry.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../design/app_colors.dart';
import '../application/create_plan_controller.dart';
import '../domain/custom_place_draft.dart';
import 'plan_text_input_sheet.dart';

/// Opens the pin page; returns the named pin, or null when backed out.
Future<CustomPlaceDraft?> showDropPinPage(BuildContext context) =>
    Navigator.of(context).push<CustomPlaceDraft>(
      MaterialPageRoute(builder: (_) => const DropPinPage()),
    );

/// Drop a pin: the user moves the map under a fixed pin, taps "Use this
/// spot" and names it. For a stay, a private home or anywhere with no
/// listing.
class DropPinPage extends ConsumerStatefulWidget {
  const DropPinPage({super.key});

  @override
  ConsumerState<DropPinPage> createState() => _DropPinPageState();
}

class _DropPinPageState extends ConsumerState<DropPinPage> {
  // Kenya, until the phone's location is known.
  static const _kenya = (lat: 0.18, lng: 37.9);
  MapboxMap? _map;

  Future<void> _use() async {
    final map = _map;
    if (map == null) return;
    final state = await map.getCameraState();
    final at = state.center.coordinates;
    if (!mounted) return;
    final name = await showPlanTextInput(
      context,
      title: 'Name this place',
      label: 'Name',
      hint: 'Airbnb in Nakuru, Aunt Rose\'s house',
      maxLength: 80,
      action: 'Add',
    );
    if (name == null || !mounted) return;
    final lat = at.lat.toDouble();
    final lng = at.lng.toDouble();
    Navigator.of(context).pop(
      CustomPlaceDraft.pin(
        name: name,
        lat: lat,
        lng: lng,
        countyCode: CountyBoundaryResolver.countyCodeFor(
          latitude: lat,
          longitude: lng,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final near = ref.watch(planCurrentLocationProvider).value;
    final token = ref.watch(appConfigProvider).mapboxAccessToken;
    final lat = near?.latitude ?? _kenya.lat;
    final lng = near?.longitude ?? _kenya.lng;
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: AppColors.pageBackground,
        elevation: 0,
        automaticallyImplyLeading: false,
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Center(
            child: AppBackButton(
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
        ),
        title: const Text('Drop a pin', style: AppTypeScale.sectionTitle),
      ),
      body: Column(
        children: [
          Expanded(
            child: token.isEmpty
                ? const Center(
                    child: Text(
                      'The map is not available here.',
                      style: AppTypeScale.small,
                    ),
                  )
                : Stack(
                    alignment: Alignment.center,
                    children: [
                      MapWidget(
                        key: ValueKey('drop-pin-$lat-$lng'),
                        styleUri: MapboxStyles.OUTDOORS,
                        textureView: true,
                        // ignore: experimental_member_use
                        androidHostingMode:
                            AndroidPlatformViewHostingMode.TLHC_HC,
                        viewport: CameraViewportState(
                          center: Point(coordinates: Position(lng, lat)),
                          zoom: near == null ? 5.5 : 13,
                        ),
                        gestureRecognizers: {
                          const Factory<OneSequenceGestureRecognizer>(
                            EagerGestureRecognizer.new,
                          ),
                        },
                        onMapCreated: (map) {
                          _map = map;
                          unawaited(AppMapboxTelemetry.applyPrivacyDefault());
                          unawaited(
                            map.scaleBar.updateSettings(
                              ScaleBarSettings(enabled: false),
                            ),
                          );
                        },
                      ),
                      // The pin's tip sits on the map's centre.
                      const IgnorePointer(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 36),
                          child: Icon(
                            Icons.location_on,
                            size: 44,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Move the map until the pin is on the spot. Anyone on '
                    'this plan will see it.',
                    textAlign: TextAlign.center,
                    style: AppTypeScale.small,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: AppTypeScale.action,
                      ),
                      onPressed: token.isEmpty ? null : () => unawaited(_use()),
                      child: const Text('Use this spot'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
