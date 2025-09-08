// lib/screens/schedule_screen.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/services.dart';

import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';

// --- Screen-Specific Model ---
class ScheduleEvent {
  final String id, title, location, eventType;
  final DateTime dateTime;
  final List<String> participantIds;
  final LatLng? coordinates;
  final String? opponent;

  ScheduleEvent(
      {required this.id,
      required this.title,
      required this.dateTime,
      required this.location,
      required this.eventType,
      required this.participantIds,
      this.coordinates,
      this.opponent});
  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'dateTime': Timestamp.fromDate(dateTime),
        'location': location,
        'eventType': eventType,
        'participantIds': participantIds,
        'coordinates': coordinates != null
            ? GeoPoint(coordinates!.latitude, coordinates!.longitude)
            : null,
        'opponent': opponent
      };
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
        opponent: map['opponent']);
  }
}

// --- Main Screen Widget ---
class ScheduleScreen extends StatefulWidget {
  @override
  _ScheduleScreenState createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  String? _currentUserRole;
  bool _isLoadingRole = true;
  late FirebaseService _firebaseService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription? _playersSubscription;
  List<User> _players = [];
  Map<DateTime, List<ScheduleEvent>> _groupedEvents = {};
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _firebaseService = Provider.of<FirebaseService>(context, listen: false);
      _fetchCurrentUserRole();
      _loadPlayers();
      _loadEvents();
    });
  }

  @override
  void dispose() {
    _playersSubscription?.cancel();
    super.dispose();
  }

  Future<void> _fetchCurrentUserRole() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.currentUser != null) {
      final user =
          await _firebaseService.getUserById(authService.currentUser!.uid);
      if (mounted)
        setState(() {
          _currentUserRole = user?.role;
          _isLoadingRole = false;
        });
    } else {
      if (mounted) setState(() => _isLoadingRole = false);
    }
  }

  void _loadPlayers() {
    _playersSubscription =
        _firebaseService.getPlayersStream().listen((players) {
      if (mounted) setState(() => _players = players);
    });
  }

  Future<void> _loadEvents() async {
    try {
      final snapshot = await _firestore
          .collection('scheduleEvents')
          .orderBy('dateTime')
          .get();
      final events = snapshot.docs
          .map((doc) => ScheduleEvent.fromMap(doc.data()))
          .toList();
      final groupedEvents = <DateTime, List<ScheduleEvent>>{};
      for (final event in events) {
        final date = DateTime(
            event.dateTime.year, event.dateTime.month, event.dateTime.day);
        groupedEvents.putIfAbsent(date, () => []).add(event);
      }
      if (mounted) setState(() => _groupedEvents = groupedEvents);
    } catch (e) {
      print('Error loading events: $e');
    }
  }

  void _saveEvent(ScheduleEvent event) async {
    try {
      await _firestore
          .collection('scheduleEvents')
          .doc(event.id)
          .set(event.toMap());
      _loadEvents();
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Event saved successfully'),
            backgroundColor: Colors.green));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed to save event'),
            backgroundColor: Colors.red));
    }
  }

  void _deleteEvent(ScheduleEvent event) async {
    try {
      await _firestore.collection('scheduleEvents').doc(event.id).delete();
      _loadEvents();
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Event deleted successfully')));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed to delete event'),
            backgroundColor: Colors.red));
    }
  }

  void _showAddEventDialog({ScheduleEvent? event}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return _AddEventDialog(
          event: event,
          selectedDay: _selectedDay!,
          players: _players,
          onSave: (newEvent) => _saveEvent(newEvent),
        );
      },
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
                  'Time: ${TimeOfDay.fromDateTime(event.dateTime).format(context)}'),
              SizedBox(height: 8),
              Text('Location: ${event.location}'),
              if (event.coordinates != null) ...[
                SizedBox(height: 16),
                Container(
                    height: 150,
                    child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                            target: event.coordinates!, zoom: 14),
                        markers: {
                          Marker(
                              markerId: MarkerId(event.id),
                              position: event.coordinates!)
                        },
                        zoomControlsEnabled: false)),
              ],
              SizedBox(height: 16),
              Text('Participating Players:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              ...event.participantIds.map((playerId) {
                final player = _players.firstWhere((p) => p.id == playerId,
                    orElse: () => User(
                        id: playerId,
                        email: '',
                        role: 'Player',
                        createdAt: DateTime.now(),
                        name: 'Unknown Player'));
                return Padding(
                    padding: EdgeInsets.symmetric(vertical: 2),
                    child: Text('• ${player.name}'));
              }).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text('Close')),
          if (_currentUserRole == 'Coach') ...[
            TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showAddEventDialog(event: event);
                },
                child: Text('Edit')),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text('Delete Event'),
                    content: Text(
                        'Are you sure you want to delete "${event.title}"?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text('Cancel')),
                      TextButton(
                          onPressed: () {
                            _deleteEvent(event);
                            Navigator.pop(ctx);
                          },
                          child: Text('Delete',
                              style: TextStyle(color: Colors.red))),
                    ],
                  ),
                );
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ]
        ],
      ),
    );
  }

  List<ScheduleEvent> _getEventsForDay(DateTime day) =>
      _groupedEvents[DateTime(day.year, day.month, day.day)] ?? [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoadingRole
          ? Center(child: CircularProgressIndicator(color: Colors.orange))
          : Column(
              children: [
                _buildCalendar(),
                Expanded(child: _buildEventsList()),
              ],
            ),
      floatingActionButton: _currentUserRole == 'Coach'
          ? FloatingActionButton(
              onPressed: () => _showAddEventDialog(),
              child: Icon(Icons.add),
              backgroundColor: Colors.orange)
          : null,
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
                todayDecoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.5),
                    shape: BoxShape.circle),
                selectedDecoration:
                    BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                markerDecoration: BoxDecoration(
                    color: Colors.orange, shape: BoxShape.circle)),
            headerStyle:
                HeaderStyle(formatButtonVisible: false, titleCentered: true)));
  }

  Widget _buildEventsList() {
    final selectedDayEvents = _getEventsForDay(_selectedDay!);
    if (selectedDayEvents.isEmpty) {
      return Center(
          child: Text(
              _currentUserRole == 'Coach'
                  ? 'No events scheduled for this day.\nTap + to add a new event.'
                  : 'No events scheduled for this day.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
        padding: EdgeInsets.all(8.0),
        itemCount: selectedDayEvents.length,
        itemBuilder: (context, index) {
          final event = selectedDayEvents[index];
          return _buildEventCard(event);
        });
  }

  Widget _buildEventCard(ScheduleEvent event) {
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
                            Flexible(
                                child: Row(children: [
                              Icon(
                                  event.eventType == 'match'
                                      ? Icons.sports_basketball
                                      : Icons.fitness_center,
                                  color: Colors.orange),
                              SizedBox(width: 8),
                              Flexible(
                                  child: Text(event.title,
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis))
                            ])),
                            Chip(
                                label: Text(event.eventType.toUpperCase(),
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 12)),
                                backgroundColor: event.eventType == 'match'
                                    ? Colors.green
                                    : Colors.blue)
                          ]),
                      SizedBox(height: 12),
                      Row(children: [
                        Icon(Icons.access_time, size: 16, color: Colors.grey),
                        SizedBox(width: 8),
                        Text(TimeOfDay.fromDateTime(event.dateTime)
                            .format(context)),
                        SizedBox(width: 16),
                        Icon(Icons.location_on, size: 16, color: Colors.grey),
                        SizedBox(width: 8),
                        Expanded(
                            child: Text(event.location,
                                overflow: TextOverflow.ellipsis))
                      ]),
                      SizedBox(height: 12),
                      Text('Players (${participatingPlayers.length}):',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Wrap(
                          spacing: 8.0,
                          runSpacing: 4.0,
                          children: participatingPlayers
                              .map((player) => Chip(
                                  avatar: CircleAvatar(
                                      backgroundColor:
                                          Colors.orange.withOpacity(0.2),
                                      child: Text(
                                          player.name
                                                  ?.substring(0, 1)
                                                  .toUpperCase() ??
                                              'P',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.orange))),
                                  label: Text(player.name ?? 'Unknown',
                                      style: TextStyle(fontSize: 12))))
                              .toList()),
                      if (event.eventType == 'match' &&
                          event.opponent != null) ...[
                        SizedBox(height: 12),
                        Row(children: [
                          Icon(Icons.people_alt, size: 16, color: Colors.grey),
                          SizedBox(width: 8),
                          Text('Opponent: ${event.opponent}',
                              style: TextStyle(fontWeight: FontWeight.w500))
                        ])
                      ]
                    ]))));
  }
}

