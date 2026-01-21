import 'package:flutter/material.dart';
import '../models/user.dart';
import '../views/login_page.dart';

class HamburgerMenuWrapper extends StatefulWidget {
  final Widget child;
  final UserType userType;
  final VoidCallback? onPendingRequestsTap;
  final VoidCallback? onApprovedApplicantsTap;
  final String title;

  const HamburgerMenuWrapper({
    super.key,
    required this.child,
    required this.userType,
    required this.title,
    this.onPendingRequestsTap,
    this.onApprovedApplicantsTap,
  });

  @override
  State<HamburgerMenuWrapper> createState() => _HamburgerMenuWrapperState();
}

class _HamburgerMenuWrapperState extends State<HamburgerMenuWrapper>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void toggleMenu() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void closeMenu() {
    if (_isOpen) {
      setState(() {
        _isOpen = false;
        _animationController.reverse();
      });
    }
  }

  void _handleLogout() {
    closeMenu();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final menuWidth = screenWidth * 0.7; // 70% of screen width

    return Stack(
      children: [
        // Main content
        widget.child,
        // Dark overlay when menu is open
        AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            if (_fadeAnimation.value == 0.0) {
              return const SizedBox.shrink();
            }
            return GestureDetector(
              onTap: closeMenu,
              child: Container(
                color: Colors.black.withValues(alpha: _fadeAnimation.value),
              ),
            );
          },
        ),
        // Hamburger button (logo)
        SafeArea(
          child: Positioned(
            top: 8,
            left: 8,
            child: GestureDetector(
              onTap: toggleMenu,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(4),
                child: Image.asset(
                  'assets/images/Haat_Baran_logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.menu,
                      color: Color(0xFF388e3c),
                      size: 24,
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        // Slide menu
        AnimatedBuilder(
          animation: _slideAnimation,
          builder: (context, child) {
            final offset = _slideAnimation.value.dx * menuWidth;
            return Positioned(
              left: offset,
              top: 0,
              bottom: 0,
              width: menuWidth,
              child: Material(
                elevation: 8,
                color: Colors.white,
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(2, 0),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: MediaQuery.of(context).padding.top + 60),
                      // Logo in menu
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SizedBox(
                          width: 80,
                          height: 80,
                          child: Image.asset(
                            'assets/images/Haat_Baran_logo.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF388e3c),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.favorite,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Admin specific menu items
                      if (widget.userType == UserType.admin) ...[
                        _buildMenuTile(
                          icon: Icons.pending_actions,
                          title: 'Pending Requests',
                          onTap: () {
                            closeMenu();
                            widget.onPendingRequestsTap?.call();
                          },
                        ),
                        _buildMenuTile(
                          icon: Icons.check_circle,
                          title: 'Approved Applicants',
                          onTap: () {
                            closeMenu();
                            widget.onApprovedApplicantsTap?.call();
                          },
                        ),
                        const Divider(),
                      ],
                      // Logout button
                      _buildMenuTile(
                        icon: Icons.logout,
                        title: 'Logout',
                        onTap: _handleLogout,
                        isLogout: true,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isLogout ? Colors.red : const Color(0xFF388e3c),
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isLogout ? Colors.red : Colors.black87,
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
      ),
      onTap: onTap,
    );
  }
}

