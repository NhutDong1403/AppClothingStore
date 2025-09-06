import 'package:appbanquanao/screens/payonl/PaymentSuccessScreen.dart';
import 'package:flutter/material.dart';

class FakeQrPaymentScreen extends StatelessWidget {
  const FakeQrPaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán online'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Quét mã QR bằng app ví điện tử (giả lập)',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // ✅ Dùng ảnh QR tĩnh từ assets
            Image.asset(
              'assets/image/demo_qr.png',
              width: 200,
              height: 200,
              fit: BoxFit.contain,
            ),

            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => const PaymentSuccessScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Xác nhận đã thanh toán'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
