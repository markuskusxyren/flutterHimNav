// ignore_for_file: use_build_context_synchronously

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:himlayang_nav/pages/login_page.dart';
import 'package:intl/intl.dart';

import 'client_home_page.dart';

class ExpiredItem {
  final String name;
  final DateTime expiryDate;

  ExpiredItem(this.name, this.expiryDate);
}

class AdminDashboardPage extends StatelessWidget {
  final String userEmail;

  const AdminDashboardPage(this.userEmail, {Key? key}) : super(key: key);

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

  Future<Map<String, int>> getCategoryCounts() async {
    final snapshot = await FirebaseFirestore.instance.collection('tombs').get();
    final Map<String, int> categoryCounts = {};

    for (var doc in snapshot.docs) {
      final tomb = doc['tomb'] as String?;

      if (tomb != null) {
        final category = tomb.substring(0, 2);

        if (categoryCounts.containsKey(category)) {
          categoryCounts[category] = categoryCounts[category]! + 1;
        } else {
          categoryCounts[category] = 1;
        }
      }
    }

    return categoryCounts;
  }

  Future<Map<String, double>> getAvailableUnavailableRatio() async {
    final snapshot = await FirebaseFirestore.instance.collection('tombs').get();

    int available = 0;
    int unavailable = 0;

    for (var doc in snapshot.docs) {
      if (doc['isAvailable'] == true) {
        available++;
      } else {
        unavailable++;
      }
    }

    return {
      'Available': available.toDouble(),
      'Unavailable': unavailable.toDouble(),
    };
  }

  Future<Map<String, dynamic>> getNearingExpiryDetails() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('deceased').get();
    final currentDate = DateTime.now();
    DateTime? oldestExpiry;
    String? nearestName;

    for (var doc in snapshot.docs) {
      final graveAvailDate = doc['grave_avail_date'] as Timestamp?;
      final name = doc['name'] as String?;

      if (graveAvailDate != null && name != null) {
        final expiryDate =
            graveAvailDate.toDate().add(const Duration(days: 5 * 365));

        if (expiryDate.isBefore(currentDate)) {
          if (oldestExpiry == null || expiryDate.isBefore(oldestExpiry)) {
            oldestExpiry = expiryDate;
            nearestName = name;
          }
        }
      }
    }

    return {
      'oldestExpiry': oldestExpiry,
      'nearestName': nearestName,
    };
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
      final tomb = doc['tomb'] as String?;

