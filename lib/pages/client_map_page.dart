import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'navigation_page.dart';

final _firestore = FirebaseFirestore.instance;

void main() {
  runApp(const MaterialApp(
    home: ClientMapPage(),
  ));
}

class ClientMapPage extends StatefulWidget {
  const ClientMapPage({Key? key}) : super(key: key);

  @override
  State<ClientMapPage> createState() => _ClientMapPageState();
}

class _ClientMapPageState extends State<ClientMapPage> {
  List<Map<String, dynamic>> tombs = [];
  String? selectedUnitId;
  List<double>? selectedCoords;
  String? selectedAvailedUnitId;
  String dropdownValue = 'Unit ID';

  @override
  void initState() {
    super.initState();
    getTombs();
  }

  String? searchAvailable;

  bool availablePanelExpanded = false;
  bool availedPanelExpanded = false;

  void getTombs() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _firestore
          .collection('tombs')
          .snapshots()
          .listen((QuerySnapshot querySnapshot) {
        setState(() {
          tombs = querySnapshot.docs.map((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            List<double> coords = data.containsKey('coords')
                ? List<double>.from(data['coords'])
                : [];
            String tomb = data['tomb'] ?? '';
            bool isAvailable = data['isAvailable'] ?? false;
            String ownerEmail = data['owner_email'] ?? '';
            return {
              "documentID": doc.id,
              "coords": coords,
              "unitID": tomb,
              "isAvailable": isAvailable,
              "owner": ownerEmail,
            };
          }).toList();

          selectedUnitId = tombs.isNotEmpty ? null : null;
        });
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

    List<Map<String, dynamic>> availableTombs = tombs
        .where((tomb) =>
            tomb['isAvailable'] &&
            (searchAvailable == null ||
                searchAvailable!.isEmpty ||
                (dropdownValue == 'Unit ID'
                    ? tomb['unitID']
                        .toLowerCase()
                        .contains(searchAvailable!.toLowerCase())
                    : tomb['owner']
                        .toLowerCase()
                        .contains(searchAvailable!.toLowerCase()))))
        .toList();

    List<Map<String, dynamic>> availedTombs = tombs
        .where(
            (tomb) => !tomb['isAvailable'] && tomb['owner'] == currentUserEmail)
        .toList();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                children: [
                  ExpansionPanelList(
                    elevation: 1,
                    expandedHeaderPadding: EdgeInsets.zero,
                    expansionCallback: (panelIndex, isExpanded) {
                      setState(() {
                        if (panelIndex == 0) {
                          availablePanelExpanded = !isExpanded;
                        } else {
                          availedPanelExpanded = !isExpanded;
                        }
                      });
                    },
                    children: [
                      ExpansionPanel(
                        headerBuilder: (context, isExpanded) {
                          return InkWell(
                            onTap: () {
                              setState(() {
                                availablePanelExpanded = !isExpanded;
                              });
                            },
                            child: const ListTile(
                              title: Text('Available Tombs'),
                            ),
                          );
                        },
                        body: Column(
                          children: [
                            TextField(
                              onChanged: (value) {
                                setState(() {
                                  searchAvailable = value;
                                });
                              },
                              decoration: const InputDecoration(
                                labelText: "Search",
                                prefixIcon: Icon(Icons.search),
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Search by:'),
                                DropdownButton<String>(
                                  value: dropdownValue,
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      dropdownValue = newValue!;
                                    });
                                  },
                                  items: <String>['Unit ID', 'Owner']
                                      .map<DropdownMenuItem<String>>(
                                          (String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                            ...availableTombs.isNotEmpty
                                ? availableTombs.map<Widget>((tomb) {
                                    return ListTile(
                                      tileColor:
                                          selectedUnitId == tomb["unitID"]
                                              ? Colors.lightBlueAccent
                                              : null,
                                      title: Text(tomb["unitID"]),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.info),
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) {
                                              return AlertDialog(
                                                title: const Text('Tomb Info'),
                                                content: SingleChildScrollView(
                                                  child: SizedBox(
                                                    width: double.infinity,
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                            'Unit ID: ${tomb["unitID"]}'),
                                                        Text(
                                                            'Coordinates: ${tomb["coords"][0].toStringAsFixed(2)}... ${tomb["coords"][1].toStringAsFixed(2)}...'),
                                                        Text(
                                                            'Availability: ${tomb["isAvailable"]}'),
                                                        Text(
                                                            'Owner: ${tomb["owner"] ?? "No Owner"}'),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                actions: <Widget>[
                                                  TextButton(
                                                    child: const Text('Close'),
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                      ),
                                      onTap: () {
                                        setState(() {
                                          selectedUnitId = tomb["unitID"];
                                          selectedCoords = tomb["coords"];
                                          selectedAvailedUnitId = null;
                                        });
                                      },
                                    );
                                  }).toList()
                                : [
                                    const SizedBox(height: 5),
                                    const Text("Nothing to see here"),
                                    const SizedBox(height: 5),
                                  ],
                          ],
                        ),
                        isExpanded: availablePanelExpanded,
                      ),
                      ExpansionPanel(
                        headerBuilder: (context, isExpanded) {
                          return InkWell(
                            onTap: () {
                              setState(() {
                                availedPanelExpanded = !isExpanded;
                              });
                            },
                            child: const ListTile(
                              title: Text('Availed Tombs'),
                            ),
                          );
                        },
                        body: Column(
                          children: [
                            ...availedTombs.isNotEmpty
                                ? availedTombs.map<Widget>((tomb) {
                                    return ListTile(
                                      tileColor: selectedAvailedUnitId ==
                                              tomb["unitID"]
                                          ? Colors.lightBlueAccent
                                          : null,
                                      title: Text(tomb["unitID"]),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.info),
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) {
                                              return AlertDialog(
                                                title: const Text('Tomb Info'),
                                                content: SingleChildScrollView(
                                                  child: SizedBox(
                                                    width: double.infinity,
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                            'Unit ID: ${tomb["unitID"]}'),
                                                        Text(
                                                            'Coordinates: ${tomb["coords"][0].toStringAsFixed(2)}... ${tomb["coords"][1].toStringAsFixed(2)}...'),
                                                        Text(
                                                            'Availability: ${tomb["isAvailable"]}'),
                                                        Text(
                                                            'Owner: ${tomb["owner"] ?? "No Owner"}'),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                actions: <Widget>[
                                                  TextButton(
                                                    child: const Text('Close'),
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                      ),
                                      onTap: () {
                                        setState(() {
                                          selectedUnitId = tomb["unitID"];
                                          selectedCoords = tomb["coords"];
                                          selectedAvailedUnitId = tomb[
                                              "unitID"]; // Set selected availed tomb
                                        });
                                      },
                                    );
                                  }).toList()
                                : [
                                    const SizedBox(height: 5),
                                    const Text("No availed tombs"),
                                    const SizedBox(height: 5),
                                  ],
                          ],
                        ),
                        isExpanded: availedPanelExpanded,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (selectedCoords != null) {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => NavigationScreen(
                        selectedCoords![0], // Pass the latitude from coords
                        selectedCoords![1], // Pass the longitude from coords
                      ),
                    ));
                  }
                },
                child: const Text('Get Directions'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
