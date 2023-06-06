import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminRecordsPage extends StatefulWidget {
  const AdminRecordsPage({Key? key}) : super(key: key);

  @override
  State<AdminRecordsPage> createState() => _AdminRecordsPageState();
}

class _AdminRecordsPageState extends State<AdminRecordsPage> {
  late Stream<QuerySnapshot<Map<String, dynamic>>> _recordsStream;
  final _dateFormat = DateFormat('MMMM dd, yyyy');
  final TextEditingController _searchController = TextEditingController();
  late String _searchFilter;

  @override
  void initState() {
    super.initState();
    _loadRecords();
    _searchFilter = 'Name';
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

        // Retrieve tomb information from Firestore
        final tombQuery = FirebaseFirestore.instance
            .collection('tombs')
            .where('tomb', isEqualTo: tomb)
            .get();

        return FutureBuilder<QuerySnapshot>(
          future: tombQuery,
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AlertDialog(
                title: Text('Record Details'),
                content: SizedBox(
                  width: 60, // Adjust the size as needed
                  height: 60, // Adjust the size as needed
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              );
            } else if (snapshot.hasError) {
              return const AlertDialog(
                title: Text('Record Details'),
                content: Text('An error occurred while loading the data.'),
              );
            } else {
              final tombDocs = snapshot.data?.docs;
              final ownerEmail = tombDocs != null && tombDocs.isNotEmpty
                  ? tombDocs.first.get('owner_email')
                  : null;

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
                    Text('Lot: $tomb'),
                    if (ownerEmail != null) ...[
                      const SizedBox(height: 3),
                      Text('Owner: $ownerEmail'),
                    ],
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Close'),
                  ),
                ],
              );
            }
          },
        );
      },
    );
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
                    decoration: const InputDecoration(labelText: 'Lot'),
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
                            'createdAt': FieldValue.serverTimestamp(),
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

  Widget _buildSearchFilterDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Search by:'),
          DropdownButton<String>(
            value: _searchFilter,
            icon: const Icon(Icons.arrow_downward),
            iconSize: 24,
            elevation: 16,
            onChanged: (String? newValue) {
              setState(() {
                _searchFilter = newValue!;
              });
            },
            items: <String>['Name', 'Lot']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
        ],
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
            _buildSearchFilterDropdown(),
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

                    final filteredRecords = _searchController.text.isEmpty
                        ? records
                        : records.where((record) {
                            final recordData = record.data();
                            final searchField =
                                _searchFilter == 'Lot' ? 'tomb' : 'name';
                            final fieldValue = recordData[searchField];
                            return fieldValue
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
                        final name = recordData['name'];
                        final graveAvailDate =
                            _formatTimestamp(recordData['grave_avail_date']);
                        final tomb = recordData['tomb'];

                        return Container(
                          margin: const EdgeInsets.symmetric(
                              vertical: 8.0), // Add vertical margin
                          child: ListTile(
                            title: Text(name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Purchase Date: $graveAvailDate'),
                                Text('Lot: $tomb'),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.info),
                              onPressed: () {
                                _showDetails(document);
                              },
                            ),
                          ),
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
