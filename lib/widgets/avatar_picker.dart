import 'package:flutter/material.dart';

class AvatarPicker extends StatelessWidget {
  // දැන් මෙතැනින් return කරන්නේ image path එකක් නිසා Function(String) ලෙස වෙනස් කර ඇත
  final Function(String) onAvatarSelected;

  const AvatarPicker({super.key, required this.onAvatarSelected});

  @override
  Widget build(BuildContext context) {
    // ඔබ සතු පින්තූර වල paths මෙහි ලැයිස්තුගත කරන්න
    final List<String> avatars = [
      'assets/avatars/avatar1.png',
      'assets/avatars/avatar2.png',
      'assets/avatars/avatar3.png',
      'assets/avatars/avatar4.png',
      'assets/avatars/avatar5.png',
      'assets/avatars/avatar6.png',
      'assets/avatars/avatar7.png',
      'assets/avatars/avatar8.png',
      'assets/avatars/avatar9.png',
    ];

    return Container(
      padding: const EdgeInsets.all(25),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "ප්‍රතිරූපයක් තෝරන්න / Choose an Avatar",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1565C0)),
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 15,
              crossAxisSpacing: 15,
            ),
            itemCount: avatars.length,
            itemBuilder: (context, index) {
              return InkWell(
                onTap: () {
                  onAvatarSelected(avatars[index]);
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF06292).withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: Image.asset(avatars[index], fit: BoxFit.cover),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}