// =======================================================================
// FINAL, VERIFIED, AND SELF-CONTAINED DIALOG WIDGET
// =======================================================================
class _AddEventDialog extends StatefulWidget {
  final ScheduleEvent? event;
  final DateTime selectedDay;
  final List<User> players;
  final Function(ScheduleEvent) onSave;

  const _AddEventDialog(
      {Key? key,
      this.event,
      required this.selectedDay,
      required this.players,
      required this.onSave})
      : super(key: key);

  @override
  __AddEventDialogState createState() => __AddEventDialogState();
}

class __AddEventDialogState extends State<_AddEventDialog> {
  final _formKey = GlobalKey<FormState>();
  late String eventType, title, location;
  String? opponent;
  late DateTime dateTime;
  late List<String> selectedPlayerIds;
  LatLng? coordinates;
  GoogleMapController? _mapController;
  late TextEditingController _locationController;
  Timer? _debounce;
  GoogleMapsPlaces? _places;
  List<Prediction> _placePredictions = [];
  final FocusNode _locationFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _initializeAndSetupState();
  }

  Future<void> _initializeAndSetupState() async {
    String apiKey = '';
    try {
      // This uses a platform channel to directly ask the Android side
      // for the metadata value from the manifest. This is very reliable.
      const MethodChannel channel = MethodChannel(
          'com.example.hoops_lab_v1/metadata'); // Use your app's package name
      apiKey = await channel.invokeMethod('getApiKey');
      print('--- Manually read API Key from Manifest: "$apiKey" ---');
    } catch (e) {
      print('--- ERROR reading API Key from Manifest: $e ---');
    }

    if (apiKey.isNotEmpty) {
      _places = GoogleMapsPlaces(apiKey: apiKey);
    } else {
      print(
          '--- WARNING: API Key is still empty. Autocomplete will not work. ---');
    }

    // Initialize the rest of the state
    final e = widget.event;
    eventType = e?.eventType ?? 'match';
    title = e?.title ?? '';
    location = e?.location ?? '';
    opponent = e?.opponent;
    dateTime = e?.dateTime ?? widget.selectedDay;
    selectedPlayerIds = e?.participantIds ?? [];
    coordinates = e?.coordinates;
    _locationController = TextEditingController(text: location);

    _locationFocusNode.addListener(() {
      if (!_locationFocusNode.hasFocus) {
        if (mounted) setState(() => _placePredictions = []);
      }
    });

    // This is important to ensure the UI rebuilds after the async setup
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _locationController.dispose();
    _locationFocusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchPlacePredictions(String input) async {
    if (_places == null || input.length < 3) {
      if (mounted) setState(() => _placePredictions = []);
      return;
    }

    print('--- FETCHING PLACES for input: "$input" ---');

    final response = await _places!
        .autocomplete(input, components: [Component(Component.country, "my")]);

    // --- THIS IS THE CRUCIAL DEBUGGING PART ---
    if (response.isOkay) {
      print(
          'SUCCESS: Places API returned OK with ${response.predictions.length} predictions.');
      if (mounted) {
        setState(() {
          _placePredictions = response.predictions;
        });
      }
    } else {
      // This will tell us exactly WHY it's failing.
      print('ERROR: Places API call failed!');
      print('API Response Status: ${response.status}');
      print('API Error Message: ${response.errorMessage}');
      if (mounted) {
        setState(() {
          _placePredictions = [];
        });
      }
    }
    print('-----------------------------------------');
  }

  Future<void> _onPredictionSelected(Prediction prediction) async {
    if (_places == null || prediction.placeId == null) return;

    _locationFocusNode.unfocus();

    final details = await _places!.getDetailsByPlaceId(prediction.placeId!);
    if (details.isOkay && details.result.geometry != null && mounted) {
      final loc = details.result.geometry!.location;
      final newCoords = LatLng(loc.lat, loc.lng);
      final newAddress =
          details.result.formattedAddress ?? prediction.description ?? '';

      setState(() {
        coordinates = newCoords;
        location = newAddress;
        _locationController.text = newAddress;
        _placePredictions = [];
      });
      _mapController
          ?.animateCamera(CameraUpdate.newLatLngZoom(newCoords, 15.0));
    }
  }

  void _geocodeAddress(String address) async {
    if (address.length < 5) return;
    try {
      List<geocoding.Location> locations =
          await geocoding.locationFromAddress(address);
      if (locations.isNotEmpty && mounted) {
        final loc = locations.first;
        final newCoords = LatLng(loc.latitude, loc.longitude);
        setState(() => coordinates = newCoords);
        _mapController
            ?.animateCamera(CameraUpdate.newLatLngZoom(newCoords, 15.0));
      }
    } catch (e) {
      print("Geocoding failed: $e");
    }
  }

  void _reverseGeocode(LatLng position) async {
    try {
      List<geocoding.Placemark> placemarks = await geocoding
          .placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty && mounted) {
        final p = placemarks.first;
        final fullAddress =
            "${p.street}, ${p.subLocality}, ${p.locality}, ${p.postalCode}, ${p.country}"
                .replaceAll(RegExp(r', , '), ', ')
                .replaceAll(RegExp(r'^, |,$'), '');
        setState(() {
          location = fullAddress;
          _locationController.text = fullAddress;
        });
      }
    } catch (e) {
      print("Reverse geocoding failed: $e");
    }
  }

  void _onSavePressed() {
    if (!_formKey.currentState!.validate()) return;
    if (selectedPlayerIds.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select at least 5 players')));
      return;
    }
    final newEvent = ScheduleEvent(
      id: widget.event?.id ?? Uuid().v4(),
      title: title,
      dateTime: dateTime,
      location: location,
      eventType: eventType,
      participantIds: selectedPlayerIds,
      coordinates: coordinates,
      opponent: eventType == 'match' ? opponent : null,
    );
    widget.onSave(newEvent);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.event != null ? 'Edit Event' : 'Add New Event'),
      content: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                      child: RadioListTile<String>(
                          title: Text('Match'),
                          value: 'match',
                          groupValue: eventType,
                          onChanged: (v) => setState(() => eventType = v!))),
                  Expanded(
                      child: RadioListTile<String>(
                          title: Text('Training'),
                          value: 'training',
                          groupValue: eventType,
                          onChanged: (v) => setState(() => eventType = v!)))
                ]),
                TextFormField(
                    initialValue: title,
                    decoration: InputDecoration(
                        labelText: 'Title', border: OutlineInputBorder()),
                    validator: (v) =>
                        v!.isEmpty ? 'Please enter a title' : null,
                    onChanged: (v) => title = v),
                SizedBox(height: 16),
                Text('Date & Time'),
                Row(children: [
                  Expanded(
                      child: Text(
                          DateFormat('EEE, MMM d, yyyy').format(dateTime))),
                  TextButton(
                      child: Text('Change'),
                      onPressed: () async {
                        final newDate = await showDatePicker(
                            context: context,
                            initialDate: dateTime,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030));
                        if (newDate != null)
                          setState(() => dateTime = DateTime(
                              newDate.year,
                              newDate.month,
                              newDate.day,
                              dateTime.hour,
                              dateTime.minute));
                      })
                ]),
                Row(children: [
                  Expanded(
                      child: Text(
                          TimeOfDay.fromDateTime(dateTime).format(context))),
                  TextButton(
                      child: Text('Change'),
                      onPressed: () async {
                        final newTime = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(dateTime));
                        if (newTime != null)
                          setState(() => dateTime = DateTime(
                              dateTime.year,
                              dateTime.month,
                              dateTime.day,
                              newTime.hour,
                              newTime.minute));
                      })
                ]),
                SizedBox(height: 16),
                TextFormField(
                  controller: _locationController,
                  focusNode: _locationFocusNode,
                  decoration: InputDecoration(
                      labelText: 'Location', border: OutlineInputBorder()),
                  validator: (v) =>
                      v!.isEmpty ? 'Please enter a location' : null,
                  onChanged: (value) {
                    location = value;
                    if (_debounce?.isActive ?? false) _debounce!.cancel();
                    _debounce = Timer(const Duration(milliseconds: 700), () {
                      _fetchPlacePredictions(value);
                      _geocodeAddress(value);
                    });
                  },
                ),
                if (_placePredictions.isNotEmpty)
                  SizedBox(
                    height: 150,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _placePredictions.length,
                      itemBuilder: (context, index) {
                        final prediction = _placePredictions[index];
                        return ListTile(
                          title: Text(prediction.description ?? ''),
                          onTap: () => _onPredictionSelected(prediction),
                        );
                      },
                    ),
                  ),
                SizedBox(height: 16),
                Text('Location on Map (Tap to select)'),
                SizedBox(height: 8),
                Container(
                  height: 200,
                  decoration:
                      BoxDecoration(border: Border.all(color: Colors.grey)),
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                        target: coordinates ?? LatLng(3.1390, 101.6869),
                        zoom: 14),
                    markers: coordinates != null
                        ? {
                            Marker(
                                markerId: MarkerId('selected'),
                                position: coordinates!)
                          }
                        : {},
                    onMapCreated: (controller) => _mapController = controller,
                    onTap: (position) {
                      setState(() => coordinates = position);
                      _reverseGeocode(position);
                    },
                  ),
                ),
                SizedBox(height: 16),
                if (eventType == 'match') ...[
                  TextFormField(
                      initialValue: opponent,
                      decoration: InputDecoration(
                          labelText: 'Opponent Team',
                          border: OutlineInputBorder()),
                      onChanged: (v) => opponent = v),
                  SizedBox(height: 16)
                ],
                Text('Select Players (at least 5)',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text('${selectedPlayerIds.length} selected',
                    style: TextStyle(
                        color: selectedPlayerIds.length >= 5
                            ? Colors.green
                            : Colors.red)),
                Container(
                  height: 200,
                  decoration:
                      BoxDecoration(border: Border.all(color: Colors.grey)),
                  child: ListView.builder(
                    itemCount: widget.players.length,
                    itemBuilder: (context, index) {
                      final player = widget.players[index];
                      final isSelected = selectedPlayerIds.contains(player.id);
                      return CheckboxListTile(
                          title: Text(player.name ?? 'Unknown'),
                          subtitle: Text(player.position ?? 'N/A'),
                          value: isSelected,
                          onChanged: (selected) => setState(() {
                                if (selected!)
                                  selectedPlayerIds.add(player.id);
                                else
                                  selectedPlayerIds.remove(player.id);
                              }));
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
            onPressed: () => Navigator.pop(context), child: Text('Cancel')),
        ElevatedButton(onPressed: _onSavePressed, child: Text('Save')),
      ],
    );
  }
}
