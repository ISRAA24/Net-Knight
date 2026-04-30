import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/nk_colors.dart';
import '../dashboard/widgets/sidebar.dart';
import 'models/nat_model.dart';
import 'services/nat_service.dart';
import 'widgets/nat_type_selector.dart';
import 'widgets/masquerade_form.dart';
import 'widgets/source_nat_form.dart';
import 'widgets/destination_nat_form.dart';
import 'widgets/command_preview.dart';

class NATScreen extends StatefulWidget {
  const NATScreen({super.key});

  @override
  State<NATScreen> createState() => _NATScreenState();
}

class _NATScreenState extends State<NATScreen> {
  final _service = NatService();

  // ─── Interfaces from API ──────────────────
  List<String> _interfaces = [];

  // ─── Type ─────────────────────────────────
  NatType _selectedType = NatType.masquerade;
  bool _isSuccess = false;
  bool _isLoading = false;

  // ─── Preview ──────────────────────────────
  String _previewCommand = '';
  Timer? _debounce;

  // ─── Masquerade ───────────────────────────
  final _masqSourceIpCtrl = TextEditingController();
  String? _masqInterface;

  // ─── Source NAT ───────────────────────────
  final _snatSourceIpCtrl = TextEditingController();
  final _snatNewSourceIpCtrl = TextEditingController();
  String? _snatInterface;

  // ─── Destination NAT ──────────────────────
  final _dnatDestIpCtrl = TextEditingController();
  final _dnatExtPortCtrl = TextEditingController();
  final _dnatIntPortCtrl = TextEditingController();
  String? _dnatProtocol;
  String? _dnatInterface;

