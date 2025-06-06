import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;


class GuideScreen extends StatefulWidget {
  const GuideScreen({super.key});

  @override
  State<GuideScreen> createState() => _GuideScreenState();
}

class _GuideScreenState extends State<GuideScreen> {
  List<Guide> guides = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchGuides();
  }

  Future<void> _fetchGuides() async {
  try {
  final response = await http.get(
    Uri.parse('https://sea-venture.org/api/guide'),
  );

  if (response.statusCode == 200) {
    final List<dynamic> data = json.decode(response.body);

    setState(() {
      guides = data.map((item) => Guide.fromJson(item)).toList();
      isLoading = false;
    });
  } else {
    throw Exception('Failed to load guides');
  }
} catch (e) {
  setState(() {
    isLoading = false;
  });

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Failed to fetch guides')),
  );
}
  }
  List<Guide> get filteredGuides {
    if (searchQuery.isEmpty) return guides;
    return guides.where((guide) =>
      guide.fName.toLowerCase().contains(searchQuery.toLowerCase()) ||
      guide.lName.toLowerCase().contains(searchQuery.toLowerCase()) ||
      guide.area.toLowerCase().contains(searchQuery.toLowerCase())
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search guides...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),
          
          // Guide List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredGuides.isEmpty
                    ? const Center(child: Text('No guides found'))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredGuides.length,
                        separatorBuilder: (context, index) => const Divider(
                          height: 24,
                          thickness: 1,
                          indent: 16,
                          endIndent: 16,
                        ),
                        itemBuilder: (context, index) {
                          final guide = filteredGuides[index];
                          return _buildGuideCard(guide);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideCard(Guide guide) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: CircleAvatar(
        radius: 28,
        backgroundImage: CachedNetworkImageProvider(guide.nicPhoto),
        backgroundColor: Colors.grey[200],
        child: guide.nicPhoto.isEmpty
            ? Text(
                '${guide.fName[0]}${guide.lName[0]}',
                style: const TextStyle(fontSize: 20),
              )
            : null,
      ),
      title: Text(
        '${guide.fName} ${guide.lName}',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        guide.area,
        style: const TextStyle(fontSize: 14),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // Navigate to guide details
        _showGuideDetails(guide);
      },
    );
  }

  void _showGuideDetails(Guide guide) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${guide.fName} ${guide.lName}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: CachedNetworkImageProvider(guide.nicPhoto),
                  backgroundColor: Colors.grey[200],
                ),
              ),
              const SizedBox(height: 16),
              _buildDetailRow('Area', guide.area),
              _buildDetailRow('Phone', guide.phoneNumber),
              const SizedBox(height: 16),
              const Text(
                'Licenses:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: CachedNetworkImage(
                      imageUrl: guide.licenceFront,
                      height: 120,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[200],
                        height: 120,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CachedNetworkImage(
                      imageUrl: guide.licenceBack,
                      height: 120,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[200],
                        height: 120,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }
}

class Guide {
  final String guideId;
  final String fName;
  final String lName;
  final String licenceFront;
  final String licenceBack;
  final String area;
  final String nicPhoto;
  final String phoneNumber;
  final String beachId;

  Guide({
    required this.guideId,
    required this.fName,
    required this.lName,
    required this.licenceFront,
    required this.licenceBack,
    required this.area,
    required this.nicPhoto,
    required this.phoneNumber,
    required this.beachId,
  });

  factory Guide.fromJson(Map<String, dynamic> json) {
    return Guide(
      guideId: json['guide_id'] ?? '',
      fName: json['f_name'] ?? '',
      lName: json['l_name'] ?? '',
      licenceFront: json['licence_front'] ?? '',
      licenceBack: json['licence_back'] ?? '',
      area: json['area'] ?? '',
      nicPhoto: json['nic_photo'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      beachId: json['beach_id']?.toString() ?? '',
    );
  }
}