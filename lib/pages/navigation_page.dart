import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:location/location.dart' as loc;
import 'package:location/location.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' show cos, sqrt, asin;
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

  @override
  void initState() {
    super.initState();
    getNavigation();
    addMarker();
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
                      controller.animateCamera(
                        CameraUpdate.newLatLngZoom(
                          curLocation,
                          16.0,
                        ),
                      );
                      isMapInitialized = true;
                    }
                  },
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

  getNavigation() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;
    final GoogleMapController controller = await _controller.future;
    location.changeSettings(accuracy: loc.LocationAccuracy.high);
    serviceEnabled = await location.serviceEnabled();

    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    // Modify the permission check block
    permissionGranted = await location.hasPermission();
    if (permissionGranted != PermissionStatus.granted) {
      // Permission not granted, request permission
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        // Permission denied, handle accordingly
        // Display a dialog or show a message to the user
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
    }

    isLocationPermissionGranted = true;

    _currentPosition = await location.getLocation();
    curLocation = LatLng(
      _currentPosition!.latitude!,
      _currentPosition!.longitude!,
    );
    locationSubscription =
        location.onLocationChanged.listen((LocationData currentLocation) {
      if (mounted) {
        controller
            .showMarkerInfoWindow(MarkerId(sourcePosition!.markerId.value));
        setState(() {
          curLocation = LatLng(
            currentLocation.latitude!,
            currentLocation.longitude!,
          );
          sourcePosition = Marker(
            markerId: MarkerId(currentLocation.toString()),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueBlue,
            ),
            position: LatLng(
              currentLocation.latitude!,
              currentLocation.longitude!,
            ),
            infoWindow: InfoWindow(
              title:
                  '${double.parse((getDistance(LatLng(widget.lat, widget.lng)).toStringAsFixed(2)))} km',
            ),
          );
        });
        getDirections(LatLng(widget.lat, widget.lng));
      }
    });
  }

  getDirections(LatLng dst) async {
    if (!isLocationPermissionGranted) {
      return;
    }

    List<LatLng> polylineCoordinates = [];
    List<dynamic> points = [];
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      'AIzaSyCKPYZdoTx6j_6dVZu1MwtTt1Kzfr9h668',
      PointLatLng(curLocation.latitude, curLocation.longitude),
      PointLatLng(dst.latitude, dst.longitude),
      travelMode: TravelMode.driving,
    );
    if (result.points.isNotEmpty) {
      for (var point in result.points) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        points.add({'lat': point.latitude, 'lng': point.longitude});
      }
    }
    addPolyLine(polylineCoordinates);
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

  addMarker() {
    setState(() {
      sourcePosition = Marker(
        markerId: const MarkerId('source'),
        position: curLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      );
      destinationPosition = Marker(
        markerId: const MarkerId('destination'),
        position: LatLng(widget.lat, widget.lng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
      );
    });
  }
}
