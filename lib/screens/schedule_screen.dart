import 'dart:math';

import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'package:table_calendar/table_calendar.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import '../models/player.dart';
import '../services/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:flutter_google_places_hoc081098/flutter_google_places_hoc081098.dart';
import 'package:google_maps_webservice/places.dart';

class ScheduleEvent {
  final String id;
  final String title;
  final DateTime dateTime;
  final String location;
  final String eventType; // 'match' or 'training'
  final List<String> participantIds;
  final LatLng? coordinates;
  final String? opponent; // Only for matches

  ScheduleEvent({
    required this.id,
    required this.title,
    required this.dateTime,
    required this.location,
    required this.eventType,
    required this.participantIds,
    this.coordinates,
    this.opponent,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'dateTime': Timestamp.fromDate(dateTime),
      'location': location,
      'eventType': eventType,
      'participantIds': participantIds,
      'coordinates': coordinates != null
          ? GeoPoint(coordinates!.latitude, coordinates!.longitude)
          : null,
      'opponent': opponent,
    };
  }

  factory ScheduleEvent.fromMap(Map<String, dynamic> map) {
    final timestamp = map['dateTime'] as Timestamp;
    final geoPoint = map['coordinates'] as GeoPoint?;

    return ScheduleEvent(
      id: map['id'],
      title: map['title'],
      dateTime: timestamp.toDate(),
      location: map['location'],
      eventType: map['eventType'],
      participantIds: List<String>.from(map['participantIds']),
      coordinates: geoPoint != null
          ? LatLng(geoPoint.latitude, geoPoint.longitude)
          : null,
      opponent: map['opponent'],
    );
  }
}

class ScheduleScreen extends StatefulWidget {
  @override
  _ScheduleScreenState createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = Uuid();

  String location = '';
  LatLng? coordinates;
  List<Player> _players = [];
  List<ScheduleEvent> _events = [];

  List<Prediction> _predictions = [];
  bool _showPredictions = false;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  final FocusNode _locationFocusNode = FocusNode();

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<ScheduleEvent>> _groupedEvents = {};

  final String kGoogleApiKey = "AIzaSyB1jPJtxXlJcQxoPEeoC6hZV0Y-vXm63H4";

  GoogleMapsPlaces? _places;

  Timer? _debounce;