  @override
  void initState() {
    super.initState();
    _loadInterfaces();
    _masqSourceIpCtrl.addListener(_onChanged);
    _snatSourceIpCtrl.addListener(_onChanged);
    _snatNewSourceIpCtrl.addListener(_onChanged);
    _dnatDestIpCtrl.addListener(_onChanged);
    _dnatExtPortCtrl.addListener(_onChanged);
    _dnatIntPortCtrl.addListener(_onChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _masqSourceIpCtrl.dispose();
    _snatSourceIpCtrl.dispose();
    _snatNewSourceIpCtrl.dispose();
    _dnatDestIpCtrl.dispose();
    _dnatExtPortCtrl.dispose();
    _dnatIntPortCtrl.dispose();
    super.dispose();
  }

  // ─── Load Interfaces ──────────────────────
  Future<void> _loadInterfaces() async {
    try {
      final interfaces = await _service.getInterfaces();
      if (mounted) setState(() => _interfaces = interfaces);
    } catch (e) {
      print('Error loading interfaces: $e');
      if (mounted) setState(() => _interfaces = []);
    }
  }

  // ─── Reset Fields ─────────────────────────
  void _resetFields() {
    _masqSourceIpCtrl.clear();
    _snatSourceIpCtrl.clear();
    _snatNewSourceIpCtrl.clear();
    _dnatDestIpCtrl.clear();
    _dnatExtPortCtrl.clear();
    _dnatIntPortCtrl.clear();
    setState(() {
      _masqInterface = null;
      _snatInterface = null;
      _dnatProtocol = null;
      _dnatInterface = null;
      _previewCommand = '';
    });
  }

  // ─── Preview (debounced) ──────────────────
  void _updatePreview() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      // ← تحقق إن في بيانات كافية قبل ما تبعت request
      final data = _buildPreviewData();
      final hasEnoughData = _hasRequiredFields(data);
      if (!hasEnoughData) {
        if (mounted) setState(() => _previewCommand = '');
        return;
      }
      try {
        final command = await _service.previewNat(data);
        if (mounted) setState(() => _previewCommand = command);
      } catch (e) {
        print('Error previewing NAT: $e');
      }
    });
  }

  bool _hasRequiredFields(Map<String, dynamic> data) {
    switch (_selectedType) {
      case NatType.masquerade:
        return (data['source_ip'] as String).isNotEmpty &&
            (data['output_interface'] as String).isNotEmpty;
      case NatType.source:
        return (data['source_ip'] as String).isNotEmpty &&
            (data['new_source_ip'] as String).isNotEmpty &&
            (data['output_interface'] as String).isNotEmpty;
      case NatType.destination:
        return (data['dest_ip'] as String).isNotEmpty &&
            (data['ext_port'] as String).isNotEmpty &&
            (data['int_port'] as String).isNotEmpty &&
            (data['protocol'] as String).isNotEmpty &&
            (data['input_interface'] as String).isNotEmpty;
    }
  }

  Map<String, dynamic> _buildPreviewData() {
    switch (_selectedType) {
      case NatType.masquerade:
        return {
          'nat_type': 'masquerade',
          'source_ip': _masqSourceIpCtrl.text.trim(),
          'output_interface': _masqInterface ?? '',
          'comment': '',
        };
      case NatType.source:
        return {
          'nat_type': 'snat',
          'source_ip': _snatSourceIpCtrl.text.trim(),
          'new_source_ip': _snatNewSourceIpCtrl.text.trim(),
          'output_interface': _snatInterface ?? '',
          'comment': '',
        };
      case NatType.destination:
        return {
          'nat_type': 'dnat',
          'input_interface': _dnatInterface ?? '',
          'dest_ip': _dnatDestIpCtrl.text.trim(),
          'int_port': _dnatIntPortCtrl.text.trim(),
          'protocol': _dnatProtocol ?? '',
          'ext_port': _dnatExtPortCtrl.text.trim(),
          'comment': '',
        };
    }
  }

  // ─── On Any Field Changed ─────────────────
  void _onChanged() {
    if (_isSuccess) setState(() => _isSuccess = false);
    _updatePreview();
  }

  // ─── Add Rule ─────────────────────────────
  Future<void> _addRule() async {
    setState(() => _isLoading = true);
    try {
      switch (_selectedType) {
        case NatType.masquerade:
          if (_masqSourceIpCtrl.text.trim().isEmpty || _masqInterface == null) {
            _showError('Please fill in all required fields');
            return;
          }
          await _service.addMasquerade(MasqueradeModel(
            sourceIp: _masqSourceIpCtrl.text.trim(),
            interface: _masqInterface!,
          ));
          break;

        case NatType.source:
          if (_snatSourceIpCtrl.text.trim().isEmpty ||
              _snatInterface == null ||
              _snatNewSourceIpCtrl.text.trim().isEmpty) {
            _showError('Please fill in all required fields');
            return;
          }
          await _service.addSourceNat(SourceNatModel(
            sourceIp: _snatSourceIpCtrl.text.trim(),
            interface: _snatInterface!,
            newSourceIp: _snatNewSourceIpCtrl.text.trim(),
          ));
          break;

        case NatType.destination:
          if (_dnatProtocol == null ||
              _dnatInterface == null ||
              _dnatDestIpCtrl.text.trim().isEmpty ||
              _dnatExtPortCtrl.text.trim().isEmpty ||
              _dnatIntPortCtrl.text.trim().isEmpty) {
            _showError('Please fill in all required fields');
            return;
          }
          await _service.addDestinationNat(DestinationNatModel(
            protocol: _dnatProtocol!,
            interface: _dnatInterface!,
            destIp: _dnatDestIpCtrl.text.trim(),
            externalPort: _dnatExtPortCtrl.text.trim(),
            internalPort: _dnatIntPortCtrl.text.trim(),
          ));
          break;
      }

      if (mounted) {
        setState(() => _isSuccess = true);
        // ← بعد ثانيتين يظهر الـ success ثم يعمل reset
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          setState(() => _isSuccess = false);
          _resetFields();
        }
      }
    } on DioException catch (e) {
      final msg = e.response?.statusCode == 409
          ? 'Rule already exists'
          : 'Connection error. Please try again.';
      _showError(msg);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NKColors.bg,
      body: Row(
        children: [
          const Sidebar(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TopBar(title: 'NAT'),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(32, 24, 32, 24),
                    child: Stack(
                      alignment: Alignment.topLeft,
                      children: [
                        // ─── Form ──────────────────────
                        SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              NatTypeSelector(
                                selected: _selectedType,
                                onChanged: (type) => setState(() {
                                  _selectedType = type;
                                  _isSuccess = false;
                                  _onChanged();
                                }),
                              ),
                              const SizedBox(height: 40),
                              _buildForm(),
                            ],
                          ),
                        ),

                        // ─── Command Preview ───────────
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 80,
                          child: CommandPreview(
                            command: _previewCommand,
                            isSuccess: _isSuccess,
                          ),
                        ),

                        // ─── FAB ───────────────────────
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: _AddButton(
                            isLoading: _isLoading,
                            onTap: _addRule,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    switch (_selectedType) {
      case NatType.masquerade:
        return MasqueradeForm(
          sourceIpController: _masqSourceIpCtrl,
          interfaces: _interfaces,
          selectedInterface: _masqInterface,
          onInterfaceChanged: (v) => setState(() {
            _masqInterface = v;
            _onChanged();
          }),
          onChanged: _onChanged,
        );
      case NatType.source:
        return SourceNatForm(
          sourceIpController: _snatSourceIpCtrl,
          newSourceIpController: _snatNewSourceIpCtrl,
          interfaces: _interfaces,
          selectedInterface: _snatInterface,
          onInterfaceChanged: (v) => setState(() {
            _snatInterface = v;
            _onChanged();
          }),
          onChanged: _onChanged,
        );
      case NatType.destination:
        return DestinationNatForm(
          destIpController: _dnatDestIpCtrl,
          externalPortController: _dnatExtPortCtrl,
          internalPortController: _dnatIntPortCtrl,
          interfaces: _interfaces,
          selectedProtocol: _dnatProtocol,
          selectedInterface: _dnatInterface,
          onProtocolChanged: (v) => setState(() {
            _dnatProtocol = v;
            _onChanged();
          }),
          onInterfaceChanged: (v) => setState(() {
            _dnatInterface = v;
            _onChanged();
          }),
          onChanged: _onChanged,
        );
    }
  }
}

// ─── Top Bar ──────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final String title;
  const _TopBar({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.rajdhani(
                  fontSize: 26,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1D242B),
                ),
              ),
              const Icon(LucideIcons.bell, size: 22, color: Color(0xFF1D242B)),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xff1d242b), height: 1),
        ],
      ),
    );
  }
}

// ─── Add Button ───────────────────────────────────────────

class _AddButton extends StatelessWidget {
  const _AddButton({required this.isLoading, required this.onTap});

  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      child: Container(
        height: 56,
        width: 56,
        decoration: BoxDecoration(
          color: const Color(0xFF3B82F6),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xff0077c0).withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: isLoading
            ? const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(
                    color: Color(0xfffafafa), strokeWidth: 2),
              )
            : const Icon(Icons.add, color: Color(0xfffafafa), size: 28),
      ),
    );
  }
}
