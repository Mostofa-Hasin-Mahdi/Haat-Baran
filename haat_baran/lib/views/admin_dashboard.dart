import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/applicant.dart';
import '../models/donation.dart';
import '../controllers/applicant_controller.dart';
import '../controllers/donation_controller.dart';
import '../widgets/applicant_details_popup.dart';
import '../views/login_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _applicantController = ApplicantController();
  final _donationController = DonationController();

  int _selectedIndex = 0;

  void _showDetailsPopup(Applicant applicant) {
    showDialog(
      context: context,
      builder: (context) =>
          ApplicantDetailsPopup(applicant: applicant, showDonateButton: false),
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
                'Admin Dashboard',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF388e3c),
                ),
              ),
            ),
            // Tab buttons (Scrollable Row)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  _buildTabButton(
                    'Pending Applicants',
                    Icons.pending_actions,
                    0,
                  ),
                  _buildTabButton('Approved Applicants', Icons.check_circle, 1),
                  _buildTabButton(
                    'Donation Requests',
                    Icons.volunteer_activism,
                    2,
                  ),
                  _buildTabButton('Incoming Donations', Icons.attach_money, 3),
                  _buildTabButton(
                    'Completed Donations',
                    Icons.check_circle_outline,
                    4,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Content
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildPendingRequests();
      case 1:
        return _buildApprovedApplicants();
      case 2:
        return _buildDonationRequests();
      case 3:
        return _buildIncomingDonations();
      case 4:
        return _buildCompletedDonations();
      default:
        return _buildPendingRequests();
    }
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
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF388e3c) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[700],
              size: 18,
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

  Widget _buildPendingRequests() {
    return FutureBuilder<List<Applicant>>(
      future: _applicantController.getPendingApplicants(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final applicants = snapshot.data ?? [];

        if (applicants.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: ListView(
              children: const [
                SizedBox(height: 200),
                Center(
                  child: Text(
                    'No pending requests',
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
            padding: const EdgeInsets.all(16),
            itemCount: applicants.length,
            itemBuilder: (context, index) {
              final applicant = applicants[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    radius: 30,
                    backgroundImage: applicant.photoUrl != null
                        ? NetworkImage(applicant.photoUrl!)
                        : null,
                    child: applicant.photoUrl == null
                        ? const Icon(Icons.person, size: 30)
                        : null,
                  ),
                  title: Text(
                    applicant.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Text(
                    'Needs: ${applicant.category}\nDate: ${DateFormat('MMM d, y').format(applicant.createdAt)}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        ),
                        onPressed: () async {
                          await _applicantController.approveApplicant(
                            applicant.id,
                          );
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Applicant approved'),
                              ),
                            );
                            setState(() {}); // Refresh list
                          }
                        },
                        tooltip: 'Approve',
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () async {
                          await _applicantController.rejectApplicant(
                            applicant.id,
                          );
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Applicant rejected'),
                              ),
                            );
                            setState(() {}); // Refresh list
                          }
                        },
                        tooltip: 'Reject',
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.info_outline,
                          color: Colors.blue,
                        ),
                        onPressed: () => _showDetailsPopup(applicant),
                        tooltip: 'Details',
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildApprovedApplicants() {
    return FutureBuilder<List<Applicant>>(
      future: _applicantController.getApprovedApplicants(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final applicants = snapshot.data ?? [];

        if (applicants.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: ListView(
              children: const [
                SizedBox(height: 200),
                Center(
                  child: Text(
                    'No approved applicants',
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
            padding: const EdgeInsets.all(16),
            itemCount: applicants.length,
            itemBuilder: (context, index) {
              final applicant = applicants[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    radius: 30,
                    backgroundImage: applicant.photoUrl != null
                        ? NetworkImage(applicant.photoUrl!)
                        : null,
                    child: applicant.photoUrl == null
                        ? const Icon(Icons.person, size: 30)
                        : null,
                  ),
                  title: Text(
                    applicant.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Text(
                    'Full Finding Needed: ${applicant.fullFundingNeeded} BDT\nCurrent Funding: ${applicant.currentFunding} BDT',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showEditDialog(applicant),
                        tooltip: 'Edit',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Applicant'),
                              content: const Text(
                                'Are you sure you want to delete this applicant?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await _applicantController.deleteApplicant(
                              applicant.id,
                            );
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Applicant deleted'),
                                ),
                              );
                              setState(() {}); // Refresh list
                            }
                          }
                        },
                        tooltip: 'Delete',
                      ),
                    ],
                  ),
                  onTap: () => _showDetailsPopup(applicant),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDonationRequests() {
    return FutureBuilder<List<Donation>>(
      future: _donationController.getPendingDonations(),
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
                    'No donation requests',
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
            padding: const EdgeInsets.all(16),
            itemCount: donations.length,
            itemBuilder: (context, index) {
              final donation = donations[index];
              return _buildDonationCardWithApplicant(donation, isRequest: true);
            },
          ),
        );
      },
    );
  }

  Widget _buildIncomingDonations() {
    return FutureBuilder<List<Donation>>(
      future: _donationController.getIncomingDonations(),
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
                    'No incoming donations',
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
            padding: const EdgeInsets.all(16),
            itemCount: donations.length,
            itemBuilder: (context, index) {
              final donation = donations[index];
              return _buildIncomingDonationCard(donation);
            },
          ),
        );
      },
    );
  }

  Widget _buildCompletedDonations() {
    return FutureBuilder<List<Donation>>(
      future: _donationController.getCompletedDonations(),
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
                    'No completed donations',
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
            padding: const EdgeInsets.all(16),
            itemCount: donations.length,
            itemBuilder: (context, index) {
              final donation = donations[index];
              return _buildDonationCardWithApplicant(
                donation,
                isRequest: false,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDonationCardWithApplicant(
    Donation donation, {
    required bool isRequest,
  }) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: Supabase.instance.client
          .from('applicants')
          .select()
          .eq('id', donation.applicantId),
      builder: (context, snapshot) {
        Applicant? applicant;
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          applicant = Applicant.fromMap(snapshot.data!.first);
        }

        if (applicant == null) {
          return Card(
            child: ListTile(
              title: Text('Donation #${donation.id.substring(0, 8)}'),
              subtitle: const Text('Loading details...'),
            ),
          );
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ExpansionTile(
            leading: CircleAvatar(
              radius: 24,
              backgroundImage: applicant.photoUrl != null
                  ? NetworkImage(applicant.photoUrl!)
                  : null,
              child: applicant.photoUrl == null
                  ? const Icon(Icons.person)
                  : null,
            ),
            title: Text(
              isRequest
                  ? 'Request for ${applicant.name}'
                  : 'Donation for ${applicant.name}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Amount: ${donation.amount} BDT',
              style: TextStyle(color: Colors.green[700]),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Applicant Category: ${applicant.category}'),
                    const SizedBox(height: 16),
                    if (isRequest)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () async {
                              await _donationController.approveDonation(
                                donation.id,
                              );
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Donation approved'),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.check),
                            label: const Text('Approve'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () async {
                              await _donationController.rejectDonation(
                                donation.id,
                              );
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Donation rejected'),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.close),
                            label: const Text('Reject'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIncomingDonationCard(Donation donation) {
    final applicantName = donation.applicantName ?? 'Unknown';
    final applicantPhoto = donation.applicantPhoto;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: applicantPhoto != null
                      ? NetworkImage(applicantPhoto)
                      : null,
                  child: applicantPhoto == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'For: $applicantName',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Status: ${donation.status.toString().split('.').last.toUpperCase()}',
                      style: const TextStyle(color: Colors.blue),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (donation.status == DonationStatus.meetingRequested) ...[
              const Text('Donor requested a meeting.'),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _showScheduleDialog(donation),
                icon: const Icon(Icons.calendar_today),
                label: const Text('Schedule'),
              ),
            ] else if (donation.status == DonationStatus.scheduled) ...[
              Text(
                'Scheduled: ${DateFormat('MMM d, y h:mm a').format(donation.scheduledAt!)}',
              ),
              Text('Location: ${donation.scheduledLocation ?? 'TBD'}'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => _showCompleteDonationDialog(donation),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Mark Completed'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showScheduleDialog(Donation donation) async {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    final locationCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Schedule Meeting'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                'Date: ${DateFormat('yyyy-MM-dd HH:mm').format(selectedDate)}',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (date != null) {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(selectedDate),
                  );
                  if (time != null) {
                    selectedDate = DateTime(
                      date.year,
                      date.month,
                      date.day,
                      time.hour,
                      time.minute,
                    );
                  }
                }
              },
            ),
            TextField(
              controller: locationCtrl,
              decoration: InputDecoration(
                labelText: 'Location',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.map, color: Color(0xFF388e3c)),
                  onPressed: () async {
                    final selectedLink = await _pickLocationOnMap();
                    if (selectedLink != null) {
                      locationCtrl.text = selectedLink;
                    }
                  },
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (locationCtrl.text.isNotEmpty) {
                await _donationController.scheduleMeeting(
                  donation.id,
                  selectedDate,
                  locationCtrl.text,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Schedule'),
          ),
        ],
      ),
    );
  }

  Future<String?> _pickLocationOnMap() async {
    LatLng selectedPoint = const LatLng(23.8103, 90.4125); // Default Dhaka

    return await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            insetPadding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 400,
                  width: double.maxFinite,
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: selectedPoint,
                      initialZoom: 13.0,
                      onTap: (tapPosition, point) {
                        setState(() {
                          selectedPoint = point;
                        });
                      },
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
                            point: selectedPoint,
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
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          final link =
                              'https://www.google.com/maps/search/?api=1&query=${selectedPoint.latitude},${selectedPoint.longitude}';
                          Navigator.pop(context, link);
                        },
                        child: const Text('Select'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showCompleteDonationDialog(Donation donation) async {
    final amountCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Donation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Confirm that the donation was received. Enter the final amount (if applicable/monetary).',
            ),
            TextField(
              controller: amountCtrl,
              decoration: const InputDecoration(labelText: 'Amount (BDT)'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountCtrl.text) ?? 0.0;
              await _donationController.confirmDonation(
                donation.id,
                donation.applicantId,
                amount,
              );
              Navigator.pop(context);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditDialog(Applicant applicant) async {
    final nameCtrl = TextEditingController(text: applicant.name);
    final ageCtrl = TextEditingController(text: applicant.age.toString());
    final goalCtrl = TextEditingController(text: applicant.businessGoal);
    final fundingCtrl = TextEditingController(
      text: applicant.fundingGoal.toString(),
    );
    final locCtrl = TextEditingController(text: applicant.location);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Applicant'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: ageCtrl,
                decoration: const InputDecoration(labelText: 'Age'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: goalCtrl,
                decoration: const InputDecoration(labelText: 'Business Goal'),
              ),
              TextField(
                controller: fundingCtrl,
                decoration: const InputDecoration(labelText: 'Funding Goal'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: locCtrl,
                decoration: const InputDecoration(labelText: 'Location'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final updatedApplicant = Applicant(
                  id: applicant.id,
                  name: nameCtrl.text,
                  age: int.tryParse(ageCtrl.text) ?? applicant.age,
                  businessGoal: goalCtrl.text,
                  fundingGoal:
                      double.tryParse(fundingCtrl.text) ??
                      applicant.fundingGoal,
                  location: locCtrl.text,
                  currentFunding: applicant.currentFunding,
                  photo: applicant.photo,
                  fingerprintPhoto: applicant.fingerprintPhoto,
                  isVerified: applicant.isVerified,
                  isApproved: applicant.isApproved,
                  createdAt: applicant.createdAt,
                  maritalStatus: applicant.maritalStatus,
                  familyMembers: applicant.familyMembers,
                  division: applicant.division,
                  district: applicant.district,
                  upazilla: applicant.upazilla,
                  thana: applicant.thana,
                  currentOccupation: applicant.currentOccupation,
                );

                await _applicantController.updateApplicant(updatedApplicant);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Applicant updated')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error updating: $e')));
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
