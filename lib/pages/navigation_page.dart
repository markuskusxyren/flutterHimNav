import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:location/location.dart' as loc;
import 'package:location/location.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' show asin, cos, max, min, sqrt;
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future main() async {
  await dotenv.load(fileName: ".env");
}

String? api = dotenv.env['GOOGLE_API_KEY'];

class NavigationScreen extends StatefulWidget {
  final double lat;
  final double lng;
  const NavigationScreen(this.lat, this.lng, {Key? key}) : super(key: key);

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  Map<PolylineId, Polyline> polylines = {};
  PolylinePoints polylinePoints = PolylinePoints();
  Location location = Location();
  Marker? sourcePosition, destinationPosition;
  loc.LocationData? _currentPosition;
  LatLng curLocation = const LatLng(14.682569991056297, 121.0524150628587);
  StreamSubscription<loc.LocationData>? locationSubscription;
  bool isFirstLocationUpdate = true;
  bool isMapInitialized = false;
  bool isLocationPermissionGranted = false;
  bool shouldAnimateToCurrentLocation = true;

  @override
  void initState() {
    super.initState();
    checkPermissions();
    addMarker(LatLng(widget.lat, widget.lng));

    // Retrieve current location and assign it to curLocation
    locationSubscription =
        location.onLocationChanged.listen((loc.LocationData locationData) {
      if (mounted) {
        setState(() {
          curLocation = LatLng(
            locationData.latitude!,
            locationData.longitude!,
          );
          updateCurrentLocationMarker();
        });
      }
    });
  }

  void updateCurrentLocationMarker() {
    if (sourcePosition != null) {
      setState(() {
        sourcePosition = sourcePosition!.copyWith(
          positionParam: curLocation,
        );
      });
    }
  }

  Future<void> checkPermissions() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    location.changeSettings(accuracy: loc.LocationAccuracy.high);
    serviceEnabled = await location.serviceEnabled();

    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted != PermissionStatus.granted) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Location Permission Denied'),
                content: const Text(
                  'You have denied the location permission. Some features of the app may not work correctly.',
                ),
                actions: [
                  TextButton(
                    child: const Text('OK'),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              );
            },
          );
        }
        return;
      }
      isLocationPermissionGranted = true;
      await getNavigation();
    }

    isLocationPermissionGranted = true;

    // Retrieve current location
    _currentPosition = await location.getLocation();
    if (_currentPosition != null) {
      curLocation = LatLng(
        _currentPosition!.latitude!,
        _currentPosition!.longitude!,
      );
      updateCurrentLocationMarker();
      if (!isMapInitialized) {
        // Delay the animation for 1.5 seconds
        if (shouldAnimateToCurrentLocation) {
          await Future.delayed(const Duration(milliseconds: 1500));
          shouldAnimateToCurrentLocation = false;
          // Zoom out to show both markers
          final GoogleMapController controller = await _controller.future;
          controller.animateCamera(
            CameraUpdate.newLatLngBounds(
              LatLngBounds(
                southwest: LatLng(
                  min(curLocation.latitude, widget.lat),
                  min(curLocation.longitude, widget.lng),
                ),
                northeast: LatLng(
                  max(curLocation.latitude, widget.lat),
                  max(curLocation.longitude, widget.lng),
                ),
              ),
              100, // padding
            ),
          );
        }
        isMapInitialized = true;
      }
    } else {
      // Handle case when current location is not available
      if (mounted) {
        (showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Location Not Available'),
              content: const Text(
                'Unable to retrieve current location. Please try again.',
              ),
              actions: [
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            );
          },
        ));
      }
    }

    getNavigation();
  }

  @override
  void dispose() {
    locationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: sourcePosition == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  zoomControlsEnabled: false,
                  polylines: Set<Polyline>.of(polylines.values),
                  initialCameraPosition: CameraPosition(
                    target: curLocation,
                    zoom: 16,
                  ),
                  markers: {sourcePosition!, destinationPosition!},
                  onMapCreated: (GoogleMapController controller) async {
                    _controller.complete(controller);
                    _currentPosition = await location.getLocation();
                    curLocation = LatLng(
                      _currentPosition!.latitude!,
                      _currentPosition!.longitude!,
                    );

                    if (!isMapInitialized) {
                      // Delay the animation for 1.5 seconds
                      if (shouldAnimateToCurrentLocation) {
                        await Future.delayed(
                            const Duration(milliseconds: 1500));
                        shouldAnimateToCurrentLocation = false;
                        // Zoom out to show both markers
                        controller.animateCamera(
                          CameraUpdate.newLatLngBounds(
                            LatLngBounds(
                              southwest: LatLng(
                                min(curLocation.latitude, widget.lat),
                                min(curLocation.longitude, widget.lng),
                              ),
                              northeast: LatLng(
                                max(curLocation.latitude, widget.lat),
                                max(curLocation.longitude, widget.lng),
                              ),
                            ),
                            100, // padding
                          ),
                        );
                      }

                      isMapInitialized = true;
                    }
                  },
                ),
                Positioned(
                  top: 16,
                  left: 5,
                  child: SafeArea(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.5),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue,
                    ),
                    child: Center(
                      child: IconButton(
                        icon: const Icon(
                          Icons.navigation_outlined,
                          color: Colors.white,
                        ),
                        onPressed: () async {
                          await launchUrl(Uri.parse(
                              'google.navigation:q=${widget.lat}, ${widget.lng}&key=AIzaSyCKPYZdoTx6j_6dVZu1MwtTt1Kzfr9h668'));
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> getNavigation() async {
    PolylinePoints polylinePoints = PolylinePoints();
    List<LatLng> polylineCoordinates = [];

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      api!,
      PointLatLng(curLocation.latitude, curLocation.longitude),
      PointLatLng(widget.lat, widget.lng),
      travelMode: TravelMode.driving,
    );

    if (result.points.isNotEmpty) {
      for (var point in result.points) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }
    }

    setState(() {
      Polyline polyline = Polyline(
        polylineId: const PolylineId('route'),
        color: Colors.blue,
        points: polylineCoordinates,
        width: 5,
      );

      polylines[const PolylineId('route')] = polyline;
    });
  }

  getDirections(LatLng dst) async {
    List<LatLng> polylineCoordinates = [];
    List<dynamic> points = [];
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      api!,
      PointLatLng(curLocation.latitude, curLocation.longitude),
      PointLatLng(dst.latitude, dst.longitude),
      travelMode: TravelMode.driving,
    );
    if (result.points.isNotEmpty) {
      for (var point in result.points) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        points.add({'lat': point.latitude, 'lng': point.longitude});
      }
    } else {}
    addPolyLine(polylineCoordinates);
    addMarker(dst); // Add the destination marker to the map
  }

  addPolyLine(List<LatLng> polylineCoordinates) {
    PolylineId id = const PolylineId('poly');
    Polyline polyline = Polyline(
      polylineId: id,
      color: Colors.blue,
      points: polylineCoordinates,
      width: 5,
    );
    polylines[id] = polyline;
    setState(() {});
  }

  double calculateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  double getDistance(LatLng destposition) {
    return calculateDistance(
      curLocation.latitude,
      curLocation.longitude,
      destposition.latitude,
      destposition.longitude,
    );
  }

  addMarker(LatLng destination) {
    setState(() {
      sourcePosition = Marker(
        markerId: const MarkerId('source'),
        position: curLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      );
      destinationPosition = Marker(
        markerId: const MarkerId('destination'),
        position: destination,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
      );
    });
  }
}
