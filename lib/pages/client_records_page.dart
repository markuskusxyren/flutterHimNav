import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ClientRecordsPage extends StatefulWidget {
  const ClientRecordsPage({Key? key}) : super(key: key);

  @override
  State<ClientRecordsPage> createState() => _ClientRecordsPageState();
}

class _ClientRecordsPageState extends State<ClientRecordsPage> {
  Stream<QuerySnapshot<Map<String, dynamic>>>? _recordsStream;
  final TextEditingController _searchController = TextEditingController();
  String _searchFilter = 'Name';

  @override
  void initState() {
    super.initState();
    _loadRecords().then((stream) {
      if (mounted) {
        setState(() {
          _recordsStream = stream;
        });
      }
    });
  }

  Future<Stream<QuerySnapshot<Map<String, dynamic>>>> _loadRecords() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Stream.empty();
    }

    final currentUserEmail = currentUser.email;

    final firestore = FirebaseFirestore.instance;

    final CollectionReference<Map<String, dynamic>> tombsCollection =
        firestore.collection('tombs');
    final CollectionReference<Map<String, dynamic>> deceasedCollection =
        firestore.collection('deceased');

    final tombQuery =
        tombsCollection.where('owner', isEqualTo: currentUserEmail);
    final tombsSnapshot = await tombQuery.get();

    if (tombsSnapshot.docs.isEmpty) {
      return const Stream.empty();
    }

    final tombIds =
        tombsSnapshot.docs.map((doc) => doc.data()['unitID']).toList();

    if (tombIds.isEmpty) {
      return const Stream.empty();
    }

    final deceasedQuery = deceasedCollection.where('tomb', whereIn: tombIds);

    return deceasedQuery.snapshots();
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
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
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
            items: <String>['Name', 'Tomb']
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

                  if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                    final records = snapshot.data!.docs;

                    final filteredRecords = _searchController.text.isEmpty
                        ? records
                        : records.where((record) {
                            final recordData = record.data();
                            final searchField =
                                _searchFilter == 'Tomb' ? 'tomb' : 'name';
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
                          margin: const EdgeInsets.all(15.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20.0),
                            color: Colors.grey[200],
                          ),
                          child: ListTile(
                            title: Text(name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Purchase Date: $graveAvailDate'),
                                Text('Tomb: $tomb'),
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
                  return const Center(child: Text('No records found.'));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
