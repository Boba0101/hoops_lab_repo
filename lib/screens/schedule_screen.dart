import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:uuid/uuid.dart';
// --- THE ONLY PLACES IMPORT NEEDED ---
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart'
    as places_sdk;

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
  final int? ourScore;
  final int? opponentScore;

  ScheduleEvent(
      {required this.id,
      required this.title,
      required this.dateTime,
      required this.location,
      required this.eventType,
      required this.participantIds,
      this.coordinates,
      this.opponent,
      this.ourScore,
      this.opponentScore});
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
        'opponent': opponent,
        'ourScore': ourScore,
        'opponentScore': opponentScore
      };
  factory ScheduleEvent.fromMap(Map<String, dynamic> map) {
    List<String> participants = [];
    if (map['participantIds'] is List) {
      participants =
          List<String>.from(map['participantIds'].where((id) => id is String));
    }
    final utcTimestamp =
        (map['dateTime'] as Timestamp?)?.toDate() ?? DateTime.now().toUtc();
    return ScheduleEvent(
        id: map['id'] ?? Uuid().v4(),
        title: map['title'] ?? 'Untitled Event',
        dateTime: utcTimestamp.toLocal(),
        location: map['location'] ?? 'Unknown Location',
        eventType: map['eventType'] ?? 'match',
        participantIds: participants,
        coordinates: (map['coordinates'] as GeoPoint?) != null
            ? LatLng(map['coordinates'].latitude, map['coordinates'].longitude)
            : null,
        opponent: map['opponent'],
        ourScore: map['ourScore'],
        opponentScore: map['opponentScore']);
  }
}

