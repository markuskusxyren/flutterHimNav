import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'navigation_page.dart';

final _firestore = FirebaseFirestore.instance;

void main() {
  runApp(const MaterialApp(
    home: HeadMapPage(),
  ));
}

class HeadMapPage extends StatefulWidget {
  const HeadMapPage({Key? key}) : super(key: key);

  @override
  State<HeadMapPage> createState() => _HeadMapPageState();
}

class _HeadMapPageState extends State<HeadMapPage> {
  List<Map<String, dynamic>> tombs = [];
  String? selectedUnitId;
  List<double>? selectedCoords;
  String dropdownValue = 'Lot';

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
          Map<String, dynamic> data =
              doc.data() as Map<String, dynamic>; // Cast to the desired type
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
                (dropdownValue == 'Lot'
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
                (dropdownValue == 'Lot'
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
                              title: Text('Available Lots'),
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
                                  items: <String>['Lot', 'Owner']
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
                                                title: const Text('Lot Info'),
                                                content: SingleChildScrollView(
                                                  child: SizedBox(
                                                    width: double.infinity,
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                            'Lot: ${tomb["tomb"]}'),
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
                                                    onPressed: () {
                                                      _showEditDialog(tomb);
                                                    },
                                                    child: const Text('Edit'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      _showDeleteConfirmation(
                                                          tomb["documentID"]);
                                                    },
                                                    child: const Text('Delete'),
                                                  ),
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
                              title: Text('Not Available Lots'),
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
                                  items: <String>['Lot', 'Owner']
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
                                                title: const Text('Lot Info'),
                                                content: SingleChildScrollView(
                                                  child: SizedBox(
                                                    width: double.infinity,
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                            'Lot: ${tomb["tomb"]}'),
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
                                                    onPressed: () {
                                                      // Edit action
                                                      _showEditDialog(tomb);
                                                    },
                                                    child: const Text('Edit'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      // Delete action
                                                      _showDeleteConfirmation(
                                                          tomb["documentID"]);
                                                    },
                                                    child: const Text('Delete'),
                                                  ),
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
                child: const Text('Add Lot'),
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

  void _showEditDialog(Map<String, dynamic> tomb) {
    String unitID = tomb['tomb'];
    List<double> coords = List.from(tomb['coords']);
    String documentID = tomb['documentID']; // Get the document ID
    bool isAvailable = tomb['owner_email']?.isEmpty ?? true;
    String owner = tomb['owner_email'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Edit Lot'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Lot'),
                      initialValue: unitID,
                      onChanged: (value) {
                        setState(() {
                          unitID = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16.0),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Latitude'),
                      initialValue: coords[0].toString(),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d*$')),
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
                      initialValue: coords[1].toString(),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d*$')),
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
                      initialValue: owner,
                      onChanged: (value) {
                        setState(() {
                          owner = value;
                          isAvailable = owner.isEmpty;
                        });
                      },
                    ),
                    const SizedBox(height: 16.0),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    // Save the updated record to Firestore
                    final firestore = FirebaseFirestore.instance;
                    firestore.collection('tombs').doc(documentID).update({
                      'tomb': unitID,
                      'coords': coords,
                      'isAvailable': isAvailable,
                      'owner_email': owner,
                    });

                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmation(String documentId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete this tomb?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteRecord(documentId);
              },
              child: const Text('Delete'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _deleteRecord(String documentId) {
    _firestore.collection('tombs').doc(documentId).delete();
  }

  void _showAddDialog() {
    String unitID = '';
    List<double> coords = [0.0, 0.0];
    String owner = '';

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
                    'Add Lot',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Lot'),
                    onChanged: (value) {
                      setState(() {
                        unitID = value;
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
                        owner = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: () {
                      // Determine availability based on the presence of owner
                      bool isAvailable = owner.isEmpty;

                      // Add the new record to Firestore
                      final firestore = FirebaseFirestore.instance;
                      firestore.collection('tombs').add({
                        'tomb': unitID,
                        'coords': coords,
                        'isAvailable': isAvailable,
                        'owner_email': owner,
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
