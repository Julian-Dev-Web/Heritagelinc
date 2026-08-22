// lib/features/trips/presentation/screens/saved_trips_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/saved_trip_service.dart';

class SavedTripsScreen extends StatefulWidget {
  const SavedTripsScreen({super.key, this.embedded = false});

  /// When true the screen renders without its own AppBar, for use inside a
  /// bottom-navigation tab.
  final bool embedded;

  @override
  State<SavedTripsScreen> createState() => _SavedTripsScreenState();
}

class _SavedTripsScreenState extends State<SavedTripsScreen> {
  final _service = SavedTripService();
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  List<SavedTrip> _trips = const [];
  bool _isLoading = true;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------ READ

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _error = null);

    try {
      final trips = _query.isEmpty
          ? await _service.fetchAll()
          : await _service.search(_query);
      if (!mounted) return;
      setState(() {
        _trips = trips;
        _isLoading = false;
      });
    } on TripFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() => _query = value);
      _load();
    });
  }

  // ---------------------------------------------------- CREATE / UPDATE

  Future<void> _openEditor({SavedTrip? existing}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TripEditorSheet(service: _service, existing: existing),
    );

    if (saved == true && mounted) {
      _load();
      _toast(existing == null ? 'Trip saved.' : 'Trip updated.');
    }
  }

  Future<void> _toggleFavorite(SavedTrip trip) async {
    // Optimistic update, rolled back if the write fails.
    setState(() {
      _trips = _trips
          .map(
            (t) => t.id == trip.id
                ? SavedTrip(
                    id: t.id,
                    label: t.label,
                    origin: t.origin,
                    destination: t.destination,
                    mode: t.mode,
                    isFavorite: !t.isFavorite,
                    createdAt: t.createdAt,
                    estimatedFare: t.estimatedFare,
                    notes: t.notes,
                  )
                : t,
          )
          .toList();
    });

    try {
      await _service.toggleFavorite(trip);
      if (mounted) _load();
    } on TripFailure catch (e) {
      if (!mounted) return;
      _toast(e.message);
      _load();
    }
  }

  // ---------------------------------------------------------- DELETE

  Future<void> _confirmDelete(SavedTrip trip) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text(
          'Delete this trip?',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        content: Text(
          '"${trip.label}" will be removed from your saved trips. '
          'This cannot be undone.',
          style: const TextStyle(fontSize: 13.5, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textGrey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Delete',
              style: TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _service.delete(trip.id);
      if (!mounted) return;
      _toast('Trip deleted.');
      _load();
    } on TripFailure catch (e) {
      if (!mounted) return;
      _toast(e.message);
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  // ------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: widget.embedded
          ? null
          : AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              title: const Text(
                'Saved Trips',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              iconTheme: const IconThemeData(color: AppColors.textDark),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        backgroundColor: AppColors.primaryTeal,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Add Trip',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        top: widget.embedded,
        child: Column(
          children: [
            if (widget.embedded) _buildEmbeddedHeader(),
            _buildSearchField(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildEmbeddedHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 14, 20, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Saved Trips',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: TextField(
        controller: _searchCtrl,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search your trips',
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.textGrey,
            size: 20,
          ),
          suffixIcon: _searchCtrl.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppColors.textGrey,
                  ),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _query = '');
                    _load();
                  },
                ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE1E8E6)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE1E8E6)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: AppColors.primaryTeal,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.4,
          color: AppColors.primaryTeal,
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 40,
                color: Color(0xFFB9C6C2),
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.5,
                  color: AppColors.textGrey,
                ),
              ),
              const SizedBox(height: 18),
              TextButton(
                onPressed: _load,
                child: const Text(
                  'Try again',
                  style: TextStyle(
                    color: AppColors.primaryTeal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_trips.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(34),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _query.isEmpty
                    ? Icons.bookmark_border_rounded
                    : Icons.search_off_rounded,
                size: 40,
                color: const Color(0xFFB9C6C2),
              ),
              const SizedBox(height: 16),
              Text(
                _query.isEmpty ? 'No saved trips yet' : 'No matches',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _query.isEmpty
                    ? 'Save the routes you take often so the fare and mode '
                          'are one tap away.'
                    : 'Try a different search term.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: AppColors.textGrey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primaryTeal,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
        itemCount: _trips.length,
        itemBuilder: (context, i) => _TripTile(
          trip: _trips[i],
          onEdit: () => _openEditor(existing: _trips[i]),
          onDelete: () => _confirmDelete(_trips[i]),
          onToggleFavorite: () => _toggleFavorite(_trips[i]),
        ),
      ),
    );
  }
}

// =====================================================================
// List tile
// =====================================================================

class _TripTile extends StatelessWidget {
  const _TripTile({
    required this.trip,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleFavorite,
  });

