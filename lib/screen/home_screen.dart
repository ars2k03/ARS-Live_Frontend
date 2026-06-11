import 'package:ars_live/mediaSize/size.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../authService/auth_service.dart';
import '../socket/socket_service.dart';
import 'Login_Screen.dart';
import 'chat_screen.dart';

class HomePage extends StatefulWidget {
  final String name;
  final String email;
  final String picture;
  const HomePage({super.key, required this.name, required this.email, required this.picture});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  String message = "Loading...";
  String profilePicture = "";
  String currentUserId = "";
  List<dynamic> users = [];

  @override
  void initState() {
    super.initState();
    profilePicture = widget.picture;
    SocketService.connect();
    loadProfile();
    loadUsers();
  }

  @override
  void dispose() {
    SocketService.socket.disconnect();
    super.dispose();
  }

  Future <void> loadProfile() async {
    final response = await AuthService.getProfile();

    if (response["success"] == true) {

      setState(() {
        message = response["data"]["message"];
      });

      currentUserId = response["data"]["user"]["id"];

      SocketService.socket.emit(
        "register",
        currentUserId,
      );

    } else {

      setState(() {
        message = response["message"];
      });

    }

  }

  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('refreshToken');

    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
      );
    }
  }

  Future<void> loadUsers() async {

    final response = await AuthService.getUsers();

    if (response["success"] == true) {

      setState(() {
        users = response["users"];
      });

    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: context.h * .09,
        titleSpacing: 20,
        title: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundImage: NetworkImage(profilePicture),
            ),

            const SizedBox(width: 15),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.name,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  Text(
                    "Online",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        actions: [
          IconButton(
            onPressed: () async {
              final isDark = Theme.of(context).brightness == Brightness.dark;

              final result = await showDialog<bool>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    elevation: 0,

                    icon: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red.withOpacity(
                          isDark ? .18 : .10,
                        ),
                      ),
                      child: const Icon(
                        Icons.logout_rounded,
                        color: Colors.red,
                        size: 30,
                      ),
                    ),

                    title: Text(
                      "Logout",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark? Colors.white : Colors.black,
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                      ),
                    ),

                    content: Text(
                      "Are you sure you want to logout from your account? You'll need to sign in again to continue.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark? Colors.white : Colors.black,
                      ),
                    ),

                    actionsPadding: const EdgeInsets.fromLTRB(
                      20,
                      0,
                      20,
                      20,
                    ),

                    actions: [

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context, false);
                          },
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(
                              double.infinity,
                              50,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text("Cancel",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDark? Colors.white : Colors.black,
                              )
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.pop(context, true);
                          },
                          icon: const Icon(Icons.logout_rounded),
                          label: const Text("Logout"),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(
                              double.infinity,
                              50,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),

                    ],
                  );
                },
              );

              if (result == true) {
                await _handleLogout();
              }

            },
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),

      body: users.isEmpty ? SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(context.w * .04),
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Search users...",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                ),
              ),
            ),

            SizedBox(height: context.h * 0.3),

            Icon(
              Icons.people_outline_rounded,
              size: context.w * .18,
              color: Colors.grey,
            ),

            const SizedBox(height: 12),

            Text(
              "No users found",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ) :
          Column(
            children: [
              Padding(
                padding: EdgeInsets.all(context.w * .04),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Search users...",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                  ),
                ),
              ),
              Expanded(
                  child: ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {

                      final user = users[index];

                      return Container(
                        margin: EdgeInsets.symmetric(
                          horizontal: context.w * .04,
                          vertical: context.h * .006,
                        ),

                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            if (!isDark)
                              BoxShadow(
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                                color: Colors.black.withOpacity(.05),
                              ),
                          ],
                        ),

                        child: Material(
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : Colors.white70,

                          borderRadius: BorderRadius.circular(18),

                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: context.w * .04,
                              vertical: context.h * .006,
                            ),

                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                    senderId: currentUserId,
                                    receiverId: user["id"],
                                    receiverName: user["name"],
                                    receiverAvatar : user["avatar_url"],
                                  ),
                                ),
                              );
                            },

                            leading: CircleAvatar(
                              radius: 28,
                              backgroundImage: NetworkImage(
                                user["avatar_url"] ?? "",
                              ),
                            ),

                            title: Text(
                              user["name"] ?? "Unknown",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),

                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                user["email"] ?? "",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                            trailing: IconButton(
                              onPressed: () {},
                              icon: Icon(
                                Icons.wifi_calling_3,
                                size: 30,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              )
            ],
          )
    );
  }
}


