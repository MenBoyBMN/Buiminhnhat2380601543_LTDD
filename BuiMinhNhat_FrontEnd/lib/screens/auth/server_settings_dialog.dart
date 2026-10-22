import 'package:flutter/material.dart';
import '../../config/config_url.dart';

class ServerSettingsDialog extends StatefulWidget {
  const ServerSettingsDialog({super.key});

  @override
  State<ServerSettingsDialog> createState() => _ServerSettingsDialogState();
}

class _ServerSettingsDialogState extends State<ServerSettingsDialog> {
  late TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: ConfigUrl.baseUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _saveUrl(String url) async {
    await ConfigUrl.setBaseUrl(url);
    if (mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã cập nhật máy chủ: $url'), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.dns, color: Colors.indigo),
          SizedBox(width: 8),
          Text('Cấu Hình Server API', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chọn nhanh máy chủ phù hợp với thiết bị bạn đang chạy:',
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.computer, size: 16),
                  label: const Text('Localhost (5000)'),
                  onPressed: () => _urlController.text = 'http://localhost:5000',
                ),
                ActionChip(
                  avatar: const Icon(Icons.phone_android, size: 16),
                  label: const Text('Máy ảo Android (10.0.2.2)'),
                  onPressed: () => _urlController.text = 'http://10.0.2.2:5000',
                ),
                ActionChip(
                  avatar: const Icon(Icons.wifi, size: 16),
                  label: const Text('Conveyor LAN (192.168.123.15:45455)'),
                  onPressed: () => _urlController.text = 'http://192.168.123.15:45455',
                ),
                ActionChip(
                  avatar: const Icon(Icons.cloud, size: 16),
                  label: const Text('Conveyor Cloud'),
                  onPressed: () => _urlController.text = 'https://bigtealski73.conveyor.cloud',
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'URL API Backend',
                hintText: 'http://localhost:5000',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Gợi ý: Nếu dùng Conveyor Cloud, nhập URL dạng https://xxxx.conveyor.cloud',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () => _saveUrl(_urlController.text),
          child: const Text('Lưu & Áp Dụng'),
        ),
      ],
    );
  }
}