      if (tomb != null) {
        final category = tomb.substring(0, 2);

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
        child: GridView.count(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          padding: const EdgeInsets.all(20),
          crossAxisCount:
              MediaQuery.of(context).orientation == Orientation.portrait
                  ? 2
                  : 2,
          children: [
            GestureDetector(
              onTap: () async {
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
                        height: MediaQuery.of(context).size.height *
                            0.5, // This line sets the height to 50% of screen height
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Forefeited Lots',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16.0),
                              Expanded(
                                child: FutureBuilder<List<ExpiredItem>>(
                                  future: getExpiredItems(),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      final expiredItems = snapshot.data!;
                                      return ListView.builder(
                                        itemCount: expiredItems.length,
                                        itemBuilder: (context, index) {
                                          final item = expiredItems[index];
                                          final formattedExpiryDate =
                                              DateFormat('yyyy-MM-dd')
                                                  .format(item.expiryDate);
                                          return ListTile(
                                            title: Text(item.name),
                                            subtitle: Text(
                                                'Forefeiture Date: $formattedExpiryDate'),
                                          );
                                        },
                                      );
                                    } else if (snapshot.hasError) {
                                      return Text('Error: ${snapshot.error}');
                                    } else {
                                      return const Center(
                                        child: SizedBox(
                                          width: 50,
                                          height: 50,
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                                    }
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
                      Icon(Icons.person, size: 50),
                      Text(
                        'Forefeited',
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
                      height: MediaQuery.of(context).size.height *
                          0.5, // Set the height to half of the screen height
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 16.0,
                          right: 16.0,
                          top: 16.0,
                          bottom: 0.0, // Set bottom padding to 0
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Lot Chart',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16.0),
                            FutureBuilder<Map<String, double>>(
                              future: getAvailableUnavailableRatio(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  final data = snapshot.data!;
                                  return Expanded(
                                    child: PieChart(
                                      PieChartData(
                                        sectionsSpace: 0,
                                        centerSpaceRadius: 30,
                                        sections: [
                                          PieChartSectionData(
                                            value: data['Available'] ?? 0,
                                            title:
                                                'Available ${data['Available']!.toInt()}',
                                            color: const Color.fromARGB(
                                                255, 122, 122, 122),
                                            titleStyle: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Color.fromARGB(
                                                  255, 204, 204, 204),
                                            ),
                                            radius: 70,
                                          ),
                                          PieChartSectionData(
                                            value: data['Unavailable'] ?? 0,
                                            title:
                                                'Unavailable ${data['Unavailable']!.toInt()}',
                                            color: const Color.fromARGB(
                                                255, 48, 48, 48),
                                            titleStyle: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Color.fromARGB(
                                                  255, 99, 99, 99),
                                            ),
                                            radius: 80,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                } else if (snapshot.hasError) {
                                  return Text('Error: ${snapshot.error}');
                                } else {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }
                              },
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
                      Icon(Icons.pie_chart, size: 50),
                      Text(
                        'Lot Chart',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
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
                      height: MediaQuery.of(context).size.height * 0.455,
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 16.0,
                          right: 16.0,
                          top: 16.0,
                          bottom: 0.0,
                        ),
                        child: SingleChildScrollView(
                          // Wrap the Column with SingleChildScrollView
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Category Chart',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16.0),
                              FutureBuilder<Map<String, int>>(
                                future: getCategoryCounts(),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData) {
                                    final categoryCounts = snapshot.data!;
                                    final categories =
                                        categoryCounts.keys.toList();
                                    final counts =
                                        categoryCounts.values.toList();

                                    return CategoryChart(
                                      categories: categories,
                                      counts: counts,
                                    );
                                  } else if (snapshot.hasError) {
                                    return Text('Error: ${snapshot.error}');
                                  } else {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }
                                },
                              ),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text('Close'),
                                  ),
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
                      Icon(Icons.bar_chart, size: 50),
                      Text(
                        'Category Chart',
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
              onTap: () async {
                // Query Firestore for users with isVerified set to false
                final snapshot = await FirebaseFirestore.instance
                    .collection('userID')
                    .where('isVerified', isEqualTo: false)
                    .get();

                // Map the documents to their email field
                final unverifiedEmails = snapshot.docs
                    .map((doc) => doc.data()['email'] as String)
                    .toList();

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
                      height: MediaQuery.of(context).size.height *
                          0.5, // Set the height to half of the screen height
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 16.0,
                          right: 16.0,
                          top: 16.0,
                          bottom: 0.0, // Set bottom padding to 0
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Unverified Emails',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16.0),
                            Expanded(
                              child: ListView.separated(
                                itemCount: unverifiedEmails.length,
                                separatorBuilder:
                                    (BuildContext context, int index) =>
                                        const SizedBox(height: 10.0),
                                itemBuilder: (BuildContext context, int index) {
                                  return Text(
                                    unverifiedEmails[index],
                                    style: const TextStyle(
                                      fontSize: 16,
                                    ),
                                  );
                                },
                              ),
                            ),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('Close'),
                                ),
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
                      Icon(Icons.email, size: 50),
                      Text(
                        'Unverified Emails',
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
                      height: MediaQuery.of(context).size.height *
                          0.5, // Set the height to half of the screen height
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 16.0,
                          right: 16.0,
                          top: 16.0,
                          bottom: 0.0, // Set bottom padding to 0
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Recent Records',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16.0),
                            Expanded(
                              child: FutureBuilder<List<String>>(
                                future: getRecentDeceasedRecords(),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData) {
                                    final recentRecords = snapshot.data!;
                                    return ListView.builder(
                                      itemCount: recentRecords.length,
                                      itemBuilder: (context, index) {
                                        final record = recentRecords[index];
                                        return ListTile(
                                          title: Text(record),
                                        );
                                      },
                                    );
                                  } else if (snapshot.hasError) {
                                    return Text('Error: ${snapshot.error}');
                                  } else {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }
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
                      Icon(Icons.history, size: 50),
                      Text(
                        'Recent Records',
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
                              'Lot Markers',
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
                        'Lot Markers',
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(
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
              Center(
                child: responsiveGridDashboard(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CategoryChart extends StatelessWidget {
  final List<String> categories;
  final List<int> counts;

  const CategoryChart({
    required this.categories,
    required this.counts,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      padding: const EdgeInsets.symmetric(vertical: 0),
      child: Center(
        child: ListView.builder(
          shrinkWrap: true,
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          itemBuilder: (BuildContext context, int index) {
            final category = categories[index];
            final count = counts[index];

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 5),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    category,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 0),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10.0),
                    child: Container(
                      height: 110,
                      width: 35,
                      color: const Color.fromARGB(
                          255, 156, 156, 156), // Customize the color as needed
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: count / counts.reduce((a, b) => a + b),
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8.0),
                              topRight: Radius.circular(8.0),
                            ),
                            child: Container(
                              color: const Color.fromARGB(255, 59, 59,
                                  59), // Customize the color as needed
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    count.toString(),
                    style: const TextStyle(
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin Dashboard',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LoginPage(),
    );
  }
}

Future<List<String>> getRecentDeceasedRecords() async {
  final snapshot = await FirebaseFirestore.instance
      .collection('deceased')
      .orderBy('createdAt', descending: true)
      .limit(5)
      .get();

  final recentRecords =
      snapshot.docs.map((doc) => doc['name'] as String).toList();

  return recentRecords;
}

Widget _buildMap() {
  GoogleMapController? mapController;

  return GestureDetector(
    onPanUpdate: (details) {
      if (details.delta.dy < 0) {
        // Zoom in when the user swipes up
        mapController?.animateCamera(CameraUpdate.zoomIn());
      } else if (details.delta.dy > 0) {
        // Zoom out when the user swipes down
        mapController?.animateCamera(CameraUpdate.zoomOut());
      }
    },
    child: StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('tombs').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final currentUserEmail = FirebaseAuth.instance.currentUser?.email;
          final markers = snapshot.data!.docs
              .map((doc) {
                final tombID = doc['tomb'] as String?;
                final coords = doc['coords'] as List<dynamic>?;
                final isAvailable = doc['isAvailable'] as bool?;
                final ownerEmail = doc['owner_email'] as String?;

                if (tombID != null &&
                    coords != null &&
                    coords.length >= 2 &&
                    isAvailable == true) {
                  final lat = coords[0] as double;
                  final lng = coords[1] as double;

                  final markerColor = ownerEmail == currentUserEmail
                      ? BitmapDescriptor.hueBlue
                      : (ownerEmail == null || ownerEmail.isEmpty
                          ? BitmapDescriptor.hueRed
                          : null);

                  if (markerColor != null) {
                    return Marker(
                      markerId: MarkerId(tombID),
                      position: LatLng(lat, lng),
                      icon: BitmapDescriptor.defaultMarkerWithHue(markerColor),
                      infoWindow: InfoWindow(
                        title: tombID,
                        snippet: 'owner_email: ${ownerEmail ?? ''}',
                      ),
                    );
                  }
                }

                return null;
              })
              .whereType<Marker>()
              .toSet();

          // Legends
          final legends = [
            LegendItem(color: Colors.red, label: 'Available'),
          ];

          return Stack(
            children: [
              GoogleMap(
                markers: markers,
                onMapCreated: (GoogleMapController controller) {
                  mapController = controller;
                  // You can perform additional map setup here if needed
                },
                initialCameraPosition: const CameraPosition(
                  target: LatLng(14.683531742290285, 121.05322763852632),
                  zoom: 16.0,
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: Column(
                  children: legends
                      .map((legend) => Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                color: legend.color,
                              ),
                              const SizedBox(width: 8),
                              Text(legend.label),
                            ],
                          ))
                      .toList(),
                ),
              ),
            ],
          );
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    ),
  );
}
