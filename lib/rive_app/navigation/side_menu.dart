import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rive/rive.dart';
import 'package:flutter_samples/rive_app/components/menu_row.dart';
import 'package:flutter_samples/rive_app/models/menu_item.dart';
import 'package:flutter_samples/rive_app/models/user_model.dart';
import 'package:flutter_samples/rive_app/services/user_provider.dart';
import 'package:flutter_samples/rive_app/screens/profile_screen.dart';
import 'package:flutter_samples/rive_app/screens/search_screen.dart';
import 'package:flutter_samples/rive_app/screens/practice_screen.dart';
import 'package:flutter_samples/rive_app/screens/chat_screen.dart';
import 'package:flutter_samples/rive_app/screens/learning_path_screen.dart';
import 'package:flutter_samples/rive_app/screens/notifications_screen.dart';
import 'package:flutter_samples/rive_app/theme.dart';
import 'package:flutter_samples/rive_app/theme_provider.dart';
import 'package:flutter_samples/rive_app/assets.dart' as app_assets;
import 'dart:math' as math;

class SideMenu extends StatefulWidget {
  const SideMenu({Key? key}) : super(key: key);

  @override
  State<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> {
  final List<MenuItemModel> _browseMenuIcons = MenuItemModel.menuItems;
  final List<MenuItemModel> _historyMenuIcons = MenuItemModel.menuItems2;
  final List<MenuItemModel> _themeMenuIcon = MenuItemModel.menuItems3;
  String _selectedMenu = MenuItemModel.menuItems[0].title;

  void onThemeRiveIconInit(artboard) {
    final controller = StateMachineController.fromArtboard(
        artboard, _themeMenuIcon[0].riveIcon.stateMachine);
    artboard.addController(controller!);
    _themeMenuIcon[0].riveIcon.status =
        controller.findInput<bool>("active") as SMIBool;
  }

  void onMenuPress(MenuItemModel menu, BuildContext context) {
    setState(() {
      _selectedMenu = menu.title;
    });
    
    // Close the sidebar when Home is selected
    if (menu.title == "Home") {
      // Close the menu if it's open
      final homeScreen = Navigator.of(context).widget;
      if (homeScreen is Navigator) {
        // Pop until we reach the home screen
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
    else if (menu.title == "Profile") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfileScreen()),
      );
    }
    else if (menu.title == "Search") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SearchScreen()),
      );
    }
    else if (menu.title == "Favorites") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PracticeScreen()),
      );
    }
    else if (menu.title == "Help") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ChatScreen()),
      );
    }
    else if (menu.title == "History") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LearningPathScreen()),
      );
    }
    else if (menu.title == "Notification") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const NotificationsScreen()),
      );
    }
  }

  void onThemeToggle(value) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    themeProvider.setDarkMode(value);
    _themeMenuIcon[0].riveIcon.status!.change(value);
  }

  void _handleSignOut() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    userProvider.logout();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final bool isAuthenticated = userProvider.isAuthenticated;
    final UserModel? currentUser = userProvider.currentUser;
    
    return Container(
      padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top,
          bottom: math.max(0, MediaQuery.of(context).padding.bottom - 60)),
      constraints: const BoxConstraints(maxWidth: 288),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDarkMode ? RiveAppTheme.background2Dark : RiveAppTheme.background2,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User header section with profile picture, name, and level
          InkWell(
            onTap: () {
              if (isAuthenticated) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    foregroundColor: Colors.white,
                    child: isAuthenticated 
                        ? Text(
                            currentUser!.name.isNotEmpty 
                                ? currentUser.name[0].toUpperCase() 
                                : '?',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          )
                        : const Icon(Icons.person_outline),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAuthenticated ? currentUser!.name : "Guest User",
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontFamily: "Inter"),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        if (isAuthenticated)
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  "LVL ${currentUser!.level}",
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "${currentUser.xpPoints} XP",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          )
                        else
                          Text(
                            "Sign in to save progress",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 15,
                              fontFamily: "Inter",
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (isAuthenticated)
                    IconButton(
                      icon: const Icon(
                        Icons.logout,
                        color: Colors.white70,
                        size: 20,
                      ),
                      onPressed: _handleSignOut,
                      tooltip: "Sign Out",
                    ),
                ],
              ),
            ),
          ),
          
          // Display streak if authenticated
          if (isAuthenticated)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.local_fire_department,
                    color: Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "${currentUser!.streak} day streak",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "Today",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
          MenuButtonSection(
              title: "BROWSE",
              selectedMenu: _selectedMenu,
              menuIcons: _browseMenuIcons,
              onMenuPress: (menu) => onMenuPress(menu, context)),
          MenuButtonSection(
              title: "HISTORY",
              selectedMenu: _selectedMenu,
              menuIcons: _historyMenuIcons,
              onMenuPress: (menu) => onMenuPress(menu, context)),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(children: [
              SizedBox(
                width: 32,
                height: 32,
                child: Opacity(
                  opacity: 0.6,
                  child: RiveAnimation.asset(
                    app_assets.iconsRiv,
                    stateMachines: [_themeMenuIcon[0].riveIcon.stateMachine],
                    artboard: _themeMenuIcon[0].riveIcon.artboard,
                    onInit: onThemeRiveIconInit,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  _themeMenuIcon[0].title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontFamily: "Inter",
                      fontWeight: FontWeight.w600),
                ),
              ),
              CupertinoSwitch(value: isDarkMode, onChanged: onThemeToggle),
            ]),
          )
        ],
      ),
    );
  }
}

class MenuButtonSection extends StatelessWidget {
  const MenuButtonSection(
      {Key? key,
      required this.title,
      required this.menuIcons,
      this.selectedMenu = "Home",
      this.onMenuPress})
      : super(key: key);

  final String title;
  final String selectedMenu;
  final List<MenuItemModel> menuIcons;
  final Function(MenuItemModel menu)? onMenuPress;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding:
              const EdgeInsets.only(left: 24, right: 24, top: 10, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 15,
                fontFamily: "Inter",
                fontWeight: FontWeight.w600),
          ),
        ),
        Container(
          margin: const EdgeInsets.all(8),
          child: Column(
            children: [
              for (var menu in menuIcons) ...[
                Divider(
                    color: Colors.white.withOpacity(0.1),
                    thickness: 1,
                    height: 1,
                    indent: 16,
                    endIndent: 16),
                MenuRow(
                  menu: menu,
                  selectedMenu: selectedMenu,
                  onMenuPress: () => onMenuPress!(menu),
                ),
              ]
            ],
          ),
        ),
      ],
    );
  }
}
