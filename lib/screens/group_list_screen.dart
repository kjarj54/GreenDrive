import 'package:flutter/material.dart';
import 'package:greendrive/model/event.dart';
import 'package:greendrive/services/event_service.dart';
import 'package:greendrive/providers/user_provider.dart';
import 'package:greendrive/widgets/home/events/create_group_modal.dart';
import 'package:greendrive/widgets/home/events/group_details_modal.dart';
import 'package:provider/provider.dart';

class GroupListScreen extends StatefulWidget {
  const GroupListScreen({super.key});

  @override
  State<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends State<GroupListScreen> {
  final EventService _eventService = EventService();
  List<Event> _groups = [];
  List<Event> _filteredGroups = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    setState(() => _isLoading = true);
    final userId = Provider.of<UserProvider>(context, listen: false).userId!;
    try {
      final groups = await _eventService.getEvents();
      final List<Event> processedGroups = [];

      for (final group in groups) {
        final participants = await _eventService.getEventParticipants(group.id);
        final isJoined = participants.any((p) => p['usuarioId'] == userId);

        final shouldShow =
            group.status == 'Activo' || isJoined || group.creatorId == userId;

        if (shouldShow) {
          processedGroups.add(
            group.copyWith(participantCount: isJoined ? 1 : 0),
          );
        }
      }

      final activeGroups =
          processedGroups.where((g) => g.status == 'Activo').toList();
      final inactiveGroups =
          processedGroups.where((g) => g.status != 'Activo').toList();

      setState(() {
        _groups = [...activeGroups, ...inactiveGroups];
        _filteredGroups = _groups;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading groups: \$e')));
    }
  }

  void _filterGroups(String query) {
    setState(() {
      _searchQuery = query;
      _filteredGroups =
          _groups
              .where((g) => g.title.toLowerCase().contains(query.toLowerCase()))
              .toList();
    });
  }

  Future<void> _joinGroup(int eventId, int userId) async {
    try {
      await _eventService.registerForEvent(eventId, userId);
      _loadGroups();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('You joined the group!')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error joining group: \$e')));
    }
  }

  Future<void> _leaveGroup(int eventId, int userId) async {
    try {
      await _eventService.unregisterFromEvent(eventId, userId);
      _loadGroups();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('You left the group.')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error leaving group: \$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = Provider.of<UserProvider>(context).userId ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Groups'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final created = await showDialog<bool>(
                context: context,
                builder: (context) => const CreateGroupModal(),
              );

              if (created == true) {
                _loadGroups();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Group created successfully!')),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search groups...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _filterGroups,
            ),
          ),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredGroups.isEmpty
                    ? const Center(child: Text('No groups found'))
                    : ListView.builder(
                      itemCount: _filteredGroups.length,
                      itemBuilder: (context, index) {
                        final group = _filteredGroups[index];
                        final joined = group.participantCount > 0;
                        final bool isFirstInactive =
                            group.status != 'Activo' &&
                            (index == 0 ||
                                _filteredGroups[index - 1].status == 'Activo');

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isFirstInactive)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: Text(
                                  'Grupos inactivos',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red[700],
                                  ),
                                ),
                              ),
                            ListTile(
                              onTap: () async {
                                final updated = await showDialog<bool>(
                                  context: context,
                                  builder:
                                      (context) => GroupDetailsModal(
                                        group: group,
                                        onUpdated: _loadGroups,
                                      ),
                                );
                                if (updated == true) {
                                  _loadGroups(); // refresca la lista si hubo un cambio
                                }
                              },
                              title: Row(
                                children: [
                                  Expanded(child: Text(group.title)),
                                  if (group.status != 'Activo') ...[
                                    const SizedBox(width: 6),
                                    const Icon(
                                      Icons.warning_amber,
                                      color: Colors.red,
                                      size: 18,
                                    ),
                                  ],
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(group.description),
                                  if (group.status != 'Activo')
                                    const Text(
                                      'Este grupo está inactivo',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                              trailing:
                                  joined
                                      ? OutlinedButton.icon(
                                        onPressed:
                                            () => _leaveGroup(group.id, userId),
                                        icon: const Icon(
                                          Icons.logout,
                                          color: Colors.red,
                                        ),
                                        label: const Text(
                                          'Leave',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      )
                                      : ElevatedButton.icon(
                                        onPressed:
                                            () => _joinGroup(group.id, userId),
                                        icon: const Icon(Icons.login),
                                        label: const Text('Join'),
                                      ),
                            ),
                          ],
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
