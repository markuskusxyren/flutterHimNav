import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'navigation_page.dart';

final _firestore = FirebaseFirestore.instance;

void main() {
  runApp(const MaterialApp(
    home: AdminMapPage(),
  ));
}

class AdminMapPage extends StatefulWidget {
  const AdminMapPage({Key? key}) : super(key: key);

  @override
  State<AdminMapPage> createState() => _AdminMapPageState();
}

class _AdminMapPageState extends State<AdminMapPage> {
  List<Map<String, dynamic>> tombs = [];
  String? selectedUnitId;
  List<double>? selectedCoords;
  String dropdownValue = 'Tomb';

  @override
  void initState() {
    super.initState();
    getTombs();
  }

  String? searchAvailable;
  String? searchNotAvailable;

  bool availablePanelExpanded = false;
  bool notAvailablePanelExpanded = false;

  void getTombs() {
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
            "tomb": tomb,
            "isAvailable": isAvailable,
            "owner_email": ownerEmail,
          };
        }).toList();

        selectedUnitId = tombs.isNotEmpty ? null : null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> availableTombs = tombs
        .where((tomb) =>
            tomb['isAvailable'] &&
            (searchAvailable == null ||
                searchAvailable!.isEmpty ||
                (dropdownValue == 'Tomb'
                    ? tomb['tomb']
                        .toLowerCase()
                        .contains(searchAvailable!.toLowerCase())
                    : tomb['owner_email']
                        .toLowerCase()
                        .contains(searchAvailable!.toLowerCase()))))
        .toList();

    List<Map<String, dynamic>> notAvailableTombs = tombs
        .where((tomb) =>
            !tomb['isAvailable'] &&
            (searchNotAvailable == null ||
                searchNotAvailable!.isEmpty ||
                (dropdownValue == 'Tomb'
                    ? tomb['tomb']
                        .toLowerCase()
                        .contains(searchNotAvailable!.toLowerCase())
                    : tomb['owner_email']
                        .toLowerCase()
                        .contains(searchNotAvailable!.toLowerCase()))))
        .toList();

    notAvailableTombs = notAvailableTombs.map((tomb) {
      if (tomb['owner_email'] == null || tomb['owner_email'].isEmpty) {
        tomb['owner_email'] = 'No Owner';
      }
      return tomb;
    }).toList();

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
                          notAvailablePanelExpanded = !isExpanded;
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
                                const Text('    Search by:'),
                                DropdownButton<String>(
                                  value: dropdownValue,
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      dropdownValue = newValue!;
                                    });
                                  },
                                  items: <String>['Tomb', 'Owner']
                                      .map<DropdownMenuItem<String>>(
                                    (String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value),
                                      );
                                    },
                                  ).toList(),
                                ),
                              ],
                            ),
                            ...availableTombs.isNotEmpty
                                ? availableTombs.map<Widget>((tomb) {
                                    return ListTile(
                                      tileColor: selectedUnitId == tomb["tomb"]
                                          ? Colors.lightBlueAccent
                                          : null,
                                      title: Text(tomb["tomb"]),
                                      subtitle: Text(
                                          'Owner: ${tomb["owner_email"] ?? "No Owner"}'),
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
                                                            'Tomb: ${tomb["tomb"]}'),
                                                        Text(
                                                            'Coordinates: ${tomb["coords"][0].toStringAsFixed(2)}... ${tomb["coords"][1].toStringAsFixed(2)}...'),
                                                        Text(
                                                            'Availability: ${tomb["isAvailable"]}'),
                                                        Text(
                                                            'Owner: ${tomb["owner_email"] ?? "No Owner"}'),
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
                                          selectedUnitId = tomb["tomb"];
                                          selectedCoords = tomb["coords"];
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
                                notAvailablePanelExpanded = !isExpanded;
                              });
                            },
                            child: const ListTile(
                              title: Text('Not Available Tombs'),
                            ),
                          );
                        },
                        body: Column(
                          children: [
                            TextField(
                              onChanged: (value) {
                                setState(() {
                                  searchNotAvailable = value;
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
                                const Text('    Search by:'),
                                DropdownButton<String>(
                                  value: dropdownValue,
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      dropdownValue = newValue!;
                                    });
                                  },
                                  items: <String>['Tomb', 'Owner']
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
                            ...notAvailableTombs.isNotEmpty
                                ? notAvailableTombs.map<Widget>((tomb) {
                                    return ListTile(
                                      tileColor: selectedUnitId == tomb["tomb"]
                                          ? Colors.lightBlueAccent
                                          : null,
                                      title: Text(tomb["tomb"]),
                                      subtitle: Text(
                                          'Owner: ${tomb["owner_email"] ?? "No Owner"}'),
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
                                                            'Tomb: ${tomb["tomb"]}'),
                                                        Text(
                                                            'Coordinates: ${tomb["coords"][0].toStringAsFixed(2)}... ${tomb["coords"][1].toStringAsFixed(2)}...'),
                                                        Text(
                                                            'Availability: ${tomb["isAvailable"]}'),
                                                        Text(
                                                            'Owner: ${tomb["owner_email"] ?? "No Owner"}'),
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
                                          selectedUnitId = tomb["tomb"];
                                          selectedCoords = tomb["coords"];
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
                        isExpanded: notAvailablePanelExpanded,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _showAddDialog();
                },
                child: const Text('Add Tomb'),
              ),
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

  void _showAddDialog() {
    String tomb = '';
    List<double> coords = [0.0, 0.0];
    String ownerEmail = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Add this property
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
        ),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Add Tomb',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Tomb'),
                    onChanged: (value) {
                      setState(() {
                        tomb = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Latitude'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*$')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        coords[0] = double.tryParse(value) ?? 0.0;
                      });
                    },
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Longitude'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*$')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        coords[1] = double.tryParse(value) ?? 0.0;
                      });
                    },
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Owner'),
                    onChanged: (value) {
                      setState(() {
                        ownerEmail = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: () {
                      // Determine availability based on the presence of owner
                      bool isAvailable = ownerEmail.isEmpty;

                      // Add the new record to Firestore
                      final firestore = FirebaseFirestore.instance;
                      firestore.collection('tombs').add({
                        'tomb': tomb,
                        'coords': coords,
                        'isAvailable': isAvailable,
                        'owner_email': ownerEmail,
                      });

                      Navigator.pop(context);
                    },
                    child: const Text('Add'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
