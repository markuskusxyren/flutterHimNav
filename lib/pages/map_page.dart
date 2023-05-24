import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'navigation_page.dart';

final _firestore = FirebaseFirestore.instance;

void main() {
  runApp(const MaterialApp(
    home: MapPage(),
  ));
}

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  List<Map<String, dynamic>> tombs = [];
  String? selectedUnitId;
  GeoPoint? selectedCoords;

  void getTombs() async {
    await _firestore
        .collection('tombs')
        .get()
        .then((QuerySnapshot querySnapshot) {
      for (var doc in querySnapshot.docs) {
        List<dynamic> pointList = doc["coords"];
        GeoPoint point = GeoPoint(pointList[0], pointList[1]);
        String unitID = doc["unitID"];
        tombs.add({"coords": point, "unitID": unitID});
      }
      setState(() {});
    });
  }

  @override
  void initState() {
    super.initState();
    getTombs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Expanded(
            child: ListView.builder(
                itemCount: tombs.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    tileColor: selectedUnitId == tombs[index]["unitID"]
                        ? Colors.lightBlueAccent
                        : null,
                    title: Text(tombs[index]["unitID"]),
                    onTap: () {
                      setState(() {
                        selectedUnitId = tombs[index]["unitID"];
                        selectedCoords = tombs[index]["coords"];
                      });
                    },
                  );
                }),
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
                            selectedCoords!.latitude,
                            selectedCoords!.longitude)));
                  }
                },
                child: const Text('Get Directions')),
          ),
        ]),
      ),
    );
  }
}
