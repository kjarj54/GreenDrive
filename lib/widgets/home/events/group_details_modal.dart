import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:greendrive/model/event.dart';
import 'package:greendrive/services/event_service.dart';
import 'package:greendrive/providers/user_provider.dart';

class GroupDetailsModal extends StatefulWidget {
  final Event group;
  final VoidCallback onUpdated;

  const GroupDetailsModal({
    super.key,
    required this.group,
    required this.onUpdated,
  });

  @override
  State<GroupDetailsModal> createState() => _GroupDetailsModalState();
}

class _GroupDetailsModalState extends State<GroupDetailsModal> {
  int _participantCount = 0;
  List<Map<String, dynamic>> _participants = [];
  bool _loadingParticipants = true;

  @override
  void initState() {
    super.initState();
    _loadParticipants();
  }

  Future<void> _loadParticipants() async {
    try {
      final participants = await EventService().getEventParticipants(
        widget.group.id,
      );
      setState(() {
        _participants = participants;
        _participantCount = participants.length;
        _loadingParticipants = false;
      });
    } catch (e) {
      setState(() => _loadingParticipants = false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading participants: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = Provider.of<UserProvider>(context, listen: false).userId;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.group, color: Colors.green.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.group.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoTile(Icons.description, "Description", widget.group.description),
          const SizedBox(height: 10),
          _infoTile(Icons.location_on, "Location", widget.group.location),
          const SizedBox(height: 10),
          _infoTile(
            Icons.calendar_today,
            "Date",
            widget.group.eventDate.toLocal().toString().split(' ')[0],
          ),
          const SizedBox(height: 10),
          _infoTile(
            widget.group.status == "Activo" ? Icons.check_circle : Icons.cancel,
            "Status",
            widget.group.status,
            iconColor:
                widget.group.status == "Activo" ? Colors.green : Colors.red,
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _participants.isNotEmpty ? _showParticipantsDialog : null,
            child: _infoTile(
              Icons.people,
              "Participants",
              _loadingParticipants
                  ? "Loading..."
                  : '$_participantCount user(s)',
              iconColor: Colors.blue,
              underline: _participants.isNotEmpty,
            ),
          ),
        ],
      ),
      actions: [
        if (userId == widget.group.creatorId) ...[
          TextButton.icon(
            onPressed: () => _confirmStatusChange(context),
            icon: const Icon(Icons.swap_horiz),
            label: Text(
              widget.group.status == "Activo" ? "Deactivate" : "Activate",
            ),
          ),
          TextButton.icon(
            onPressed: () => _confirmDeletion(context),
            icon: const Icon(Icons.delete, color: Colors.red),
            label: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
          TextButton.icon(
            onPressed: () => _showEditDialog(context),
            icon: const Icon(Icons.edit),
            label: const Text("Edit"),
          ),
        ],
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Close"),
        ),
      ],
    );
  }

  Widget _infoTile(
    IconData icon,
    String label,
    String value, {
    Color? iconColor,
    bool underline = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: iconColor ?? Colors.grey[700]),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              text: "$label: ",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              children: [
                TextSpan(
                  text: value.isNotEmpty ? value : 'No information',
                  style: TextStyle(
                    fontWeight: FontWeight.normal,
                    color: Colors.black,
                    decoration:
                        underline
                            ? TextDecoration.underline
                            : TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showParticipantsDialog() {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text("Group Participants"),
            content: SizedBox(
              width: double.maxFinite,
              child:
                  _participants.isEmpty
                      ? const Text("No participants.")
                      : ListView.separated(
                        shrinkWrap: true,
                        itemCount: _participants.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (ctx, index) {
                          final user = _participants[index];
                          final name =
                              user['nombre'] ?? user['email'] ?? "Unknown";
                          return ListTile(
                            leading: const Icon(Icons.person),
                            title: Text(name),
                          );
                        },
                      ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Close"),
              ),
            ],
          ),
    );
  }

  void _confirmStatusChange(BuildContext context) async {
    final newStatus = widget.group.status == "Activo" ? "Inactivo" : "Activo";

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text("Confirm status change"),
            content: Text(
              "Are you sure you want to change this group to \"$newStatus\"?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("Confirm"),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await EventService().updateGroupStatus(widget.group.id, newStatus);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Status updated to $newStatus')),
          );
          widget.onUpdated();
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  void _confirmDeletion(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text("Confirm deletion"),
            content: const Text(
              "Are you sure you want to delete this group? This action cannot be undone.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("Delete"),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await EventService().deleteEvent(widget.group.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Group deleted successfully')),
          );
          widget.onUpdated();
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  void _showEditDialog(BuildContext context) {
    final titleController = TextEditingController(text: widget.group.title);
    final descriptionController = TextEditingController(
      text: widget.group.description,
    );
    final locationController = TextEditingController(
      text: widget.group.location,
    );
    final dateController = TextEditingController(
      text: widget.group.eventDate.toLocal().toString().split(' ')[0],
    );

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text("Edit Group"),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  TextField(
                    controller: locationController,
                    decoration: const InputDecoration(labelText: 'Location'),
                  ),
                  TextField(
                    controller: dateController,
                    readOnly: true,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: widget.group.eventDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        dateController.text =
                            picked.toIso8601String().split('T').first;
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await EventService().updateEvent(
                      Event(
                        id: widget.group.id,
                        creatorId: widget.group.creatorId,
                        title: titleController.text,
                        description: descriptionController.text,
                        location: locationController.text,
                        eventDate: DateTime.parse(dateController.text),
                        status: widget.group.status,
                      ),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Group updated')),
                      );
                      Navigator.pop(ctx);
                      Navigator.pop(context);
                      widget.onUpdated();
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error updating: $e')),
                      );
                    }
                  }
                },
                child: const Text("Save"),
              ),
            ],
          ),
    );
  }
}
