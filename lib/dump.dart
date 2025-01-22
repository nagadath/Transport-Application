// ,
//       // body: GoogleMap(
//       //   onMapCreated: (GoogleMapController controller) {
//       //           setState(() {
//       //             mapController = controller;
//       //           });
//       //         },
//       //   initialCameraPosition: CameraPosition(
//       //     target: userLocation,
//       //     zoom: 18.0,
//       //   ),
//       //   markers: visibleMarkers,
//       // ),
//       body: Column(
//         children: [
//            Container(
//               width: 200,
//               decoration: const BoxDecoration(
//     color: Colors.transparent, // Set your desired background color here
//   ),
//           child: TextButton(
//               onPressed: () {
//                 Navigator.of(context).push(
//                   MaterialPageRoute(builder: (context) => const SearchLoc()),
//                 );
//               },
//               style: ButtonStyle(backgroundColor: MaterialStateProperty.all<Color>(Colors.transparent),),
//               child: const Text("Enter Your search place"),
//             )
//           ),
//       //     if (widget.userLocation != const LatLng(0,0))
//       //       GoogleMap(
//       //         initialCameraPosition: CameraPosition(
//       //           target: widget.userLocation,
//       //           zoom: 15.0,
//       //         ),
//       //         markers: visibleMarkers,
//       //         //circles: _circles,
//       //         onMapCreated: (GoogleMapController controller) {
//       //           setState(() {
//       //             mapController = controller;
//       //           });
//       //         },
//       //       )
//       //     else
//       //       const Center(
//       //         child: CircularProgressIndicator(),
//       //       ),
//       Expanded( // Constrain GoogleMap to take up remaining space
//         child: Stack(
//           children: [
//             if (widget.userLocation != const LatLng(0,0))
//               GoogleMap(
//                 initialCameraPosition: CameraPosition(
//                   target: widget.userLocation,
//                   zoom: 15.0,
//                 ),
//                 markers: visibleMarkers,
//                 onMapCreated: (GoogleMapController controller) {
//                   setState(() {
//                     mapController = controller;
//                   });
//                 },
//               )
//             else
//               const Center(
//                 child: CircularProgressIndicator(),
//               ),
//           ],
//         ),
//       ),
//         ],
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           updateVisibleMarkers(widget.userLocation);
//           //_controller.animateCamera(CameraUpdate.newLatLngZoom(_currentPosition, 18));
//         },
//         child: const Icon(Icons.location_on),
//       ),