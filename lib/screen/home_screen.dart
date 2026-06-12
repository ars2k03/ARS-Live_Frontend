import 'package:ars_live/mediaSize/size.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../authService/auth_service.dart';
import '../socket/socket_service.dart';
import 'Login_Screen.dart';
import 'call/calling.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isLoading = true;

  String name = "";
  String email = "";
  String picture = "";
  String phoneNumber = "";

  String currentUserId = "";
  List<dynamic> users = [];

  @override
  void initState() {
    super.initState();
    SocketService.connect();
    loadProfile();
  }

  @override
  void dispose() {
    SocketService.socket.off("incoming-call");
    SocketService.socket.off("user-offline");
    super.dispose();
  }

  Future<void> loadProfile() async {
    try {
      final response = await AuthService.getProfile();

      if (response["success"] == true) {
        final user = response["data"]["user"];

        if (!mounted) return;

        setState(() {
          name = user["name"] ?? "";
          email = user["email"] ?? "";
          picture = user["picture"] ?? "";
          phoneNumber = user["phoneNumber"] ?? "";
          isLoading = false;
        });

        currentUserId = user["id"];

        SocketService.socket.emit("register", currentUserId);

        setupCallListeners();

        await loadUsers();
      } else {
        if (!mounted) return;

        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Profile Error: $e");

      if (!mounted) return;

      setState(() {
        isLoading = false;
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

  void setupCallListeners() {
    SocketService.socket.off("incoming-call");
    SocketService.socket.off("user-offline");

    // NOTE: "call-accepted" and "call-rejected" are handled inside
    // CallScreen itself (for the caller side). Do NOT register them
    // here, otherwise they'll be removed when CallScreen calls
    // socket.off() in its dispose().

    SocketService.socket.on("incoming-call", (data) {
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CallScreen(
            picture: data["callerPicture"] ?? "",
            callerName: data["callerName"],
            isIncoming: true,
            callerId: data["callerId"],
            currentUserId: currentUserId,
          ),
        ),
      );
    });

    SocketService.socket.on("user-offline", (data) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("User is Offline"),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: context.h * .09,
        titleSpacing: 20,
        title: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundImage: picture.isNotEmpty ? NetworkImage(picture) : null,
              child: picture.isEmpty ? const Icon(Icons.person) : null,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            showDragHandle: true,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(24),
                              ),
                            ),
                            builder: (context) {
                              return Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.verified,
                                      color: Colors.blue,
                                      size: 60,
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      "Verified Account",
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      "This account has been verified by ARS Live. "
                                          "You can trust that this user is authentic.",
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 24),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                        child: const Icon(
                          Icons.verified,
                          color: Colors.blue,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    phoneNumber,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.amber : Colors.brown,
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
                        color: Colors.red.withOpacity(isDark ? .18 : .10),
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
                        color: isDark ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                      ),
                    ),
                    content: Text(
                      "Are you sure you want to logout from your account? You'll need to sign in again to continue.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    actions: [
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context, false);
                          },
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            "Cancel",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black,
                            ),
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
                            minimumSize: const Size(double.infinity, 50),
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
      body: users.isEmpty
          ? SingleChildScrollView(
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
      )
          : Column(
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
                    color: isDark ? const Color(0xFF1E293B) : Colors.white70,
                    borderRadius: BorderRadius.circular(18),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: context.w * .04,
                        vertical: context.h * .006,
                      ),
                      onTap: () {},
                      leading: CircleAvatar(
                        radius: 28,
                        backgroundImage: NetworkImage(user["avatar_url"] ?? ""),
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
                          user["phone_number"] ?? "",
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      trailing: IconButton(
                        onPressed: () {
                          // Remove our own listeners temporarily so they
                          // don't interfere while CallScreen takes over.
                          SocketService.socket.off("incoming-call");
                          SocketService.socket.off("user-offline");

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CallScreen(
                                picture: user["avatar_url"],
                                callerName: user["name"],
                                isIncoming: false,
                                callerId: user["id"],
                                currentUserId: currentUserId,
                              ),
                            ),
                          ).then((_) {
                            // Re-register listeners once back on HomePage
                            if (mounted) setupCallListeners();
                          });

                          SocketService.socket.emit("call-user", {
                            "callerId": currentUserId,
                            "callerName": name,
                            "receiverId": user["id"],
                            "callerPicture": picture,
                          });
                        },
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
          ),
        ],
      ),
    );
  }
}