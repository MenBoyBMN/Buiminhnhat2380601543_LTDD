import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/attendance_service.dart';
import '../../services/camera_service.dart';
import '../../services/location_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/mood_selector.dart';

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  Position? _currentPosition;
  bool _isLoadingLocation = true;

  File? _selfieFile;
  String _qrToken = '';
  String _selectedMood = 'Happy';
  final _noteController = TextEditingController();
  bool _isSubmitting = false;

  bool _isScannerOpen = false;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    setState(() => _isLoadingLocation = true);
    final pos = await LocationService.getCurrentLocation();
    if (mounted) {
      setState(() {
        _currentPosition = pos;
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _takeSelfie() async {
    final file = await CameraService.takeSelfie();
    if (file != null && mounted) {
      setState(() => _selfieFile = file);
    }
  }

  Future<void> _pickGallery() async {
    final file = await CameraService.pickFromGallery();
    if (file != null && mounted) {
      setState(() => _selfieFile = file);
    }
  }

  Future<void> _fetchActiveQrToken() async {
    try {
      final session = await AttendanceService.getActiveQr();
      if (mounted) {
        setState(() => _qrToken = session.tokenCode);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã nhận mã QR động: ${session.tokenCode} (Còn ${session.remainingSeconds}s)'),
            backgroundColor: Colors.indigo,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể lấy mã QR động')),
        );
      }
    }
  }

  Future<void> _submitCheckIn() async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đang lấy vị trí GPS, vui lòng đợi trong giây lát...')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final result = await AttendanceService.checkIn(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        qrToken: _qrToken.isNotEmpty ? _qrToken : null,
        mood: _selectedMood,
        note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
        photoFile: _selfieFile,
      );

      if (mounted) {
        setState(() => _isSubmitting = false);
        _showSuccessDialog(result);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  void _showSuccessDialog(Map<String, dynamic> result) {
    final streak = result['streakCount'] ?? 1;
    final points = result['pointsEarned'] ?? 10;
    final totalPoints = result['totalPoints'] ?? 0;
    final distance = result['distanceMeters'] ?? 0.0;
    final isWithin = result['isWithinGeofence'] ?? true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: Colors.green, size: 48),
            ),
            const SizedBox(height: 12),
            const Text(
              'Chấm Công Thành Công!',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result['message'] ?? '',
              style: TextStyle(
                fontSize: 13,
                color: isWithin ? Colors.green.shade800 : Colors.orange.shade900,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Divider(height: 20),
            Row(
              children: [
                const Text('🔥 Chuỗi Streak: ', style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(
                  child: Text('$streak ngày liên tiếp', style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Text('⭐ Điểm tích lũy: ', style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(
                  child: Text('+$points điểm (Tổng: $totalPoints điểm)', style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Text('📍 Khoảng cách GPS: ', style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(
                  child: Text('${distance}m', style: TextStyle(color: isWithin ? Colors.green : Colors.red)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Text('😊 Tâm trạng: ', style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(
                  child: Text(_selectedMood),
                ),
              ],
            ),
          ],
        ),
        actions: [
          CustomButton(
            text: 'Hoàn Tất',
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context, true); // Trở về dashboard và reload
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chấm Công 3-Trong-1'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. CHỨC NĂNG 1: ĐỊNH VỊ GPS
            _buildSectionCard(
              title: '1. Xác Định Vị Trí GPS',
              icon: Icons.location_on,
              iconColor: Colors.red,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isLoadingLocation)
                    const Row(
                      children: [
                        SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                        SizedBox(width: 10),
                        Text('Đang lấy tọa độ GPS thực tế...'),
                      ],
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tọa độ: ${_currentPosition?.latitude.toStringAsFixed(6)}, ${_currentPosition?.longitude.toStringAsFixed(6)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Độ chính xác: ~${_currentPosition?.accuracy.toStringAsFixed(1)}m',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ],
                    ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: _fetchLocation,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Lấy lại GPS'),
                      style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. CHỨC NĂNG 2: CHỤP ẢNH MINH CHỨNG
            _buildSectionCard(
              title: '2. Chụp Ảnh Selfie Minh Chứng',
              icon: Icons.camera_alt,
              iconColor: Colors.blue,
              child: Column(
                children: [
                  if (_selfieFile != null)
                    Stack(
                      alignment: Alignment.topRight,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _selfieFile!,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        IconButton(
                          icon: const CircleAvatar(
                            backgroundColor: Colors.white,
                            radius: 14,
                            child: Icon(Icons.close, size: 16, color: Colors.red),
                          ),
                          onPressed: () => setState(() => _selfieFile = null),
                        ),
                      ],
                    )
                  else
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.face_retouching_natural, size: 36, color: Colors.grey.shade400),
                            const SizedBox(height: 6),
                            Text('Chưa chụp ảnh minh chứng', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _takeSelfie,
                          icon: const Icon(Icons.camera_front),
                          label: const Text('Chụp Selfie'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickGallery,
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Thư viện'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. CHỨC NĂNG 3: QUÉT MÃ QR CODE
            _buildSectionCard(
              title: '3. Nhận Diện Mã QR Code',
              icon: Icons.qr_code_scanner,
              iconColor: Colors.purple,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isScannerOpen)
                    SizedBox(
                      height: 220,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: MobileScanner(
                          onDetect: (capture) {
                            final List<Barcode> barcodes = capture.barcodes;
                            for (final barcode in barcodes) {
                              if (barcode.rawValue != null) {
                                setState(() {
                                  _qrToken = barcode.rawValue!;
                                  _isScannerOpen = false;
                                });
                                break;
                              }
                            }
                          },
                        ),
                      ),
                    )
                  else ...[
                    if (_qrToken.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Mã QR: $_qrToken',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () => setState(() => _qrToken = ''),
                            ),
                          ],
                        ),
                      )
                    else
                      Text(
                        'Quét mã QR được hiển thị tại sảnh văn phòng hoặc lấy mã QR động',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => setState(() => _isScannerOpen = true),
                            icon: const Icon(Icons.qr_code_scanner),
                            label: const Text('Bật Camera Quét'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _fetchActiveQrToken,
                            icon: const Icon(Icons.auto_awesome, color: Colors.purple),
                            label: const Text('Lấy mã động'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 4. TÍNH NĂNG MỚI: MOOD & WORK-ENERGY CHECK-IN
            _buildSectionCard(
              title: '4. Tâm Trạng & Năng Lượng (Mood Check-in)',
              icon: Icons.sentiment_very_satisfied,
              iconColor: Colors.amber,
              child: MoodSelector(
                selectedMood: _selectedMood,
                onMoodSelected: (mood) => setState(() => _selectedMood = mood),
              ),
            ),
            const SizedBox(height: 16),

            // 5. GHI CHÚ
            CustomTextField(
              controller: _noteController,
              label: 'Ghi chú công việc hôm nay (Tùy chọn)',
              hint: 'Ví dụ: Làm việc đúng giờ, hỗ trợ dự án A...',
              prefixIcon: Icons.notes,
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // NÚT XÁC NHẬN CHẤM CÔNG
            CustomButton(
              text: 'XÁC NHẬN CHẤM CÔNG',
              icon: Icons.check,
              isLoading: _isSubmitting,
              color: Colors.indigo.shade700,
              onPressed: _submitCheckIn,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          child,
        ],
      ),
    );
  }
}
