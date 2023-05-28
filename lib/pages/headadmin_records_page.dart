import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class HeadRecordsPage extends StatefulWidget {
  const HeadRecordsPage({Key? key}) : super(key: key);

  @override
  State<HeadRecordsPage> createState() => _HeadRecordsPageState();
}

class _HeadRecordsPageState extends State<HeadRecordsPage> {
  late Stream<QuerySnapshot<Map<String, dynamic>>> _recordsStream;
  final _dateFormat = DateFormat('MMMM dd, yyyy');
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  void _loadRecords() {
    final collection = FirebaseFirestore.instance.collection('deceased');
    _recordsStream = collection.snapshots();
  }

  void _showDetails(DocumentSnapshot<Map<String, dynamic>> document) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final recordData = document.data();
        final name = recordData?['name'];
        final dateOfBirth = _formatTimestamp(recordData?['date_of_birth']);
        final dateOfDeath = _formatTimestamp(recordData?['date_of_death']);
        final graveAvailDate =
            _formatTimestamp(recordData?['grave_avail_date']);
        final sex = recordData?['sex'];
        final tomb = recordData?['tomb'];

        return AlertDialog(
          title: const Text('Record Details'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Name: $name'),
              const SizedBox(height: 3),
              Text('Date of Birth: $dateOfBirth'),
              const SizedBox(height: 3),
              Text('Date of Death: $dateOfDeath'),
              const SizedBox(height: 3),
              Text('Purchase Date: $graveAvailDate'),
              const SizedBox(height: 3),
              Text('Sex: $sex'),
              const SizedBox(height: 3),
              Text('Tomb: $tomb'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Edit action
                _showEditDialog(document);
              },
              child: const Text('Edit'),
            ),
            TextButton(
              onPressed: () {
                // Delete action
                _showDeleteConfirmation(document.id);
              },
              child: const Text('Delete'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showEditDialog(DocumentSnapshot<Map<String, dynamic>> document) {
    final recordData = document.data();
    String name = recordData?['name'];
    String sex = recordData?['sex'];
    DateTime dateOfBirth = recordData?['date_of_birth'].toDate();
    DateTime dateOfDeath = recordData?['date_of_death'].toDate();
    String tomb = recordData?['tomb'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Record'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Name'),
                  initialValue: name,
                  onChanged: (value) {
                    setState(() {
                      name = value;
                    });
                  },
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Sex'),
                  initialValue: sex,
                  onChanged: (value) {
                    setState(() {
                      sex = value;
                    });
                  },
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Tomb'),
                  initialValue: tomb,
                  onChanged: (value) {
                    setState(() {
                      tomb = value;
                    });
                  },
                ),
                const SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: () async {
                    // Existing onPressed code...
                  },
                  child: Text(
                    'Date of Birth: ${_dateFormat.format(dateOfBirth)}',
                  ),
                ),
                const SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: () async {
                    // Existing onPressed code...
                  },
                  child: Text(
                    'Date of Death: ${_dateFormat.format(dateOfDeath)}',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Save the updated record to Firestore
                final firestore = FirebaseFirestore.instance;
                firestore.collection('deceased').doc(document.id).update({
                  'name': name,
                  'sex': sex,
                  'date_of_birth': Timestamp.fromDate(dateOfBirth),
                  'date_of_death': Timestamp.fromDate(dateOfDeath),
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
  }

  void _showDeleteConfirmation(String documentId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete this record?'),
          actions: [
            TextButton(
              onPressed: () {
                // Delete the record
                _deleteRecord(documentId);
                // Then close the dialog
                Navigator.pop(context);
              },
              child: const Text('Delete'),
            ),
            TextButton(
              onPressed: () {
                // Close the dialog
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
    final firestore = FirebaseFirestore.instance;
    firestore.collection('deceased').doc(documentId).delete();
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) {
      return 'N/A';
    }
    final dateTime = timestamp.toDate();
    final formatter = DateFormat('MMMM dd, yyyy');
    return formatter.format(dateTime);
  }

  Future<DateTime?> _selectDate(
      BuildContext context, DateTime? initialDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    return picked;
  }

  void _showAddRecordDialog() {
    DateTime? selectedDateOfBirth;
    DateTime? selectedDateOfDeath;
    DateTime? selectedGraveAvailDate;
    String name = '';
    String sex = '';
    String tomb = '';

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
                    'Add Record',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Name'),
                    onChanged: (value) {
                      setState(() {
                        name = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Sex'),
                    onChanged: (value) {
                      setState(() {
                        sex = value;
                      });
                    },
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final DateTime? picked =
                                await _selectDate(context, selectedDateOfBirth);
                            if (picked != null) {
                              setState(() {
                                selectedDateOfBirth = picked;
                              });
                            }
                          },
                          child: Text(
                            selectedDateOfBirth != null
                                ? _dateFormat.format(selectedDateOfBirth!)
                                : 'Select Date of Birth',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final DateTime? picked =
                                await _selectDate(context, selectedDateOfDeath);
                            if (picked != null) {
                              setState(() {
                                selectedDateOfDeath = picked;
                              });
                            }
                          },
                          child: Text(
                            selectedDateOfDeath != null
                                ? _dateFormat.format(selectedDateOfDeath!)
                                : 'Select Date of Death',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final DateTime? picked = await _selectDate(
                                context, selectedGraveAvailDate);
                            if (picked != null) {
                              setState(() {
                                selectedGraveAvailDate = picked;
                              });
                            }
                          },
                          child: Text(
                            selectedGraveAvailDate != null
                                ? _dateFormat.format(selectedGraveAvailDate!)
                                : 'Select Purchase Date',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () {
                        if (name.isNotEmpty &&
                            sex.isNotEmpty &&
                            tomb.isNotEmpty &&
                            selectedDateOfBirth != null &&
                            selectedDateOfDeath != null &&
                            selectedGraveAvailDate != null) {
                          // Save the record to Firestore
                          final firestore = FirebaseFirestore.instance;
                          firestore.collection('deceased').add({
                            'name': name,
                            'sex': sex,
                            'tomb': tomb,
                            'date_of_birth': Timestamp.fromDate(
                              selectedDateOfBirth!,
                            ),
                            'date_of_death': Timestamp.fromDate(
                              selectedDateOfDeath!,
                            ),
                            'grave_avail_date': Timestamp.fromDate(
                              selectedGraveAvailDate!,
                            ),
                          });

                          Navigator.pop(context);
                        }
                      },
                      child: const Text('Submit'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              setState(() {
                _searchController.clear();
              });
            },
          ),
        ),
        onChanged: (value) {
          setState(() {});
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _recordsStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasData) {
                    final records = snapshot.data!.docs;

                    if (records.isEmpty) {
                      return const Center(
                        child: Text('No records found.'),
                      );
                    }

                    // Filter records based on search query
                    final filteredRecords = _searchController.text.isEmpty
                        ? records
                        : records.where((record) {
                            final recordData = record.data();
                            final name = recordData['name'];
                            return name
                                .toLowerCase()
                                .contains(_searchController.text.toLowerCase());
                          }).toList();

                    if (filteredRecords.isEmpty) {
                      return const Center(
                        child: Text('No matching records found.'),
                      );
                    }

                    return ListView.builder(
                      itemCount: filteredRecords.length,
                      itemBuilder: (context, index) {
                        final document = filteredRecords[index];
                        final recordData = document.data();

                        // Adjust the field names according to your Firestore document structure
                        final name = recordData['name'];
                        final graveAvailDate =
                            _formatTimestamp(recordData['grave_avail_date']);

                        return ListTile(
                          title: Text(name),
                          subtitle: Text('Purchase Date: $graveAvailDate'),
                          trailing: IconButton(
                            icon: const Icon(Icons.info),
                            onPressed: () {
                              _showDetails(document);
                            },
                          ),
                          // Customize the list tile as per your requirement
                        );
                      },
                    );
                  }
                  return Container();
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddRecordDialog,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
