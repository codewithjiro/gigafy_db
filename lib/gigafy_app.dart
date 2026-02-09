import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'homepage.dart';
import 'main.dart';

class GigafyApp extends StatefulWidget {
  const GigafyApp({super.key});

  @override
  State<GigafyApp> createState() => _GigafyAppState();
}

class _GigafyAppState extends State<GigafyApp> {
  bool isDark = false;
  final box = Hive.box("database");

  @override
  void initState() {
    super.initState();
    isDark = box.get('isDark', defaultValue: false);
  }

  void toggleTheme(bool value) {
    setState(() => isDark = value);
    box.put('isDark', value);
  }

  void toggleBiometrics(bool value) {
    box.put("biometrics", value);
    setState(() {});
  }

  void _showLogoutDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text("Sign Out?"),
          content: const Text("Are you sure you want to log out?"),
          actions: [
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: const Text("Sign Out"),
              onPressed: () {
                Navigator.pop(context);
                Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                  CupertinoPageRoute(builder: (context) => const LoginPage()),
                  (Route<dynamic> route) => false,
                );
              },
            ),
            CupertinoDialogAction(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  void _showTeamDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text("Gigafy Team"),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 15),
              Text("Jiro Gonzales"),
              Text("Joyce Manaloto"),
              Text("Ashley Guttierez"),
              Text("Jenah Ambagan"),
              SizedBox(height: 15),
            ],
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text("Close"),
              onPressed: () => Navigator.pop(context),
            )
          ],
        );
      },
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    Widget? trailing,
    required Color color,
    VoidCallback? onTap,
    String? subtitle,
  }) {
    final tileColor = isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    return Material(
      color: Colors.transparent,
      child: CupertinoListTile(
        onTap: onTap,
        backgroundColor: tileColor,
        leading: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: color,
              boxShadow: [
                BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 3))
              ]),
          child: Icon(icon, size: 18, color: CupertinoColors.white),
        ),
        trailing: trailing ??
            const Icon(CupertinoIcons.chevron_forward,
                color: CupertinoColors.systemGrey3),
        title: Text(title,
            style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
        additionalInfo: subtitle != null ? Text(subtitle) : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isBiometricEnabled = box.get("biometrics") ?? false;

    final Color bgColor =
        isDark ? const Color(0xFF000000) : const Color(0xFFF5F7FA);
    final Color barColor = isDark
        ? const Color(0xFF1C1C1E).withOpacity(0.9)
        : const Color(0xFFFFFFFF).withOpacity(0.9);
    return CupertinoApp(
      title: "Gigafy",
      debugShowCheckedModeBanner: false,
      theme: CupertinoThemeData(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primaryColor: const Color(0xFF2E86AB),
        scaffoldBackgroundColor: bgColor,
        barBackgroundColor: barColor,
      ),
      home: CupertinoTabScaffold(
          tabBar: CupertinoTabBar(
            activeColor: const Color(0xFF2E86AB),
            backgroundColor: barColor,
            items: const [
              BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.waveform), label: "Storage"),
              BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.settings_solid), label: "Settings"),
            ],
          ),
          tabBuilder: (context, index) {
            switch (index) {
              case 0:
                return const Homepage();
              default:
                return CupertinoPageScaffold(
                  backgroundColor: CupertinoDynamicColor.resolve(
                      CupertinoColors.systemGroupedBackground, context),
                  child: CustomScrollView(
                    slivers: [
                      const CupertinoSliverNavigationBar(
                          largeTitle: Text("Settings")),
                      SliverList(
                        delegate: SliverChildListDelegate([
                          CupertinoListSection.insetGrouped(
                            header: const Text("General"),
                            backgroundColor: Colors.transparent,
                            children: [
                              _buildTile(
                                  icon: CupertinoIcons.cloud_fill,
                                  title: "Current Plan",
                                  trailing: const Text("Free Tier",
                                      style: TextStyle(
                                          color: CupertinoColors.systemGrey)),
                                  color: CupertinoColors.systemBlue),
                              _buildTile(
                                  icon: CupertinoIcons.moon_fill,
                                  title: "Dark Mode",
                                  trailing: CupertinoSwitch(
                                      value: isDark,
                                      onChanged: (v) => toggleTheme(v)),
                                  color: CupertinoColors.systemIndigo),
                            ],
                          ),
                          CupertinoListSection.insetGrouped(
                              header: const Text("Security"),
                              backgroundColor: Colors.transparent,
                              children: [
                                _buildTile(
                                    icon: Icons.fingerprint,
                                    title: "Biometrics",
                                    color: CupertinoColors.systemGreen,
                                    trailing: CupertinoSwitch(
                                        value: isBiometricEnabled,
                                        onChanged: (v) => toggleBiometrics(v))),
                              ]),
                          CupertinoListSection.insetGrouped(
                              header: const Text("Information"),
                              backgroundColor: Colors.transparent,
                              children: [
                                _buildTile(
                                    icon: CupertinoIcons.person_2_fill,
                                    title: "About Team",
                                    color: CupertinoColors.systemPink,
                                    onTap: () => _showTeamDialog(context)),
                              ]),
                          CupertinoListSection.insetGrouped(
                            backgroundColor: Colors.transparent,
                            children: [
                              _buildTile(
                                  icon: CupertinoIcons.arrow_right_circle_fill,
                                  title: "Sign Out",
                                  color: CupertinoColors.systemRed,
                                  onTap: () => _showLogoutDialog(context)),
                            ],
                          )
                        ]),
                      )
                    ],
                  ),
                );
            }
          }),
    );
  }
}