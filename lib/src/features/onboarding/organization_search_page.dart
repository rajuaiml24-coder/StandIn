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
  List<Organization> _results = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _onSearch('');
  }

  void _onSearch(String query) async {
    setState(() => _loading = true);
    try {
      final results = await widget.controller.searchOrganizations(query);
      if (mounted) setState(() => _results = results);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 20),
          child: Image.asset('assets/brand/standin_logo.png', height: 28),
        ),
      ],
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
            Text(
              _searchController.text.isEmpty 
                ? (widget.controller.role == AppRole.student ? 'POPULAR COLLEGES' : 'POPULAR COMPANIES')
                : 'SEARCH RESULTS', 
              style: const TextStyle(fontSize: 12, letterSpacing: 1, fontWeight: FontWeight.w800, color: Color(0xFF667085)),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading 
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty && _searchController.text.length >= 2
                    ? const Center(child: Text('No matching organizations found.', style: TextStyle(color: Color(0xFF98A2B3))))
                    : ListView.separated(
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
                      subtitle: Text('${org.branch ?? ''} • ${org.anonymousCreatorId} • ${org.followerCount} followers', style: const TextStyle(color: Color(0xFF667085))),
                      trailing: const Icon(Icons.chevron_right, color: navy),
                      onTap: () {
                        widget.controller.selectOrganization(org);
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
