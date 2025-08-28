import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:career_roadmap/widgets/custom_appbar.dart' as appbar;
import 'package:career_roadmap/widgets/custom_taskbar.dart' as taskbar;
import 'package:career_roadmap/services/supabase_service.dart';

class ProfileDetailsScreen extends StatefulWidget {
  const ProfileDetailsScreen({super.key});

  @override
  ProfileDetailsScreenState createState() => ProfileDetailsScreenState();
}

class ProfileDetailsScreenState extends State<ProfileDetailsScreen> {
  int _selectedIndex = 3;
  bool _isLoading = false;
  Map<String, dynamic>? _profileData;
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  Future<void> _fetchUserProfile() async {
    setState(() => _isLoading = true);
    final profile = await SupabaseService.getMyProfile();
    setState(() => _isLoading = false);

    if (profile != null) {
      setState(() => _profileData = profile);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to load profile',
              style: TextStyle(fontFamily: 'Inter'),
            ),
          ),
        );
      }
    }
  }

  Future<void> _pickProfilePicture() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() => _profileImage = File(picked.path));
      final bytes = await File(picked.path).readAsBytes();

      // upload to Supabase storage
      final url = await SupabaseService.uploadAvatar(
        fileName: 'profile_${SupabaseService.authUserId}.jpg',
        bytes: bytes,
      );

      // update user profile with new avatar URL
      await SupabaseService.upsertMyProfile({'profile_picture': url});
      _fetchUserProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2FBFF),
      appBar: const appbar.CustomAppBar(),
      bottomNavigationBar: taskbar.CustomTaskbar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
      body: SafeArea(
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child:
                      _profileData == null
                          ? const Text(
                            'No profile data found.',
                            style: TextStyle(fontFamily: 'Inter'),
                          )
                          : _buildProfileView(),
                ),
      ),
    );
  }

  Widget _buildProfileView() {
    final firstName = _profileData?['first_name'] ?? '';
    final middleName = _profileData?['middle_name'] ?? '';
    final lastName = _profileData?['last_name'] ?? '';
    final gradeLevel = _profileData?['grade_level'] ?? 'N/A';

    // Include middle name in full name
    final fullName = [
      firstName,
      if (middleName.isNotEmpty) middleName,
      lastName,
    ].join(' ');

    final profilePicUrl = _profileData?['profile_picture'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with avatar + name
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF3EB6FF), Color(0xFF00E0FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              GestureDetector(
                onTap: _pickProfilePicture,
                child: CircleAvatar(
                  radius: 35,
                  backgroundImage:
                      _profileImage != null
                          ? FileImage(_profileImage!) as ImageProvider
                          : (profilePicUrl != null && profilePicUrl.isNotEmpty)
                          ? NetworkImage(profilePicUrl)
                          : const AssetImage('assets/user_placeholder.png'),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fullName,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Grade $gradeLevel Student',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Student Information
        _buildSection(
          title: 'Student Information',
          children: [
            _infoRow('First Name', firstName),
            _infoRow('Middle Name', middleName.isNotEmpty ? middleName : 'N/A'),
            _infoRow('Last Name', lastName),
            _infoRow('Full Name', fullName),
            _infoRow('Grade Level', 'Grade $gradeLevel'),
            _infoRow('School', _profileData?['school'] ?? 'N/A'),
            _infoRow('Email', SupabaseService.authEmail ?? 'N/A'),
          ],
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontFamily: 'Inter'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star, size: 20, color: Colors.amber),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}
