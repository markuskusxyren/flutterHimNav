import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'navigation_page.dart';

final _firestore = FirebaseFirestore.instance;

void main() {
  runApp(const MaterialApp(
    home: VisitorMapPage(),
  ));
}

class VisitorMapPage extends StatefulWidget {
  const VisitorMapPage({Key? key}) : super(key: key);

  @override
  State<VisitorMapPage> createState() => _VisitorMapPageState();
}

class _VisitorMapPageState extends State<VisitorMapPage> {
  List<Map<String, dynamic>> allTombs = [];
  String? selectedUnitId;
  List<double>? selectedCoords;
  String? selectedAvailedUnitId;
  String dropdownValue = 'Tomb';
  String? searchAll;
  bool reservedByCurrentUser = false;
  String? selectedAllTombId;

  @override
  void initState() {
    super.initState();
    getTombs();
  }

  String? searchAvailable;

  Future<void> getTombs() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final tombSnapshot = await _firestore.collection('tombs').get();
      final deceasedSnapshot = await _firestore.collection('deceased').get();

      setState(() {
        allTombs = tombSnapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data();
          List<double> coords = data.containsKey('coords')
              ? List<double>.from(data['coords'])
              : [];
          String tomb = data['tomb'] ?? '';
          bool isAvailable = data['isAvailable'] ?? false;
          String ownerEmail = data['owner_email'] ?? '';
          return {
            "documentID": doc.id,
            "coords": coords,
            "tomb": tomb,
            "isAvailable": isAvailable,
            "owner": ownerEmail,
          };
        }).toList();

        List<Map<String, dynamic>> deceasedList =
            deceasedSnapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data();
          String tomb = data['tomb'] ?? '';
          String name = data['name'] ?? '';
          return {
            'tomb': tomb,
            'name': name,
          };
        }).toList();

        for (var tomb in allTombs) {
          String tombName = tomb['tomb'] ?? '';
          List<String> connectedNames = deceasedList
              .where((deceased) => deceased['tomb'] == tombName)
              .map((deceased) => deceased['name'] as String)
              .toList();
          tomb['connectedNames'] = connectedNames;
        }
      });
    }
  }

  String? currentUserEmail;

  void getCurrentUserEmail() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      currentUserEmail = user.email;
    }
  }

  @override
  Widget build(BuildContext context) {
    getCurrentUserEmail(); // Get current user email on build

    List<Map<String, dynamic>> allTombsFiltered = allTombs.where((tomb) {
      String tombName = tomb['tomb'] ?? '';
      List<String> connectedNames = tomb['connectedNames'] ?? [];

      return tombName.toLowerCase().contains(searchAll?.toLowerCase() ?? '') ||
          connectedNames.any((name) =>
              name.toLowerCase().contains(searchAll?.toLowerCase() ?? ''));
    }).toList();

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              floating: true,
              elevation: 0, // Add this line to remove the shadow
              title: const Text(
                'Visitor Map',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              leading: IconButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.arrow_back),
                color: Colors.black,
              ),
              backgroundColor: Colors.white,
            ),
            SliverAppBar(
              pinned: true,
              toolbarHeight: 80,
              backgroundColor: const Color.fromARGB(255, 255, 255, 255),
              automaticallyImplyLeading: false, // Remove the back button
              flexibleSpace: Column(
                children: [
                  const SizedBox(height: 10),
                  PreferredSize(
                    preferredSize: Size.zero,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: TextField(
                        onChanged: (value) {
                          setState(() {
                            searchAll = value;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: "Search",
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(10.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  [
                    ...(allTombsFiltered.isNotEmpty
                        ? allTombsFiltered.map<Widget>((tomb) {
                            return ListTile(
                              tileColor: selectedUnitId == tomb["tomb"]
                                  ? Colors.lightBlueAccent
                                  : null,
                              title: Text(tomb["tomb"]),
                              subtitle: tomb['connectedNames'] != null &&
                                      tomb['connectedNames'].isNotEmpty
                                  ? Text(
                                      'Deceased: ${tomb['connectedNames'].join(", ")}')
                                  : null,
                              onTap: () {
                                setState(() {
                                  selectedUnitId = tomb["tomb"];
                                  selectedCoords = tomb["coords"];
                                  selectedAllTombId = tomb[
                                      "documentID"]; // Set selected tomb ID
                                });
                              },
                            );
                          }).toList()
                        : [
                            const SizedBox(height: 5),
                            const Text("    Nothing to see here"),
                            const SizedBox(height: 5),
                          ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (selectedCoords != null) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => NavigationScreen(
                  selectedCoords![0], // Pass the latitude from coords
                  selectedCoords![1], // Pass the longitude from coords
                ),
              ),
            );
          } else {
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text('No Tomb Selected'),
                  content: const Text(
                      'Please select a tomb to get directions to it.'),
                  actions: <Widget>[
                    TextButton(
                      child: const Text('Close'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                );
              },
            );
          }
        },
        child: const Icon(Icons.directions),
      ),
    );
  }
}