  final SavedTrip trip;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(trip.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDelete();
        return false; // the dialog handles removal
      },
      background: Container(
        alignment: Alignment.centerRight,
        margin: const EdgeInsets.only(bottom: 11),
        padding: const EdgeInsets.only(right: 22),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: AppColors.danger,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onEdit,
        child: Container(
          margin: const EdgeInsets.only(bottom: 11),
          padding: const EdgeInsets.fromLTRB(14, 13, 8, 13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE6ECEA)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  trip.mode.icon,
                  size: 20,
                  color: AppColors.primaryTeal,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            trip.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        if (trip.isFavorite) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.star_rounded,
                            size: 15,
                            color: Color(0xFFE3B75E),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      trip.routeLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textGrey,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${trip.mode.label} · ${trip.fareLabel}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryTeal,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onToggleFavorite,
                icon: Icon(
                  trip.isFavorite
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  size: 21,
                  color: trip.isFavorite
                      ? const Color(0xFFE3B75E)
                      : const Color(0xFFC5D0CD),
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert_rounded,
                  size: 20,
                  color: AppColors.textGrey,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: 10),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: AppColors.danger,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Delete',
                          style: TextStyle(color: AppColors.danger),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================================
// Create / edit sheet
// =====================================================================

class _TripEditorSheet extends StatefulWidget {
  const _TripEditorSheet({required this.service, this.existing});

  final SavedTripService service;
  final SavedTrip? existing;

  @override
  State<_TripEditorSheet> createState() => _TripEditorSheetState();
}

class _TripEditorSheetState extends State<_TripEditorSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _labelCtrl;
  late final TextEditingController _originCtrl;
  late final TextEditingController _destCtrl;
  late final TextEditingController _fareCtrl;
  late final TextEditingController _notesCtrl;
  late TripMode _mode;

  bool _isSaving = false;
  String? _error;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final t = widget.existing;
    _labelCtrl = TextEditingController(text: t?.label ?? '');
    _originCtrl = TextEditingController(text: t?.origin ?? '');
    _destCtrl = TextEditingController(text: t?.destination ?? '');
    _fareCtrl = TextEditingController(
      text: t?.estimatedFare == null ? '' : t!.estimatedFare!.toStringAsFixed(2),
    );
    _notesCtrl = TextEditingController(text: t?.notes ?? '');
    _mode = t?.mode ?? TripMode.jeepney;
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _originCtrl.dispose();
    _destCtrl.dispose();
    _fareCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _isSaving = true;
      _error = null;
    });

    final fare = double.tryParse(_fareCtrl.text.trim());

    try {
      if (_isEditing) {
        await widget.service.update(
          id: widget.existing!.id,
          label: _labelCtrl.text,
          origin: _originCtrl.text,
          destination: _destCtrl.text,
          mode: _mode,
          estimatedFare: fare,
          notes: _notesCtrl.text,
        );
      } else {
        await widget.service.create(
          label: _labelCtrl.text,
          origin: _originCtrl.text,
          destination: _destCtrl.text,
          mode: _mode,
          estimatedFare: fare,
          notes: _notesCtrl.text,
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } on TripFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 26),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDDE5E3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  _isEditing ? 'Edit trip' : 'Save a trip',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 18),

                if (_error != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: AppColors.danger.withValues(alpha: 0.20),
                      ),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                _field(
                  controller: _labelCtrl,
                  hint: 'Trip name, e.g. Daily commute',
                  icon: Icons.label_outline_rounded,
                  maxLength: 60,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Give this trip a name'
                      : null,
                ),
                const SizedBox(height: 12),
                _field(
                  controller: _originCtrl,
                  hint: 'From',
                  icon: Icons.trip_origin_rounded,
                  maxLength: 80,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Enter a starting point'
                      : null,
                ),
                const SizedBox(height: 12),
                _field(
                  controller: _destCtrl,
                  hint: 'To',
                  icon: Icons.place_outlined,
                  maxLength: 80,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Enter a destination'
                      : null,
                ),
                const SizedBox(height: 16),

                const Text(
                  'Mode of transport',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 9),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: TripMode.values.map((m) {
                    final selected = _mode == m;
                    return GestureDetector(
                      onTap: () => setState(() => _mode = m),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primaryTeal.withValues(alpha: 0.09)
                              : const Color(0xFFF7FAF9),
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(
                            color: selected
                                ? AppColors.primaryTeal
                                : const Color(0xFFE1E8E6),
                            width: selected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              m.icon,
                              size: 16,
                              color: selected
                                  ? AppColors.primaryTeal
                                  : AppColors.textGrey,
                            ),
                            const SizedBox(width: 7),
                            Text(
                              m.label,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: selected
                                    ? AppColors.primaryTeal
                                    : AppColors.textGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                _field(
                  controller: _fareCtrl,
                  hint: 'Estimated fare (optional)',
                  icon: Icons.payments_outlined,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final parsed = double.tryParse(v.trim());
                    if (parsed == null) return 'Enter a number';
                    if (parsed < 0) return 'Fare cannot be negative';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _field(
                  controller: _notesCtrl,
                  hint: 'Notes (optional)',
                  icon: Icons.notes_rounded,
                  maxLines: 3,
                  maxLength: 500,
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed: _isSaving ? null : _save,
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _isEditing ? 'Save changes' : 'Save trip',
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        hintText: hint,
        counterText: '',
        prefixIcon: Icon(icon, size: 19, color: AppColors.textGrey),
        filled: true,
        fillColor: const Color(0xFFF7FAF9),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: Color(0xFFE1E8E6)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: Color(0xFFE1E8E6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(
            color: AppColors.primaryTeal,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}