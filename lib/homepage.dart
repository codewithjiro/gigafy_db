import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final box = Hive.box("database");
  late String username;
  String key = "xnd_development_kb2SqfRcnOXnqJjll8S43ZvB5PUAxtRnPwJ0pKRJa4a1D2j7hdzLe5jRSIVqX";
  double totalStorageGB = 0.00;

  @override
  void initState() {
    super.initState();
    username = box.get("username", defaultValue: "User");
    totalStorageGB = box.get("storage", defaultValue: 0.0);
  }

  void _showSuccessDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text("Success!"),
          content: Text(
              "Storage upgraded! You now have ${totalStorageGB.toStringAsFixed(0)} GB."),
          actions: [
            CupertinoDialogAction(
              child: const Text("Continue"),
              onPressed: () => Navigator.pop(context),
            )
          ],
        );
      },
    );
  }

  void _confirmPurchase(int price, double gb) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('Upgrade Plan'),
        message:
            Text('Get ${gb.toStringAsFixed(0)} GB cloud storage for ₱$price?'),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.pop(context);
              _processTransaction(price, gb);
            },
            child: const Text('Confirm Purchase'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  Future<void> _processTransaction(int price, double gb) async {
  showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const CupertinoAlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 10),
              CupertinoActivityIndicator(radius: 15),
              SizedBox(height: 15),
              Text("Securing Gateway...", style: TextStyle(fontSize: 14)),
            ],
          ),
        );
      });

  final url = "https://api.xendit.co/v2/invoices";
  String auth = 'Basic ' + base64Encode(utf8.encode(key));

  try {
    final response = await http.post(Uri.parse(url),
        headers: {"Authorization": auth, "Content-Type": "application/json"},
        body: jsonEncode({
          "external_id": "gigafy_${DateTime.now().millisecondsSinceEpoch}",
          "amount": price,
          "description": "${gb.toStringAsFixed(0)} GB Gigafy Storage"
        }));

    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    final data = jsonDecode(response.body);

    if (data["invoice_url"] != null) {
      Navigator.push(
          context,
          CupertinoPageRoute(
              builder: (context) => PaymentPage(url: data["invoice_url"])));
      _pollPaymentStatus(data["id"], auth, gb);
    }
  } catch (e) {
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    debugPrint("Transaction Error: $e");
  }
}

  Future<void> _pollPaymentStatus(String id, String auth, double gb) async {
    Timer.periodic(const Duration(seconds: 5), (timer) async {
      final url = "https://api.xendit.co/v2/invoices/" + id;
      try {
        final response =
            await http.get(Uri.parse(url), headers: {"Authorization": auth});
        final data = jsonDecode(response.body);

        if (data["status"] == "PAID") {
          timer.cancel();
          if (mounted) {
            setState(() {
              totalStorageGB += gb;
            });
            box.put("storage", totalStorageGB);

            if (Navigator.canPop(context)) Navigator.pop(context);

            _showSuccessDialog();
          }
        } else if (data["status"] == "EXPIRED") {
          timer.cancel();
        }
      } catch (e) {
        timer.cancel();
      }
    });
  }

  Widget _buildPlanCard(double gb, int price, Color accent, bool isDark) {
    final Color cardBg = isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white;
    final Color textColor = isDark ? CupertinoColors.white : Colors.black87;

    return GestureDetector(
      onTap: () => _confirmPurchase(price, gb),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 15, bottom: 10),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withOpacity(0.3) : accent.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              )
            ],
            border: Border.all(color: accent.withOpacity(0.1), width: 1)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accent.withOpacity(0.2), accent.withOpacity(0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15)),
              child: Icon(CupertinoIcons.cloud_upload_fill,
                  color: accent, size: 28),
            ),
            const Spacer(),
            Text(
              '${gb.toStringAsFixed(0)} GB',
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 26,
                  letterSpacing: -0.5,
                  color: textColor),
            ),
            const SizedBox(height: 5),
            Text(
              '₱$price',
              style: TextStyle(
                  color: accent, fontWeight: FontWeight.w700, fontSize: 17),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? const Color(0xFF000000) : const Color(0xFFF5F7FA);
    final Color textColor = isDark ? CupertinoColors.white : const Color(0xFF2D3436);
    final Color subTextColor = isDark ? CupertinoColors.systemGrey : const Color(0xFF636E72);
    final Color cardColor = isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white;
    final Color ringBg = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFDFE6E9);
    final Color ringInnerBg = isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white;

    return CupertinoPageScaffold(
      backgroundColor: bgColor,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: Text("Gigafy", style: TextStyle(color: textColor)),
            backgroundColor: bgColor.withOpacity(0.8),
            border: null,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Hello, $username 👋",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "Overview",
                            style: TextStyle(
                              fontSize: 16,
                              color: subTextColor,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                            color: CupertinoColors.activeBlue.withOpacity(0.1),
                            shape: BoxShape.circle),
                        child: const Icon(CupertinoIcons.person_solid,
                            color: CupertinoColors.activeBlue),
                      )
                    ],
                  ),
                  const SizedBox(height: 30),

                  Center(
                    child: Container(
                      height: 300,
                      width: 300,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: ringInnerBg,
                          boxShadow: [
                            BoxShadow(
                                color: isDark
                                  ? Colors.black.withOpacity(0.5)
                                  : const Color(0xFF007AFF).withOpacity(0.15),
                                blurRadius: 60,
                                offset: const Offset(0, 10),
                                spreadRadius: 5)
                          ]),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 240,
                            height: 240,
                            child: CustomPaint(
                              painter: StorageRingPainter(
                                percentage: 0.85,
                                color: const Color(0xFF2E86AB),
                                backgroundColor: ringBg,
                              ),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                totalStorageGB.toStringAsFixed(0),
                                style: TextStyle(
                                    fontSize: 68,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -3.0,
                                    color: textColor,
                                    height: 1),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "GB FREE",
                                style: TextStyle(
                                    fontSize: 14,
                                    color: subTextColor,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),

                  Text(
                    "Upgrade Capacity",
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 15),

                  SizedBox(
                    height: 190,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildPlanCard(15, 249, const Color(0xFF2E86AB), isDark),
                        _buildPlanCard(50, 449, const Color(0xFF6C5CE7), isDark),
                        _buildPlanCard(100, 649, const Color(0xFFFD79A8), isDark),
                        _buildPlanCard(200, 849, const Color(0xFFE17055), isDark),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.3 : 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 5))
                        ]),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00B894).withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(CupertinoIcons.shield_fill,
                              color: Color(0xFF00B894)),
                        ),
                        const SizedBox(width: 15),
                         Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Secure Encryption",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: textColor)),
                            Text("Your files are AES-256 encrypted.",
                                style: TextStyle(
                                    fontSize: 13,
                                    color: subTextColor)),
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StorageRingPainter extends CustomPainter {
  final double percentage;
  final Color color;
  final Color backgroundColor;

  StorageRingPainter(
      {required this.percentage,
      required this.color,
      required this.backgroundColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width / 2, size.height / 2);
    const strokeWidth = 22.0;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    final fgPaint = Paint()
      ..shader = LinearGradient(
        colors: [color, color.withOpacity(0.6)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * percentage;

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle,
        sweepAngle, false, fgPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class PaymentPage extends StatefulWidget {
  final String url;
  const PaymentPage({super.key, required this.url});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  late WebViewController controller;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: const Text("Secure Payment"),
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            child: const Text("Done", style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        child: WebViewWidget(controller: controller));
  }
}