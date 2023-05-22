import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MapPage extends StatelessWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String htmlContent = '''
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link href="https://api.mapbox.com/mapbox-gl-js/v2.13.0/mapbox-gl.css" rel="stylesheet">
    <script src="https://api.mapbox.com/mapbox-gl-js/v2.13.0/mapbox-gl.js"></script>
    <script
        src="https://api.mapbox.com/mapbox-gl-js/plugins/mapbox-gl-directions/v4.1.0/mapbox-gl-directions.js"></script>
    <link rel="stylesheet"
        href="https://api.mapbox.com/mapbox-gl-js/plugins/mapbox-gl-directions/v4.1.0/mapbox-gl-directions.css"
        type="text/css" />
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/css/bootstrap.min.css" rel="stylesheet"
        integrity="sha384-GLhlTQ8iRABdZLl6O3oVMWSktQOp6b7In1Zl3/Jr59b6EGGoI1aFkw7cmDA6j6gD" crossorigin="anonymous">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.3/font/bootstrap-icons.css">
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/js/bootstrap.bundle.min.js"
        integrity="sha384-w76AqPfDkMBDXo30jS1Sgez6pr3x5MlQ1ZAGC+nuZB+EYdgRZgiwxhTBTkF7CXvN"
        crossorigin="anonymous"></script>

    <title>Himlayang Pilipino Navigation App</title>
    <style>
        body {
            margin: 0;
        }

        #map {
            height: 100vh;
            width: 100vw;
        }

        html,
        body {
            margin: 0;
        }

        div.tomblist {
            z-index: 10;
            margin: 30px;
            background: #f8f8f8;
            height: 250px;
            width: 200px;
            border-radius: 25px;
            position: fixed;
            bottom: 70px;
            right: 1px;
            box-shadow: 5px 4px 5px rgba(201, 201, 201, 0.486);
            overflow: scroll;
            visibility: hidden;
        }

        #unit-list-container {
            position: fixed;
            bottom: 4.8rem;
            right: 1rem;
            max-height: 300px;
            overflow-y: auto;
        }

        .btn-holder {
            position: fixed;
            bottom: 0;
            right: 0;
            margin: 1rem;
            margin-bottom: 1rem;
            margin-bottom: 1.8rem;
        }

        .directions-control.directions-control-directions {
            width: 200px;
            height: 250px;
        }

        .mapbox-directions-step {
            font-size: 12px;
        }
    </style>
</head>

<body>
    <div id="map"></div>
    <div id="unit-list-container" class="d-none">
        <div id="unit-list" class="list-group"></div>
    </div>

    <div class="btn-holder">
        <button id="show-units-btn" class="btn btn-primary">
            Show Units
        </button>
    </div>

    <script src="https://www.gstatic.com/firebasejs/9.6.10/firebase-app-compat.js"></script>
    <script src="https://www.gstatic.com/firebasejs/9.6.10/firebase-firestore-compat.js"></script>
    <script>

        // Set the Mapbox access token
        mapboxgl.accessToken =
            'pk.eyJ1Ijoia3Vza3VzeHlyZW5uIiwiYSI6ImNsaHk5aHR6ZzExaHozam13bTdxOXBsZGQifQ.qVIWiuy7SOY2eQq226IO3Q';

        // Function to get the coordinates of a unit from Firestore using its unitID
        function getUnitCoordinates(unitID, map) {
            // Get a reference to the unit document in the 'tombs' collection
            const unitRef = db.collection('tombs').doc(unitID);

            // Fetch the document from Firestore
            unitRef
                .get()
                .then((doc) => {
                    if (doc.exists) {
                        // Extract coordinates from the document data
                        const data = doc.data();
                        const coordinates = [data['coords'][1], data['coords'][0]];
                        // Plot the unit on the map using its coordinates
                        plotUnitOnMap(coordinates, map);
                    } else {
                        console.log('No such document!');
                    }
                })
                .catch((error) => {
                    console.log('Error getting document:', error);
                });
        }

        // Function to plot a unit on the map using its coordinates
        function plotUnitOnMap(coordinates, map) {
            const [longitude, latitude] = coordinates;

            // Check if the coordinates are valid numbers
            if (!isNaN(longitude) && !isNaN(latitude)) {
                if (map) {
                    // Create a marker and add it to the map at the specified coordinates
                    const marker = new mapboxgl.Marker().setLngLat(coordinates).addTo(map);
                    // Animate the map view to center on the marker
                    map.flyTo({
                        center: coordinates,
                        essential: true,
                    });
                }
            } else {
                console.log("Invalid coordinates:", coordinates);
            }
        }

        // Function to load the list of units from Firestore and display them in the UI
        function loadUnits(map) {
            const unitList = document.getElementById('unit-list');

            // Fetch all documents from the 'tombs' collection
            db.collection('tombs')
                .get()
                .then((querySnapshot) => {
                    // Iterate through each document and add a button for it to the unit list
                    querySnapshot.forEach((doc) => {
                        const data = doc.data();
                        const unitID = data.unitID;

                        const button = document.createElement('button');
                        button.setAttribute('type', 'button');
                        button.classList.add('list-group-item', 'list-group-item-action');
                        button.textContent = data['unitID'];
                        button.onclick = function () {
                            // Set the click event to fetch and display the unit's coordinates on the map
                            getUnitCoordinates(doc.id, map);
                        };

                        unitList.appendChild(button);
                    });
                });
        }

        // Function to set up the Mapbox GL JS map
        function setupMap(center = [121.0524150628587, 14.682569991056297]) {
            // Initialize the map and set its options
            const map = new mapboxgl.Map({
                container: 'map',
                style: 'mapbox://styles/kuskusxyrenn/clee7imbg000p01nx6ah0pt8w',
                center: center,
                zoom: 15,
            });

            // Add navigation controls to the map
            const nav = new mapboxgl.NavigationControl();
            map.addControl(nav);

            // Add directions control to the map
            var directions = new MapboxDirections({
                accessToken: mapboxgl.accessToken,
            });
            map.addControl(directions, 'top-left');

            // Add geolocation control to the map
            const geolocateControl = new mapboxgl.GeolocateControl({
                positionOptions: {
                    enableHighAccuracy: true,
                },
                // Draw an arrow next to the location dot to indicate which direction the device is heading.
                showUserHeading: true,
            });
            map.addControl(geolocateControl);

            // Set the 'geolocate' event handler for the geolocation control
            geolocateControl.on('geolocate', function (e) {
                const center = [e.coords.longitude, e.coords.latitude];
                // Animate the map view to center on the user's location
                map.flyTo({
                    center: center,
                    essential: true,
                });
            });

            return map;
        }

        // Your web app's Firebase configuration

        const firebaseConfig = {
            apiKey: "AIzaSyDv-Kg5jb9M6jsINS3jLA55shoAXkUCbjY",
            authDomain: "flutterhimnavi.firebaseapp.com",
            projectId: "flutterhimnavi",
            storageBucket: "flutterhimnavi.appspot.com",
            messagingSenderId: "749238580298",
            appId: "1:749238580298:web:d608f7e60be90fb5c6e2b3"
        };

        // Initialize the Firebase app with the configuration object
        const app = firebase.initializeApp(firebaseConfig);
        console.log("Firebase app initialized:", app);
        // Initialize the Firestore database
        const db = firebase.firestore(app);

        // Function to read example data from Firestore
        function readDataFromFirestore() {
            db.collection("tombs")
                .limit(1)
                .get()
                .then((querySnapshot) => {
                    querySnapshot.forEach((doc) => {
                        console.log("Example Firestore data:", doc.data());
                    });
                })
                .catch((error) => {
                    console.error("Error reading data from Firestore:", error);
                });
        }

        // Set up the event listeners and initialize the application when the DOM is fully loaded
        document.addEventListener('DOMContentLoaded', () => {
            const showUnitsBtn = document.getElementById('show-units-btn');
            const unitListContainer = document.getElementById('unit-list-container');

            // Toggle the visibility of the unit list when the button is clicked
            showUnitsBtn.addEventListener('click', () => {
                unitListContainer.classList.toggle('d-none');
            });

            // Main function to initialize the application
            async function init() {
                const map = setupMap();
                loadUnits(map);
            }

            // Call the main initialization function
            init();
        });
    </script>
</body>

</html>
''';

    return Scaffold(
      appBar: null, // Remove the app bar
      body: SafeArea(
        child: WebView(
          javascriptMode: JavascriptMode.unrestricted,
          onWebViewCreated: (WebViewController webViewController) {
            webViewController.loadUrl(
              Uri.dataFromString(htmlContent, mimeType: 'text/html').toString(),
            );
          },
        ),
      ),
    );
  }
}