// --- Main Screen Widget ---
class ScheduleScreen extends StatefulWidget {
  @override
  _ScheduleScreenState createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  // All state and methods for the main screen are correct.
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
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
              onSave: (newEvent) => _saveEvent(newEvent));
        });
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
                final player = _players.firstWhere((p) => p.userId == playerId,
                    orElse: () => User(
                        userId: playerId,
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
          : RefreshIndicator(
              key: _refreshIndicatorKey,
              onRefresh: _loadEvents,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _buildCalendar()),
                  _buildEventsSliverList(),
                ],
              ),
            ),
      floatingActionButton: _currentUserRole == 'Coach'
          ? FloatingActionButton(
              onPressed: () => _showAddEventDialog(),
              child: Icon(Icons.add),
              backgroundColor: Colors.orange)
          : null,
    );
  }

  Widget _buildEventsSliverList() {
    final selectedDayEvents = _getEventsForDay(_selectedDay!);
    if (selectedDayEvents.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
            padding: const EdgeInsets.all(48.0),
            child: Center(
              child: Text(
                  _currentUserRole == 'Coach'
                      ? 'No events scheduled for this day.\nTap + to add a new event.'
                      : 'No events scheduled for this day.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey)),
            )),
      );
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final event = selectedDayEvents[index];
        return _buildEventCard(event);
      }, childCount: selectedDayEvents.length),
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
        .where((player) => event.participantIds.contains(player.userId))
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

  // Form state variables
  late String eventType, title, location;
  String? opponent;
  late DateTime dateTime;
  late List<String> selectedPlayerIds;
  LatLng? coordinates;
  GoogleMapController? _mapController;
  late TextEditingController _locationController;
  Timer? _debounce;

  // --- THIS IS THE FIX ---
  // A Future that will hold our initialized places client.
  late Future<places_sdk.FlutterGooglePlacesSdk?> _placesSdkFuture;
  places_sdk.FlutterGooglePlacesSdk? _places; // The actual client instance
  List<places_sdk.AutocompletePrediction> _placePredictions = [];
  final FocusNode _locationFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Start the async initialization process.
    _placesSdkFuture = _initializePlacesSdk();

    // Initialize all the NON-ASYNC state variables here.
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
      if (!_locationFocusNode.hasFocus && mounted) {
        setState(() => _placePredictions = []);
      }
    });
  }

  // A dedicated async method to securely get the key and create the client.
  Future<places_sdk.FlutterGooglePlacesSdk?> _initializePlacesSdk() async {
    try {
      const MethodChannel channel =
          MethodChannel('com.example.hoops_lab_v1/native_secrets');
      final String? apiKey = await channel.invokeMethod('getMapsApiKey');

      if (apiKey != null && apiKey.isNotEmpty) {
        print('--- Successfully loaded Maps API Key from native side. ---');
        _places = places_sdk.FlutterGooglePlacesSdk(apiKey);
        return _places;
      } else {
        print(
            '--- WARNING: Maps API Key from native side is null or empty. ---');
        return null;
      }
    } catch (e) {
      print('--- ERROR fetching Maps API Key from native: $e ---');
      return null;
    }
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
    final response =
        await _places!.findAutocompletePredictions(input, countries: ['my']);
    if (mounted) setState(() => _placePredictions = response.predictions);
  }

  Future<void> _onPredictionSelected(
      places_sdk.AutocompletePrediction prediction) async {
    if (_places == null) return;
    _locationFocusNode.unfocus();
    final detailsResponse = await _places!.fetchPlace(prediction.placeId,
        fields: [
          places_sdk.PlaceField.Address,
          places_sdk.PlaceField.Location
        ]);
    if (detailsResponse.place != null && mounted) {
      final place = detailsResponse.place!;
      final newCoords = LatLng(place.latLng!.lat, place.latLng!.lng);
      final newAddress = place.address ?? prediction.fullText;
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

  void _onSavePressed() {
    if (!_formKey.currentState!.validate()) return;
    final minPlayers = eventType == 'match' ? 5 : 1;
    if (selectedPlayerIds.length < minPlayers) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Please select at least $minPlayers player(s).')));
      return;
    }
    final utcDateTime = dateTime.toUtc();
    final newEvent = ScheduleEvent(
        id: widget.event?.id ?? Uuid().v4(),
        title: title,
        dateTime: utcDateTime,
        location: location,
        eventType: eventType,
        participantIds: selectedPlayerIds,
        coordinates: coordinates,
        opponent: eventType == 'match' ? opponent : null);
    widget.onSave(newEvent);
    Navigator.pop(context);
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
                FutureBuilder<places_sdk.FlutterGooglePlacesSdk?>(
                  future: _placesSdkFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                          child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text("Initializing location service...")));
                    }
                    if (snapshot.hasError ||
                        !snapshot.hasData ||
                        snapshot.data == null) {
                      return Text(
                          "Error: Could not initialize location service. Please check your API key.",
                          style: TextStyle(color: Colors.red));
                    }

                    // Once the future is complete, we build the real text field.
                    return TextFormField(
                      controller: _locationController,
                      focusNode: _locationFocusNode,
                      decoration: InputDecoration(
                          labelText: 'Location', border: OutlineInputBorder()),
                      validator: (v) =>
                          v!.isEmpty ? 'Please enter a location' : null,
                      onChanged: (value) {
                        location = value;
                        if (_debounce?.isActive ?? false) _debounce!.cancel();
                        _debounce = Timer(const Duration(milliseconds: 500),
                            () => _fetchPlacePredictions(value));
                      },
                    );
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
                          title: Text(prediction.fullText),
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
                Text('Select Players'),
                Text('${selectedPlayerIds.length} selected',
                    style: TextStyle(
                        color: selectedPlayerIds.length >=
                                (eventType == 'match' ? 5 : 1)
                            ? Colors.green
                            : Colors.red)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                        child: Text("Select All"),
                        onPressed: () => setState(() => selectedPlayerIds =
                            widget.players.map((p) => p.userId).toList())),
                    TextButton(
                        child: Text("Deselect All"),
                        onPressed: () =>
                            setState(() => selectedPlayerIds = [])),
                  ],
                ),
                Container(
                  height: 200,
                  decoration:
                      BoxDecoration(border: Border.all(color: Colors.grey)),
                  child: ListView.builder(
                    itemCount: widget.players.length,
                    itemBuilder: (context, index) {
                      final player = widget.players[index];
                      final isSelected =
                          selectedPlayerIds.contains(player.userId);
                      return CheckboxListTile(
                        title: Text(player.name ?? 'Unknown'),
                        subtitle: Text(player.position ?? 'N/A'),
                        value: isSelected,
                        onChanged: (selected) => setState(() {
                          if (selected!)
                            selectedPlayerIds.add(player.userId);
                          else
                            selectedPlayerIds.remove(player.userId);
                        }),
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
            onPressed: () => Navigator.pop(context), child: Text('Cancel')),
        ElevatedButton(onPressed: _onSavePressed, child: Text('Save')),
      ],
    );
  }
}
