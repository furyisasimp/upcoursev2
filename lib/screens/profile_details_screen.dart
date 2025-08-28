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

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  Future<void> _fetchUserProfile() async {
    setState(() => _isLoading = true);
    final profile = await SupabaseService.getMyProfile();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _profileData = profile;
    });

    if (profile == null && mounted) {
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

  Future<void> _pickProfilePicture() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() => _profileImage = File(picked.path));
    final bytes = await File(picked.path).readAsBytes();

    final url = await SupabaseService.uploadAvatar(
      fileName: 'profile_${SupabaseService.authUserId}.jpg',
      bytes: bytes,
    );

    await SupabaseService.upsertMyProfile({'profile_picture': url});
    if (mounted) _fetchUserProfile();
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
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
                                  : _buildProfileView(constraints.maxWidth),
                        ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileView(double width) {
    final firstName = _profileData?['first_name'] ?? '';
    final middleName = _profileData?['middle_name'] ?? '';
    final lastName = _profileData?['last_name'] ?? '';
    final gradeLevel = _profileData?['grade_level'] ?? 'N/A';
    final fullName = [
      firstName,
      if (middleName.isNotEmpty) middleName,
      lastName,
    ].join(' ');
    final profilePicUrl = _profileData?['profile_picture'];

    final bool isNarrow = width < 360; // tiny phones breakpoint
    final double avatarRadius = isNarrow ? 28 : 35;

    final nameBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          fullName.isEmpty ? 'Student' : fullName,
          maxLines: isNarrow ? 2 : 1,
          overflow: TextOverflow.ellipsis,
          softWrap: true,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Grade $gradeLevel Student',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontFamily: 'Inter', color: Colors.white),
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Adaptive header (Row on normal screens, Column on very narrow)
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
          child:
              isNarrow
                  ? Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: _pickProfilePicture,
                        child: CircleAvatar(
                          radius: avatarRadius,
                          backgroundImage:
                              _profileImage != null
                                  ? FileImage(_profileImage!)
                                  : (profilePicUrl != null &&
                                      profilePicUrl.isNotEmpty)
                                  ? NetworkImage(profilePicUrl)
                                  : const AssetImage(
                                        'assets/user_placeholder.png',
                                      )
                                      as ImageProvider,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(alignment: Alignment.center, child: nameBlock),
                    ],
                  )
                  : Row(
                    children: [
                      GestureDetector(
                        onTap: _pickProfilePicture,
                        child: CircleAvatar(
                          radius: avatarRadius,
                          backgroundImage:
                              _profileImage != null
                                  ? FileImage(_profileImage!)
                                  : (profilePicUrl != null &&
                                      profilePicUrl.isNotEmpty)
                                  ? NetworkImage(profilePicUrl)
                                  : const AssetImage(
                                        'assets/user_placeholder.png',
                                      )
                                      as ImageProvider,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(child: nameBlock),
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
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              softWrap: true,
              overflow: TextOverflow.visible,
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
                title, // ← dynamic again
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
