import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:himi_navi_rec/pages/login_page.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ExpiredItem {
  final String name;
  final DateTime expiryDate;

  ExpiredItem(this.name, this.expiryDate);
}

class ClientDashboardPage extends StatelessWidget {
  final String userEmail;

  const ClientDashboardPage(this.userEmail, {Key? key}) : super(key: key);

  void signUserOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmation'),
          content: const Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                FirebaseAuth.instance.signOut().then((_) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                    (route) => false,
                  );
                }).catchError((error) {});

                Navigator.of(context).pop();
              },
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _getAvailedTombs() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final currentUserEmail = currentUser?.email;

    if (currentUserEmail == null) {
      return [];
    }

    final tombSnapshot = await FirebaseFirestore.instance
        .collection('tombs')
        .where('owner', isEqualTo: currentUserEmail)
        .get();

    final availedTombs = tombSnapshot.docs.map((doc) {
      final tombID = doc['unitID'] as String;
      return {
        'tombID': tombID,
      };
    }).toList();

    final tombIDs =
        availedTombs.map((tomb) => tomb['tombID'] as String).toList();

    if (tombIDs.isEmpty) {
      return [];
    }

    final deceasedSnapshot = await FirebaseFirestore.instance
        .collection('deceased')
        .where('tomb', whereIn: tombIDs)
        .get();

    final tombDetails = availedTombs.map((tomb) {
      final tombID = tomb['tombID'] as String;
      final matchingDeceased = deceasedSnapshot.docs.firstWhere(
        (doc) => doc['tomb'] == tombID,
      );

      final graveAvailDate = matchingDeceased['grave_avail_date'] as Timestamp?;

      final expiryDate =
          graveAvailDate?.toDate().add(const Duration(days: 5 * 365));

      return {
        'tombID': tombID,
        'graveAvailDate': graveAvailDate,
        'expiryDate': expiryDate,
      };
    }).toList();

    return tombDetails;
  }

  Future<DateTime?> getOldestGraveAvailDate() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('deceased').get();
    DateTime? oldestDate;

    for (var doc in snapshot.docs) {
      final graveAvailDate = doc['grave_avail_date'] as Timestamp?;

      if (graveAvailDate != null) {
        final date = graveAvailDate.toDate();

        if (oldestDate == null || date.isBefore(oldestDate)) {
          oldestDate = date;
        }
      }
    }

    return oldestDate;
  }

  Future<List<ExpiredItem>> getExpiredItems() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('deceased').get();
    final currentDate = DateTime.now();
    final List<ExpiredItem> expiredItems = [];

    for (var doc in snapshot.docs) {
      final graveAvailDate = doc['grave_avail_date'] as Timestamp?;
      final name = doc['name'] as String?;

      if (graveAvailDate != null && name != null) {
        final expiryDate =
            graveAvailDate.toDate().add(const Duration(days: 5 * 365));

        if (expiryDate.isBefore(currentDate)) {
          expiredItems.add(ExpiredItem(name, expiryDate));
        }
      }
    }

    return expiredItems;
  }

  Future<Map<String, int>> getTombCounts() async {
    final snapshot = await FirebaseFirestore.instance.collection('tombs').get();
    final Map<String, int> tombCounts = {};

    for (var doc in snapshot.docs) {
      final unitID = doc['unitID'] as String?;

      if (unitID != null) {
        final category = unitID.substring(0, 2);

        if (tombCounts.containsKey(category)) {
          tombCounts[category] = tombCounts[category]! + 1;
        } else {
          tombCounts[category] = 1;
        }
      }
    }

    return tombCounts;
  }

  Widget responsiveGridDashboard(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              GridView.count(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                padding: const EdgeInsets.all(70),
                crossAxisCount:
                    MediaQuery.of(context).orientation == Orientation.portrait
                        ? 1
                        : 2,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final List<Map<String, dynamic>> availedTombs =
                          await _getAvailedTombs();
                      // ignore: use_build_context_synchronously
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20.0),
                            topRight: Radius.circular(20.0),
                          ),
                        ),
                        builder: (BuildContext context) {
                          return SafeArea(
                            child: SizedBox(
                              height: MediaQuery.of(context).size.height * 0.5,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const Text(
                                      'Tomb Tracker',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 16.0),
                                    Expanded(
                                      child: availedTombs.isEmpty
                                          ? const Center(
                                              child: Text(
                                                'No availed tombs.',
                                                style:
                                                    TextStyle(fontSize: 16.0),
                                              ),
                                            )
                                          : ListView.builder(
                                              shrinkWrap: true,
                                              physics:
                                                  const NeverScrollableScrollPhysics(),
                                              itemCount: availedTombs.length,
                                              itemBuilder: (context, index) {
                                                final tomb = availedTombs[index]
                                                    ['tombID'] as String;
                                                final graveAvailDate =
                                                    availedTombs[index]
                                                            ['graveAvailDate']
                                                        as Timestamp;
                                                final expiryDate =
                                                    availedTombs[index]
                                                            ['expiryDate']
                                                        as DateTime?;
                                                final formattedPurchaseDate =
                                                    DateFormat('yyyy-MM-dd')
                                                        .format(graveAvailDate
                                                            .toDate());
                                                final formattedExpiryDate =
                                                    expiryDate != null
                                                        ? DateFormat(
                                                                'yyyy-MM-dd')
                                                            .format(expiryDate)
                                                        : 'N/A';

                                                return ListTile(
                                                  title: Text(tomb),
                                                  subtitle: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                          'Purchase Date: $formattedPurchaseDate'),
                                                      Text(
                                                          'Expiry Date: $formattedExpiryDate'),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: ElevatedButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text('Close'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                    child: Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.calendar_month, size: 50),
                            Text(
                              'Tomb Tracker',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20.0),
                            topRight: Radius.circular(20.0),
                          ),
                        ),
                        builder: (BuildContext context) {
                          return SizedBox(
                            height: MediaQuery.of(context).size.height * 0.7,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                left: 16.0,
                                right: 16.0,
                                top: 16.0,
                                bottom: 0.0,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Tomb Markers',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16.0),
                                  Expanded(
                                    child: _buildMap(),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text('Close'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                    child: Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.map, size: 50),
                            Text(
                              'Tomb Markers',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMap() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('tombs').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final markers = snapshot.data!.docs
              .where((doc) =>
                  doc['owner'] == FirebaseAuth.instance.currentUser?.email)
              .map((doc) {
                final tombID = doc['unitID'] as String?;
                final coords = doc['coords'] as List<dynamic>?;

                if (tombID != null && coords != null && coords.length >= 2) {
                  final lat = coords[0] as double;
                  final lng = coords[1] as double;

                  return Marker(
                    markerId: MarkerId(tombID),
                    position: LatLng(lat, lng),
                    infoWindow: InfoWindow(
                      title: tombID,
                      snippet: 'Owner: ${doc['owner'] ?? ''}',
                    ),
                  );
                }

                return null;
              })
              .whereType<Marker>()
              .toSet();

          return GoogleMap(
            markers: markers,
            onMapCreated: (GoogleMapController controller) {
              // You can perform additional map setup here if needed
            },
            initialCameraPosition: const CameraPosition(
              target: LatLng(14.683531742290285, 121.05322763852632),
              zoom: 16.0,
            ),
          );
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          return const CircularProgressIndicator();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        userEmail,
                        style: const TextStyle(
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => signUserOut(context),
                    child: Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      child: const Icon(
                        Icons.logout,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: responsiveGridDashboard(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
