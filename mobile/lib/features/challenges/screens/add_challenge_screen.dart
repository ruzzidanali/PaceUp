import 'package:flutter/material.dart';

import '../models/challenge_models.dart';
import '../services/challenge_service.dart';

class AddChallengeScreen extends StatefulWidget {
  final ChallengeService challengeService;

  const AddChallengeScreen({super.key, required this.challengeService});

  @override
  State<AddChallengeScreen> createState() => _AddChallengeScreenState();
}

class _AddChallengeScreenState extends State<AddChallengeScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetController = TextEditingController();

  String _type = 'Distance';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (date == null || !mounted) {
      return;
    }

    setState(() {
      _startDate = DateTime(date.year, date.month, date.day);

      if (_endDate.isBefore(_startDate)) {
        _endDate = _startDate.add(const Duration(days: 7));
      }
    });
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate.isBefore(_startDate) ? _startDate : _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (date == null || !mounted) {
      return;
    }

    setState(() {
      _endDate = DateTime(date.year, date.month, date.day, 23, 59, 59);
    });
  }

  Future<void> _create() async {
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final target = double.tryParse(_targetController.text.trim());

    if (name.isEmpty) {
      _showError('Challenge name is required.');
      return;
    }

    if (target == null || target <= 0) {
      _showError('Target must be greater than zero.');
      return;
    }

    if (_endDate.isBefore(_startDate)) {
      _showError('End date must be after the start date.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.challengeService.createChallenge(
        CreateChallengeRequest(
          name: name,
          description: description.isEmpty ? null : description,
          type: _type,
          targetValue: target,
          startDate: _startDate,
          endDate: _endDate,
        ),
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();

    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';
  }

  String _targetHint() {
    switch (_type) {
      case 'Distance':
        return 'Target distance in km';

      case 'Duration':
        return 'Target duration in seconds';

      case 'Activities':
        return 'Number of activities';

      default:
        return 'Target value';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Challenge')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Create a Challenge',
                  style: Theme.of(context).textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Set a target and challenge others to beat it.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Challenge Name',
                    prefixIcon: Icon(Icons.emoji_events_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _descriptionController,
                  textInputAction: TextInputAction.next,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    prefixIcon: Icon(Icons.description_outlined),
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _type,
                  decoration: const InputDecoration(
                    labelText: 'Challenge Type',
                    prefixIcon: Icon(Icons.category_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Distance',
                      child: Text('Distance'),
                    ),
                    DropdownMenuItem(
                      value: 'Duration',
                      child: Text('Duration'),
                    ),
                    DropdownMenuItem(
                      value: 'Activities',
                      child: Text('Activities'),
                    ),
                  ],
                  onChanged: _isLoading
                      ? null
                      : (value) {
                          if (value == null) {
                            return;
                          }

                          setState(() {
                            _type = value;
                          });
                        },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _targetController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: 'Target',
                    hintText: _targetHint(),
                    prefixIcon: const Icon(Icons.flag_outlined),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.calendar_today_outlined),
                        title: const Text('Start Date'),
                        subtitle: Text(_formatDate(_startDate)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _isLoading ? null : _selectStartDate,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.event_outlined),
                        title: const Text('End Date'),
                        subtitle: Text(_formatDate(_endDate)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _isLoading ? null : _selectEndDate,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isLoading ? null : _create,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Create Challenge'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
