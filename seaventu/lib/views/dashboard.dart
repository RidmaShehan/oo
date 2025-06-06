import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Beach App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Activity> activities = [];
  List<Beach> beaches = [];
  bool isLoading = true;
  bool isLoadingBeaches = true;
  bool showProfileMenu = false;
  int _currentBottomNavIndex = 0;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _fetchActivities();
    _fetchBeaches();
  }

  Future<void> _fetchActivities() async {
    try {
      setState(() => isLoading = true);
      
      final response = await http.get(
        Uri.parse('https://sea-venture.org/api/user/activities'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          activities = data.map((item) => Activity.fromJson(item)).toList();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load activities with status ${response.statusCode}');
      }
    } on TimeoutException {
      setState(() => isLoading = false);
      _showErrorSnackbar('Request timeout. Please try again');
    } on http.ClientException catch (e) {
      setState(() => isLoading = false);
      _showErrorSnackbar('Network error: ${e.message}');
    } catch (e) {
      setState(() => isLoading = false);
      _showErrorSnackbar('Failed to fetch activities: ${e.toString()}');
    }
  }

  Future<void> _fetchBeaches() async {
    try {
      setState(() => isLoadingBeaches = true);
      
      final response = await http.get(
        Uri.parse('https://sea-venture.org/api/user/beaches'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          beaches = data.map((item) => Beach.fromJson(item)).toList();
          isLoadingBeaches = false;
        });
      } else {
        throw Exception('Failed to load beaches with status ${response.statusCode}');
      }
    } on TimeoutException {
      setState(() => isLoadingBeaches = false);
      _showErrorSnackbar('Beaches request timeout. Please try again');
    } on http.ClientException catch (e) {
      setState(() => isLoadingBeaches = false);
      _showErrorSnackbar('Network error: ${e.message}');
    } catch (e) {
      setState(() => isLoadingBeaches = false);
      _showErrorSnackbar('Failed to fetch beaches: ${e.toString()}');
    }
  }

  Future<void> _handleRefresh() async {
    await Future.wait([
      _fetchActivities(),
      _fetchBeaches(),
    ]);
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Beach Explorer'),
        actions: [
          GestureDetector(
            onTap: () => setState(() => showProfileMenu = !showProfileMenu),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.blue[100],
                child: const Icon(Icons.person),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _handleRefresh,
        color: Colors.blue,
        strokeWidth: 3.0,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Activities', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildActivitiesList(),
              const SizedBox(height: 16),
              const Text('Beaches', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildBeachList(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {},
      ),
    );
  }

  Widget _buildActivitiesList() {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (activities.isEmpty) return const Text('No activities available');
    
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: activities.length,
        itemBuilder: (context, index) => _buildCircularActivityItem(activities[index]),
      ),
    );
  }

  Widget _buildCircularActivityItem(Activity activity) {
    return Container(
      width: 80,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => _showActivityDetails(activity),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blue, width: 2),
              ),
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: activity.image,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => const Icon(Icons.broken_image),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            activity.name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildBeachList() {
    if (isLoadingBeaches) return const Center(child: CircularProgressIndicator());
    if (beaches.isEmpty) return const Text('No beaches available');

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: beaches.length,
      itemBuilder: (context, index) => _buildBeachCard(beaches[index]),
    );
  }

  Widget _buildBeachCard(Beach beach) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              height: 180,
              color: Colors.blue[50],
              child: Center(
                child: Icon(Icons.beach_access, size: 60, color: Colors.blue[300]),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  beach.beachName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  beach.beachDesc,
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Chip(
                      label: Text(beach.beachType),
                      backgroundColor: Colors.blue[100],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.info_outline),
                      onPressed: () => _showBeachDetails(beach),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showActivityDetails(Activity activity) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: CachedNetworkImage(
                      imageUrl: activity.image,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 50),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(activity.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(activity.desc, style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 16),
                    _buildDetailsGrid(activity),
                    const SizedBox(height: 16),
                    _buildActionButtons(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBeachDetails(Beach beach) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Container(
                      height: 200,
                      color: Colors.blue[100],
                      child: Center(
                        child: Icon(Icons.beach_access, size: 80, color: Colors.blue),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(beach.beachName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(beach.beachDesc, style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 16),
                    _buildBeachDetails(beach),
                    const SizedBox(height: 16),
                    _buildActionButtons(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBeachDetails(Beach beach) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow(Icons.place, 'Location', 'Galle Fort Area'),
        _buildDetailRow(Icons.category, 'Beach Type', beach.beachType),
        _buildDetailRow(Icons.calendar_today, 'Added', DateFormat('MMM dd, yyyy').format(beach.createdAt)),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(value, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsGrid(Activity activity) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 3,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      children: [
        _buildDetailItem(Icons.calendar_today, 'Created', DateFormat('MMM dd, yyyy').format(activity.createdAt)),
        _buildDetailItem(Icons.update, 'Updated', DateFormat('MMM dd, yyyy').format(activity.updatedAt)),
        _buildDetailItem(Icons.category, 'Category', 'Beach Activity'),
        _buildDetailItem(Icons.star, 'Rating', '4.8/5'),
      ],
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(child: OutlinedButton(onPressed: () {}, child: const Text('okay'))),
        // const SizedBox(width: 16),
        // Expanded(child: ElevatedButton(onPressed: () {}, child: const Text('Book Now'))),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentBottomNavIndex,
      onTap: (index) {
        setState(() {
          _currentBottomNavIndex = index;
        });
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.cloud), label: 'Weather'),
        BottomNavigationBarItem(icon: Icon(Icons.beach_access), label: 'Beach Guide'),
      ],
    );
  }
}

class Activity {
  final String id;
  final String name;
  final String desc;
  final String image;
  final DateTime createdAt;
  final DateTime updatedAt;

  Activity({
    required this.id,
    required this.name,
    required this.desc,
    required this.image,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      desc: json['desc'] ?? '',
      image: json['image'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class Beach {
  final int id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String beachId;
  final String beachName;
  final String beachDesc;
  final String beachType;
  final int locationId;
  final dynamic activities;

  Beach({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.beachId,
    required this.beachName,
    required this.beachDesc,
    required this.beachType,
    required this.locationId,
    required this.activities,
  });

  factory Beach.fromJson(Map<String, dynamic> json) {
    return Beach(
      id: json['ID'] ?? 0,
      createdAt: DateTime.tryParse(json['CreatedAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['UpdatedAt'] ?? '') ?? DateTime.now(),
      beachId: json['beach_id'] ?? '',
      beachName: json['beach_name'] ?? '',
      beachDesc: json['beach_desc'] ?? '',
      beachType: json['beach_type'] ?? '',
      locationId: json['location_id'] ?? 0,
      activities: json['activities'],
    );
  }
}