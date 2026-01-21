import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:intl/intl.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/applicant.dart';
import '../models/donation.dart';
import '../controllers/applicant_controller.dart';
import '../controllers/donation_controller.dart';
import '../widgets/applicant_details_popup.dart';
import '../views/login_page.dart';
import '../services/sslcommerz_service.dart';
import '../views/payment_webview.dart';

class DonorDashboard extends StatefulWidget {
  const DonorDashboard({super.key});

  @override
  State<DonorDashboard> createState() => _DonorDashboardState();
}

class _DonorDashboardState extends State<DonorDashboard> {
  final _applicantController = ApplicantController();
  final _donationController = DonationController();
  int _selectedIndex = 0;

  void _showDetailsPopup(Applicant applicant) {
    showDialog(
      context: context,
      builder: (context) => ApplicantDetailsPopup(
        applicant: applicant,
        showDonateButton: true,
        onDonate: () async {
          // Popup is already closed by ApplicantDetailsPopup internal logic
          try {
            await _donationController.requestDonation(applicant.id);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Donation request sent! Waiting for admin approval.',
                  ),
                  backgroundColor: Color(0xFF388e3c),
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error sending request: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _handleLogout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header with logo and logout
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 8.0,
              ),
              child: Row(
                children: [
                  // Logo
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
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
                          Icons.favorite,
                          color: Color(0xFF388e3c),
                          size: 24,
                        );
                      },
                    ),
                  ),
                  const Spacer(),
                  // Logout button
                  IconButton(
                    icon: const Icon(Icons.logout, color: Color(0xFF388e3c)),
                    onPressed: _handleLogout,
                    tooltip: 'Logout',
                  ),
                ],
              ),
            ),
            // Centered title
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Donor Dashboard',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF388e3c),
                ),
              ),
            ),
            // Tab buttons
            Row(
              children: [
                Expanded(
                  child: _buildTabButton('Browse Applicants', Icons.search, 0),
                ),
                Expanded(
                  child: _buildTabButton(
                    'Approved Donations',
                    Icons.volunteer_activism,
                    1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Content
            Expanded(
              child: _selectedIndex == 0
                  ? _buildBrowseApplicants()
                  : _buildApprovedDonations(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String title, IconData icon, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF388e3c) : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[700],
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrowseApplicants() {
    return FutureBuilder<List<Applicant>>(
      future: _applicantController.getApprovedApplicants(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final approvedApplicants = snapshot.data ?? [];

        if (approvedApplicants.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: ListView(
              children: const [
                SizedBox(height: 200),
                Center(
                  child: Text(
                    'No verified applicants available',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: approvedApplicants.length,
            itemBuilder: (context, index) {
              final applicant = approvedApplicants[index];
              return _buildApplicantCard(applicant);
            },
          ),
        );
      },
    );
  }

  Widget _buildApprovedDonations() {
    return FutureBuilder<List<Donation>>(
      future: _donationController.getMyDonationInteractions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final donations = snapshot.data ?? [];

        if (donations.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: ListView(
              children: const [
                SizedBox(height: 200),
                Center(
                  child: Text(
                    'No approved donations yet.',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: donations.length,
            itemBuilder: (context, index) {
              final donation = donations[index];
              return _buildDonationCard(donation);
            },
          ),
        );
      },
    );
  }

  Widget _buildDonationCard(Donation donation) {
    // Uses joined data from Donation object
    final applicantName = donation.applicantName ?? 'Unknown';
    final applicantPhoto = donation.applicantPhoto;

    final bool isApproved = donation.status == DonationStatus.approved;
    final bool isScheduled = donation.status == DonationStatus.scheduled;
    final bool isMeetingRequested =
        donation.status == DonationStatus.meetingRequested;
    final bool isCompleted = donation.status == DonationStatus.completed;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    shape: BoxShape.circle,
                    image: applicantPhoto != null
                        ? DecorationImage(
                            image: NetworkImage(applicantPhoto),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: applicantPhoto != null
                      ? null
                      : const Icon(Icons.person, size: 28, color: Colors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        applicantName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Status: ${donation.status.toString().split('.').last.toUpperCase()}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isCompleted ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (isScheduled) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Meeting Scheduled',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildInfoRow(
                      Icons.calendar_today,
                      DateFormat(
                        'MMM dd, yyyy - hh:mm a',
                      ).format(donation.scheduledAt!),
                    ),
                    const SizedBox(height: 4),
                    _buildLocationView(donation.scheduledLocation),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (isApproved)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _handleMeetAndPay(donation),
                      icon: const Icon(Icons.handshake),
                      label: const Text('Meet & Pay'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF388e3c),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _handlePayViaApp(donation),
                      icon: const Icon(Icons.mobile_friendly),
                      label: const Text('Pay via App'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            if (isMeetingRequested)
              const Text(
                'You have requested to meet. Waiting for admin to schedule.',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            if (isCompleted)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Donation Completed! Thank you!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF388e3c),
                    ),
                  ),
                  Text(
                    'Amount Donated: BDT ${donation.amount.toStringAsFixed(0)}',
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleMeetAndPay(Donation donation) async {
    try {
      await _donationController.requestMeeting(donation.id);
      // No need to setState explicitly as StreamBuilder will handle updates
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Meeting requested! Admin will schedule it soon.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _handlePayViaApp(Donation donation) async {
    final amountCtrl = TextEditingController();

    // 1. Ask for amount
    final amount = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Donation Amount'),
        content: TextField(
          controller: amountCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Amount (BDT)',
            prefixText: '৳ ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(amountCtrl.text);
              if (val != null && val > 0) {
                Navigator.pop(context, val);
              }
            },
            child: const Text('Pay'),
          ),
        ],
      ),
    );

    if (amount == null) return;

    // 2. Select Payment Method
    if (!mounted) return;
    final paymentMethod = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Payment Method'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () => Navigator.pop(context, 'sslcommerz'),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/images/sslcommerz.png',
                      height: 40,
                      width: 100,
                      fit: BoxFit.contain,
                      errorBuilder: (c, o, s) => const Icon(Icons.payment),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'SSLCommerz',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_forward_ios, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (paymentMethod == null) return;

    // 3. Initiate Payment
    if (!mounted) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final paymentUrl = await SslCommerzService.initiatePayment(
        donation,
        amount,
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      if (paymentUrl != null) {
        bool? success;

        if (kIsWeb) {
          // Web: NavigationDelegate is not supported on Web (Scanner/Iframe security).
          // We must use a new tab and ask for manual confirmation.
          await launchUrl(
            Uri.parse(paymentUrl),
            mode: LaunchMode.externalApplication,
          );

          if (!mounted) return;
          success = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (c) => AlertDialog(
              title: const Text('Payment Confirmation'),
              content: const Text(
                'Please complete the payment in the new tab.\n\nDid you complete the payment successfully?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(c, false),
                  child: const Text('No / Failed'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(c, true),
                  child: const Text('Yes, Completed'),
                ),
              ],
            ),
          );
        } else {
          // Mobile: Use embedded WebView with Automation
          success = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentWebView(paymentUrl: paymentUrl),
            ),
          );
        }

        if (success == true) {
          // 4. Update Backend
          await _donationController.processAppPayment(
            donation.id,
            donation.applicantId,
            amount,
          );

          // StreamBuilder will handle UI update

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Payment Successful! Thank you for your donation.',
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Payment Failed or Cancelled'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to initiate payment')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading if error
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Widget _buildApplicantCard(Applicant applicant) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF388e3c).withOpacity(0.2),
                    shape: BoxShape.circle,
                    image: applicant.photoUrl != null
                        ? DecorationImage(
                            image: NetworkImage(applicant.photoUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: applicant.photoUrl != null
                      ? null
                      : const Icon(
                          Icons.person,
                          size: 28,
                          color: Color(0xFF388e3c),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        applicant.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF388e3c),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Age: ${applicant.age}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Verified',
                    style: TextStyle(
                      color: Color(0xFF388e3c),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.location_on, applicant.location),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.business, applicant.businessGoal),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Funding Progress',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        '${applicant.fundingProgress.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF388e3c),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: applicant.currentFunding / applicant.fundingGoal,
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF388e3c),
                    ),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'BDT ${applicant.currentFunding.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        'BDT ${applicant.fundingGoal.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (applicant.fundingProgress >= 100)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: const Text(
                  'This applicant is fully funded! Thank you.',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _showDetailsPopup(applicant),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF388e3c),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'View Details & Donate',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: Colors.grey[800], fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationView(String? locationLink) {
    if (locationLink == null || !locationLink.startsWith('http')) {
      return Text(
        locationLink ?? 'No location provided',
        style: TextStyle(color: Colors.grey[700]),
      );
    }

    LatLng? point;
    try {
      final uri = Uri.parse(locationLink);
      final query = uri.queryParameters['query'];
      if (query != null) {
        final parts = query.split(',');
        if (parts.length == 2) {
          final lat = double.parse(parts[0]);
          final lng = double.parse(parts[1]);
          point = LatLng(lat, lng);
        }
      }
    } catch (_) {}

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () async {
            final uri = Uri.parse(locationLink);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
          child: Row(
            children: [
              const Icon(Icons.map, size: 16, color: Colors.blue),
              const SizedBox(width: 4),
              Text(
                'View on Map',
                style: const TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        ),
        if (point != null) ...[
          const SizedBox(height: 8),
          Container(
            height: 150,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: point,
                  initialZoom: 15.0,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.none,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.haat_baran',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: point,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
