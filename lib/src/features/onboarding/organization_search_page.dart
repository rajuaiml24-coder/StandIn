import 'package:flutter/material.dart';
import '../../app.dart';
import '../../domain/attendance.dart';
import 'onboarding_controller.dart';

class OrganizationSearchPage extends StatefulWidget {
  const OrganizationSearchPage({super.key, required this.controller});
  final OnboardingController controller;

  @override
  State<OrganizationSearchPage> createState() => _OrganizationSearchPageState();
}

class _OrganizationSearchPageState extends State<OrganizationSearchPage> {
  final _searchController = TextEditingController();
  final List<Organization> _mockOrgs = [
    const Organization(id: 'org-1', name: 'StandIn Demo University', type: OrganizationType.college, branch: 'Main Campus', isVerified: true, followerCount: 1250),
    const Organization(id: 'org-2', name: 'Global Tech Corp', type: OrganizationType.company, branch: 'London Office', isVerified: true, followerCount: 450),
    const Organization(id: 'org-3', name: 'St. Mary\'s College', type: OrganizationType.college, branch: 'Downtown', isVerified: false, followerCount: 85),
  ];

  List<Organization> _results = [];

  @override
  void initState() {
    super.initState();
    _results = _mockOrgs;
  }

  void _onSearch(String query) {
    setState(() {
      _results = _mockOrgs.where((o) => o.name.toLowerCase().contains(query.toLowerCase())).toList();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: navy),
        onPressed: widget.controller.back,
      ),
    ),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.controller.role == AppRole.student ? 'Find your College' : 'Find your Company',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: navy),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _searchController,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: 'Search by name...',
                prefixIcon: const Icon(Icons.search, color: navy),
                filled: true,
                fillColor: const Color(0xFFF6F7FB),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),
            const Text('SEARCH RESULTS', style: TextStyle(fontSize: 12, letterSpacing: 1, fontWeight: FontWeight.w800, color: Color(0xFF667085))),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: _results.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, index) {
                  final org = _results[index];
                  return Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16), 
                      side: const BorderSide(color: Color(0xFFE8EBF1)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      title: Row(
                        children: [
                          Text(org.name, style: const TextStyle(fontWeight: FontWeight.w800, color: navy)),
                          if (org.isVerified) ...[const SizedBox(width: 6), const Icon(Icons.verified, color: Colors.blue, size: 16)],
                        ],
                      ),
                      subtitle: Text('${org.branch} • ${org.followerCount} followers', style: const TextStyle(color: Color(0xFF667085))),
                      trailing: const Icon(Icons.chevron_right, color: navy),
                      onTap: () {
                        // Mock policy for demo
                        final policy = AttendancePolicy(
                          id: '${org.id}-p1',
                          version: 1,
                          effectiveFrom: DateTime(2026, 8, 1),
                          state: org.isVerified ? PolicyState.official : PolicyState.community,
                          evaluationPeriod: EvaluationPeriod.monthly,
                          minimumPercent: 75,
                          basis: CalculationBasis.hours,
                          fullUnit: 7,
                          halfUnit: 3.5,
                          startDate: DateTime(2026, 1, 1), // Mock dates for existing org
                          endDate: DateTime(2026, 6, 30),
                        );
                        widget.controller.selectOrganization(org, policy);
                      },
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: TextButton(
                  onPressed: widget.controller.goToCreateOrganization,
                  child: const Text('Can\'t find yours? Create it', style: TextStyle(color: orange, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
