import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class RecordsPage extends StatefulWidget {
  const RecordsPage({Key? key}) : super(key: key);

  @override
  State<RecordsPage> createState() => _RecordsPageState();
}

class _RecordsPageState extends State<RecordsPage> {
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

        return AlertDialog(
          title: const Text('Record Details'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Name: $name'),
              Text('Date of Birth: $dateOfBirth'),
              Text('Date of Death: $dateOfDeath'),
              Text('Purchase Date: $graveAvailDate'),
              Text('Sex: $sex'),
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
                _deleteRecord(document.id);
                Navigator.pop(context);
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
    // Retrieve the record data
    final recordData = document.data();
    String name = recordData?['name'];
    String sex = recordData?['sex'];
    DateTime dateOfBirth = recordData?['date_of_birth'].toDate();
    DateTime dateOfDeath = recordData?['date_of_death'].toDate();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Record'),
          content: Column(
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
              ElevatedButton(
                onPressed: () async {
                  final DateTime? picked =
                      await _selectDate(context, dateOfBirth);
                  if (picked != null) {
                    setState(() {
                      dateOfBirth = picked;
                    });
                  }
                },
                child: Text(
                  'Date of Birth: ${_dateFormat.format(dateOfBirth)}',
                ),
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () async {
                  final DateTime? picked =
                      await _selectDate(context, dateOfDeath);
                  if (picked != null) {
                    setState(() {
                      dateOfDeath = picked;
                    });
                  }
                },
                child: Text(
                  'Date of Death: ${_dateFormat.format(dateOfDeath)}',
                ),
              ),
            ],
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

  void _deleteRecord(String documentId) {
    final firestore = FirebaseFirestore.instance;
    firestore.collection('deceased').doc(documentId).delete();
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) {
      return 'N/A';
    }
    final dateTime = timestamp.toDate();
    final formatter = DateFormat('MMMM dd, yyyy HH:mm:ss');
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

  Future<TimeOfDay?> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    return picked;
  }

  void _showAddRecordDialog() {
    DateTime? selectedDateOfBirth;
    DateTime? selectedDateOfDeath;
    DateTime? selectedGraveAvailDate;
    TimeOfDay? selectedTimeOfBirth;
    TimeOfDay? selectedTimeOfDeath;
    TimeOfDay? selectedTimeOfGraveAvail;
    String name = '';
    String sex = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
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
                  Row(
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
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final TimeOfDay? picked =
                                await _selectTime(context);
                            if (picked != null) {
                              setState(() {
                                selectedTimeOfBirth = picked;
                              });
                            }
                          },
                          child: Text(
                            selectedTimeOfBirth != null
                                ? selectedTimeOfBirth!.format(context)
                                : 'Select Time',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  Row(
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
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final TimeOfDay? picked =
                                await _selectTime(context);
                            if (picked != null) {
                              setState(() {
                                selectedTimeOfDeath = picked;
                              });
                            }
                          },
                          child: Text(
                            selectedTimeOfDeath != null
                                ? selectedTimeOfDeath!.format(context)
                                : 'Select Time',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  Row(
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
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final TimeOfDay? picked =
                                await _selectTime(context);
                            if (picked != null) {
                              setState(() {
                                selectedTimeOfGraveAvail = picked;
                              });
                            }
                          },
                          child: Text(
                            selectedTimeOfGraveAvail != null
                                ? selectedTimeOfGraveAvail!.format(context)
                                : 'Select Time',
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
                            selectedDateOfBirth != null &&
                            selectedTimeOfBirth != null &&
                            selectedDateOfDeath != null &&
                            selectedTimeOfDeath != null &&
                            selectedGraveAvailDate != null &&
                            selectedTimeOfGraveAvail != null) {
                          // Save the record to Firestore
                          final firestore = FirebaseFirestore.instance;
                          firestore.collection('deceased').add({
                            'name': name,
                            'sex': sex,
                            'date_of_birth': Timestamp.fromDate(
                              DateTime(
                                selectedDateOfBirth!.year,
                                selectedDateOfBirth!.month,
                                selectedDateOfBirth!.day,
                                selectedTimeOfBirth!.hour,
                                selectedTimeOfBirth!.minute,
                              ),
                            ),
                            'date_of_death': Timestamp.fromDate(
                              DateTime(
                                selectedDateOfDeath!.year,
                                selectedDateOfDeath!.month,
                                selectedDateOfDeath!.day,
                                selectedTimeOfDeath!.hour,
                                selectedTimeOfDeath!.minute,
                              ),
                            ),
                            'grave_avail_date': Timestamp.fromDate(
                              DateTime(
                                selectedGraveAvailDate!.year,
                                selectedGraveAvailDate!.month,
                                selectedGraveAvailDate!.day,
                                selectedTimeOfGraveAvail!.hour,
                                selectedTimeOfGraveAvail!.minute,
                              ),
                            ),
                          });

                          Navigator.pop(context);
                        }
                      },
                      child: const Text('Add Record'),
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
      body: Column(
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddRecordDialog,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
