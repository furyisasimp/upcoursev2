import 'package:flutter/material.dart';
import '../services/aws_service.dart';
import '../screens/login_screen.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  @override
  final Size preferredSize;

  const CustomAppBar({Key? key})
    : preferredSize = const Size.fromHeight(kToolbarHeight),
      super(key: key);

  @override
  CustomAppBarState createState() => CustomAppBarState();
}

class CustomAppBarState extends State<CustomAppBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scale = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openMenu(BuildContext context, Offset offset) async {
    _controller.forward(from: 0);
    final selected = await showMenu<_SettingsAction>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy,
        offset.dx + 1,
        offset.dy + 1,
      ),
      items: [
        PopupMenuItem(
          value: _SettingsAction.logout,
          child: ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text(
              'Logout',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.redAccent,
              ),
            ),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
      elevation: 8.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white.withOpacity(0.95),
    );

    if (selected == _SettingsAction.logout) {
      AwsService.currentUserId = null;
      AwsService.currentUserEmail = null;
      AwsService.currentUserFirstName = null;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: const Color(0xFFF2FBFF),
      elevation: 0,
      title: Row(
        children: [
          const SizedBox(width: 8),
          // Always show the logo at approx. text-height (20px)
          Image.asset('assets/logo.png', height: 20),
          const Spacer(),
          GestureDetector(
            onTapDown: (tap) => _openMenu(context, tap.globalPosition),
            child: ScaleTransition(
              scale: _scale,
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Image.asset('assets/settings_icon.png', height: 30),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _SettingsAction { logout }
