import 'dart:async';

import 'package:flutter/material.dart';

import '../models/social_models.dart';
import '../services/social_service.dart';
import 'user_profile_screen.dart';

class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({super.key});

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final SocialService _socialService = SocialService();
  final TextEditingController _searchController = TextEditingController();

  Timer? _debounce;

  List<UserSearchResult> _users = [];

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _socialService.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();

    final query = value.trim();

    if (query.isEmpty) {
      setState(() {
        _users = [];
        _isLoading = false;
        _errorMessage = null;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 400), () {
      _searchUsers(query);
    });
  }

  Future<void> _searchUsers(String query) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final users = await _socialService.searchUsers(query);

      if (!mounted) {
        return;
      }

      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _openUserProfile(UserSearchResult user) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => UserProfileScreen(userId: user.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Find Users')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search by username or name',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();

                          setState(() {
                            _users = [];
                            _errorMessage = null;
                            _isLoading = false;
                          });
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: LinearProgressIndicator(),
            ),
          Expanded(child: _buildResults()),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 52),
              const SizedBox(height: 16),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  final query = _searchController.text.trim();

                  if (query.isNotEmpty) {
                    _searchUsers(query);
                  }
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_searchController.text.trim().isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_search_rounded, size: 64),
              SizedBox(height: 16),
              Text(
                'Find people on PaceUp',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Search by username or display name.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (!_isLoading && _users.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_off_outlined, size: 56),
              SizedBox(height: 16),
              Text(
                'No users found',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Try a different username or name.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _users.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final user = _users[index];

        return Card(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 6,
            ),
            leading: CircleAvatar(
              radius: 26,
              backgroundImage:
                  user.profileImageUrl != null &&
                      user.profileImageUrl!.trim().isNotEmpty
                  ? NetworkImage(user.profileImageUrl!)
                  : null,
              child:
                  user.profileImageUrl == null ||
                      user.profileImageUrl!.trim().isEmpty
                  ? const Icon(Icons.person, size: 28)
                  : null,
            ),
            title: Text(
              user.displayName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('@${user.username}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openUserProfile(user),
          ),
        );
      },
    );
  }
}