  // Controllers
  final TextEditingController _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _places = GoogleMapsPlaces(apiKey: kGoogleApiKey);
    _loadPlayers();
    _loadEvents();
  }

  Future<void> _geocodeAddress(
      String address, Function(LatLng) onLocationFound) async {
    try {
      List<geocoding.Location> locations =
          await geocoding.locationFromAddress(address);
      if (locations.isNotEmpty) {
        final lat = locations.first.latitude;
        final lng = locations.first.longitude;
        onLocationFound(LatLng(lat, lng));
      }
    } catch (e) {
      print('Error geocoding address: $e');
      // You might want to show a snackbar or toast here
    }
  }

  Future<void> _loadPlayers() async {
    _firebaseService.getPlayers().listen((players) {
      setState(() {
        _players = players;
      });
    });
  }

  Future<void> _loadEvents() async {
    try {
      final snapshot = await _firestore.collection('scheduleEvents').get();
      final events = snapshot.docs
          .map((doc) => ScheduleEvent.fromMap(doc.data()))
          .toList();

      // Group events by date
      final groupedEvents = <DateTime, List<ScheduleEvent>>{};
      for (final event in events) {
        final date = DateTime(
          event.dateTime.year,
          event.dateTime.month,
          event.dateTime.day,
        );

        if (groupedEvents[date] != null) {
          groupedEvents[date]!.add(event);
        } else {
          groupedEvents[date] = [event];
        }
      }

      setState(() {
        _events = events;
        _groupedEvents = groupedEvents;
      });
    } catch (e) {
      print('Error loading events: $e');
    }
  }

  Future<void> _fetchPredictions(String input, StateSetter setState) async {
    if (input.isEmpty) {
      setState(() {
        _predictions = [];
        _removeOverlay();
      });
      return;
    }

    try {
      final PlacesAutocompleteResponse response = await _places!.autocomplete(
        input,
        components: [Component(Component.country, "my")],
        types: [], // You can specify types like 'address' if needed
      );

      if (response.status == "OK") {
        setState(() {
          _predictions = response.predictions;
          if (_predictions.isNotEmpty) {
            _showOverlay(context, setState);
          } else {
            _removeOverlay();
          }
        });
      } else {
        print("Autocomplete error: ${response.errorMessage}");
        setState(() {
          _predictions = [];
          _removeOverlay();
        });
      }
    } catch (e) {
      print("Error fetching predictions: $e");
      setState(() {
        _predictions = [];
        _removeOverlay();
      });
    }
  }

  void _showOverlay(BuildContext context, StateSetter mainSetState) {
    if (_overlayEntry != null) {
      _removeOverlay();
    }

    // Create the overlay
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width * 0.85,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0.0, 55.0), // Adjust based on your text field height
          child: Material(
            elevation: 4.0,
            child: Container(
              height: min(240, _predictions.length * 60.0), // Limit height
              color: Colors.white,
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _predictions.length,
                separatorBuilder: (context, index) => Divider(height: 1),
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: Icon(Icons.location_on),
                    title: Text(_predictions[index].description ?? ""),
                    onTap: () {
                      _processPlacePrediction(
                          _predictions[index], _places!, mainSetState);
                      _removeOverlay();
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  List<ScheduleEvent> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _groupedEvents[normalizedDay] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Team Schedule'),
        backgroundColor: Colors.orange,
      ),
      body: Column(
        children: [
          _buildCalendar(),
          Expanded(
            child: _buildEventsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEventDialog(),
        child: Icon(Icons.add),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Widget _buildCalendar() {
    return Card(
      margin: EdgeInsets.all(8.0),
      elevation: 2.0,
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: CalendarFormat.month,
        eventLoader: _getEventsForDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        calendarStyle: CalendarStyle(
          markersMaxCount: 3,
          todayDecoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: Colors.orange,
            shape: BoxShape.circle,
          ),
          markerDecoration: BoxDecoration(
            color: Colors.orange,
            shape: BoxShape.circle,
          ),
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
        ),
      ),
    );
  }

  Widget _buildEventsList() {
    final selectedDayEvents = _getEventsForDay(_selectedDay!);

    if (selectedDayEvents.isEmpty) {
      return Center(
        child: Text(
          'No events scheduled for this day.\nTap + to add a new event.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(8.0),
      itemCount: selectedDayEvents.length,
      itemBuilder: (context, index) {
        final event = selectedDayEvents[index];
        return _buildEventCard(event);
      },
    );
  }

  ImageProvider? _getPlayerImage(Player player) {
    if (player.imageBase64 != null) {
      return MemoryImage(base64Decode(player.imageBase64!));
    }
    return null;
  }

  Widget _buildEventCard(ScheduleEvent event) {
    // Get participating players
    final participatingPlayers = _players
        .where((player) => event.participantIds.contains(player.id))
        .toList();

    return Card(
      margin: EdgeInsets.only(bottom: 12.0),
      elevation: 2.0,
      child: InkWell(
        onTap: () => _showEventDetails(event),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        event.eventType == 'match'
                            ? Icons.sports_basketball
                            : Icons.fitness_center,
                        color: Colors.orange,
                      ),
                      SizedBox(width: 8),
                      Text(
                        event.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Chip(
                    label: Text(
                      event.eventType.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                    backgroundColor:
                        event.eventType == 'match' ? Colors.green : Colors.blue,
                    padding: EdgeInsets.symmetric(horizontal: 8),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey),
                  SizedBox(width: 8),
                  Text(
                    '${event.dateTime.hour.toString().padLeft(2, '0')}:${event.dateTime.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  SizedBox(width: 16),
                  Icon(Icons.location_on, size: 16, color: Colors.grey),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      event.location,
                      style: TextStyle(color: Colors.grey[700]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                'Players (${participatingPlayers.length}):',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: participatingPlayers
                    .map((player) => Chip(
                          avatar: CircleAvatar(
                            backgroundImage: _getPlayerImage(player),
                            child: player.imageBase64 == null
                                ? Icon(Icons.person)
                                : null,
                          ),
                          label:
                              Text(player.name, style: TextStyle(fontSize: 12)),
                          padding: EdgeInsets.all(4),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ))
                    .toList(),
              ),
              if (event.eventType == 'match' && event.opponent != null) ...[
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.sports_basketball,
                        size: 16, color: Colors.orange),
                    SizedBox(width: 8),
                    Text(
                      'Opponent: ${event.opponent}',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showEventDetails(ScheduleEvent event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(event.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Type: ${event.eventType.toUpperCase()}'),
              SizedBox(height: 8),
              Text(
                  'Time: ${event.dateTime.hour.toString().padLeft(2, '0')}:${event.dateTime.minute.toString().padLeft(2, '0')}'),
              SizedBox(height: 8),
              Text('Location: ${event.location}'),
              SizedBox(height: 16),
              if (event.coordinates != null) ...[
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                  ),
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: event.coordinates!,
                      zoom: 14,
                    ),
                    markers: {
                      Marker(
                        markerId: MarkerId(event.id),
                        position: event.coordinates!,
                      ),
                    },
                    zoomControlsEnabled: false,
                    scrollGesturesEnabled: false,
                  ),
                ),
                SizedBox(height: 16),
              ],
              Text(
                'Participating Players:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              ...event.participantIds.map((playerId) {
                final player = _players.firstWhere(
                  (p) => p.id == playerId,
                  orElse: () => Player(
                    id: playerId,
                    name: 'Unknown Player',
                    height: 0,
                    weight: 0,
                    age: 0,
                    team: '',
                    position: '',
                  ),
                );
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 2),
                  child: Text('• ${player.name}'),
                );
              }).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showAddEventDialog(event: event);
            },
            child: Text('Edit'),
          ),
          TextButton(
            onPressed: () => _showDeleteConfirmation(event),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(ScheduleEvent event) {
    Navigator.pop(context); // Close details dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Event'),
        content: Text(
            'Are you sure you want to delete "${event.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _deleteEvent(event);
              Navigator.pop(context);
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEvent(ScheduleEvent event) async {
    try {
      await _firestore.collection('scheduleEvents').doc(event.id).delete();
      _loadEvents(); // Refresh events
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Event deleted successfully')),
      );
    } catch (e) {
      print('Error deleting event: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete event')),
      );
    }
  }

  void _showAddEventDialog({ScheduleEvent? event}) {
    final bool isEditing = event != null;

    // Form state variables
    final _formKey = GlobalKey<FormState>();
    String eventType = event?.eventType ?? 'match';
    String title = event?.title ?? '';
    String location = event?.location ?? '';
    String? opponent = event?.opponent ?? '';
    DateTime dateTime = event?.dateTime ?? _selectedDay!;
    List<String> selectedPlayerIds = event?.participantIds ?? [];
    LatLng? coordinates = event?.coordinates;

    GoogleMapController? _mapController;

    _locationController.text = location;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Event' : 'Add New Event'),
              content: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Event Type Selection
                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<String>(
                                title: Text('Match'),
                                value: 'match',
                                groupValue: eventType,
                                onChanged: (value) {
                                  setState(() {
                                    eventType = value!;
                                  });
                                },
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<String>(
                                title: Text('Training'),
                                value: 'training',
                                groupValue: eventType,
                                onChanged: (value) {
                                  setState(() {
                                    eventType = value!;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),

                        // Title Field
                        TextFormField(
                          initialValue: title,
                          decoration: InputDecoration(
                            labelText: 'Title',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a title';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            title = value;
                          },
                        ),
                        SizedBox(height: 16),

                        // Date and Time Picker
                        Row(
                          children: [
                            Icon(Icons.calendar_today),
                            SizedBox(width: 8),
                            Text(
                              '${dateTime.day}/${dateTime.month}/${dateTime.year}',
                              style: TextStyle(fontSize: 16),
                            ),
                            SizedBox(width: 16),
                            TextButton(
                              onPressed: () async {
                                DatePicker.showDatePicker(
                                  context,
                                  showTitleActions: true,
                                  minTime: DateTime.now(),
                                  maxTime: DateTime(2030, 12, 31),
                                  onConfirm: (date) {
                                    setState(() {
                                      dateTime = DateTime(
                                        date.year,
                                        date.month,
                                        date.day,
                                        dateTime.hour,
                                        dateTime.minute,
                                      );
                                    });
                                  },
                                  currentTime: dateTime,
                                );
                              },
                              child: Text('Change Date'),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.access_time),
                            SizedBox(width: 8),
                            Text(
                              '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(fontSize: 16),
                            ),
                            SizedBox(width: 16),
                            TextButton(
                              onPressed: () {
                                DatePicker.showTimePicker(
                                  context,
                                  showTitleActions: true,
                                  onConfirm: (time) {
                                    setState(() {
                                      dateTime = DateTime(
                                        dateTime.year,
                                        dateTime.month,
                                        dateTime.day,
                                        time.hour,
                                        time.minute,
                                      );
                                    });
                                  },
                                  currentTime: dateTime,
                                );
                              },
                              child: Text('Change Time'),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),

                        // Location Field
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CompositedTransformTarget(
                              link: _layerLink,
                              child: TextFormField(
                                controller: _locationController,
                                focusNode: _locationFocusNode,
                                decoration: InputDecoration(
                                  labelText: 'Location',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.location_on),
                                  suffixIcon: IconButton(
                                    icon: Icon(Icons.search),
                                    onPressed: () async {
                                      // Show Place Autocomplete when search icon is clicked
                                      final Prediction? prediction =
                                          await PlacesAutocomplete.show(
                                        context: context,
                                        apiKey: kGoogleApiKey,
                                        mode: Mode.overlay,
                                        types: [],
                                        strictbounds: false,
                                        components: [
                                          Component(Component.country, "my")
                                        ],
                                        hint: 'Search for a location',
                                        onError: (err) {
                                          print("Places API error: $err");
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content: Text(
                                                    'Error loading place suggestions')),
                                          );
                                        },
                                      );

                                      if (prediction != null &&
                                          prediction.placeId != null) {
                                        _processPlacePrediction(prediction,
                                            _places!, setState, _mapController);
                                      }
                                    },
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a location';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  location = value;

                                  // Debounce mechanism to avoid too many API calls
                                  if (_debounce?.isActive ?? false)
                                    _debounce!.cancel();
                                  _debounce = Timer(
                                      const Duration(milliseconds: 800), () {
                                    // Only fetch predictions if enough text is entered
                                    if (value.length > 2) {
                                      _fetchPredictions(value, setState);
                                    } else {
                                      setState(() {
                                        _predictions = [];
                                        _removeOverlay();
                                      });
                                    }
                                  });
                                },
                                onTap: () {
                                  if (_predictions.isNotEmpty) {
                                    _showOverlay(context, setState);
                                  }
                                },
                              ),
                            ),
                            // We don't need to display predictions here as we'll use overlay
                          ],
                        ),
                        SizedBox(height: 16),

                        // Map for Location Selection
                        Text('Location on Map:'),
                        SizedBox(height: 8),
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                          ),
                          child: GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: coordinates ?? LatLng(4.3348, 101.1351),
                              zoom: 14,
                            ),
                            onTap: (position) {
                              setState(() {
                                coordinates = position;
                                _reverseGeocode(position, (address) {
                                  setState(() {
                                    _locationController.text = address;
                                    location = address;
                                  });
                                });
                              });
                            },
                            markers: coordinates != null
                                ? {
                                    Marker(
                                      markerId: MarkerId('selectedLocation'),
                                      position: coordinates!,
                                    ),
                                  }
                                : {},
                            onMapCreated: (GoogleMapController controller) {
                              _mapController = controller;
                            },
                          ),
                        ),
                        SizedBox(height: 16),

                        // Opponent field (only for matches)
                        if (eventType == 'match') ...[
                          TextFormField(
                            initialValue: opponent,
                            decoration: InputDecoration(
                              labelText: 'Opponent Team',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              opponent = value;
                            },
                          ),
                          SizedBox(height: 16),
                        ],

                        // Player Selection
                        Text(
                          'Select Players (at least 5):',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${selectedPlayerIds.length} player(s) selected',
                          style: TextStyle(
                            color: selectedPlayerIds.length >= 5
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: _players.isEmpty
                              ? Center(child: Text('No players available'))
                              : ListView.builder(
                                  itemCount: _players.length,
                                  itemBuilder: (context, index) {
                                    final player = _players[index];
                                    final isSelected =
                                        selectedPlayerIds.contains(player.id);

                                    return CheckboxListTile(
                                      title: Text(player.name),
                                      subtitle: Text(player.position),
                                      value: isSelected,
                                      onChanged: (selected) {
                                        setState(() {
                                          if (selected == true) {
                                            selectedPlayerIds.add(player.id);
                                          } else {
                                            selectedPlayerIds.remove(player.id);
                                          }
                                        });
                                      },
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      if (selectedPlayerIds.length < 5) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Please select at least 5 players'),
                          ),
                        );
                        return;
                      }

                      final scheduleEvent = ScheduleEvent(
                        id: event?.id ?? _uuid.v4(),
                        title: title,
                        dateTime: dateTime,
                        location: location,
                        eventType: eventType,
                        participantIds: selectedPlayerIds,
                        coordinates: coordinates,
                        opponent: eventType == 'match' ? opponent : null,
                      );

                      _saveEvent(scheduleEvent);
                      Navigator.pop(context);
                    }
                  },
                  child: Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveEvent(ScheduleEvent event) async {
    try {
      await _firestore
          .collection('scheduleEvents')
          .doc(event.id)
          .set(event.toMap());

      _loadEvents(); // Refresh events

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Event saved successfully')),
      );
    } catch (e) {
      print('Error saving event: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save event')),
      );
    }
  }

  void _processPlacePrediction(
      Prediction prediction, GoogleMapsPlaces places, StateSetter setState,
      [GoogleMapController? mapController]) async {
    try {
      // Get place details
      PlacesDetailsResponse detail = await places.getDetailsByPlaceId(
        prediction.placeId!,
      );

      if (detail.status == 'OK' && detail.result != null) {
        // Update location text and coordinates
        final selectedPlace = detail.result;
        if (selectedPlace.geometry?.location != null) {
          final lat = selectedPlace.geometry!.location.lat;
          final lng = selectedPlace.geometry!.location.lng;

          setState(() {
            _locationController.text =
                selectedPlace.formattedAddress ?? prediction.description ?? '';
            location = _locationController.text;
            coordinates = LatLng(lat, lng);

            // Update map position
            if (mapController != null) {
              mapController.animateCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(
                    target: coordinates!,
                    zoom: 14,
                  ),
                ),
              );
            }
          });
        } else {
          // Handle missing geometry
          setState(() {
            _locationController.text = prediction.description ?? '';
            location = _locationController.text;
          });
          print('Warning: Location geometry not found in place details');
        }
      } else {
        // Handle API status not OK
        setState(() {
          _locationController.text = prediction.description ?? '';
          location = _locationController.text;
        });
        print('Place details API error: ${detail.status}');
      }
    } catch (e) {
      // Handle exception in API call
      setState(() {
        _locationController.text = prediction.description ?? '';
        location = _locationController.text;
      });
      print('Error getting place details: $e');
    }
  }

//cancel the timer when the dialog closes
  @override
  void dispose() {
    _debounce?.cancel();
    _overlayEntry?.remove();
    _locationFocusNode.dispose();
    super.dispose();
  }

  Future<void> _reverseGeocode(
      LatLng position, Function(String) onAddressFound) async {
    try {
      List<geocoding.Placemark> placemarks =
          await geocoding.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        geocoding.Placemark place = placemarks.first;
        String address = '';

        // Build address from components
        if (place.street != null && place.street!.isNotEmpty) {
          address += place.street!;
        }
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          address += address.isNotEmpty
              ? ', ${place.subLocality}'
              : place.subLocality!;
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          address +=
              address.isNotEmpty ? ', ${place.locality}' : place.locality!;
        }
        if (place.postalCode != null && place.postalCode!.isNotEmpty) {
          address +=
              address.isNotEmpty ? ', ${place.postalCode}' : place.postalCode!;
        }
        if (place.country != null && place.country!.isNotEmpty) {
          address += address.isNotEmpty ? ', ${place.country}' : place.country!;
        }

        onAddressFound(address);
      }
    } catch (e) {
      print('Error reverse geocoding: $e');
    }
  }
}
