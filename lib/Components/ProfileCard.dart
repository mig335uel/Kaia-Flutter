import 'package:flutter/material.dart';
import 'package:kaia/Controllers/HomeFeedController.dart';
import 'package:kaia/Data/Users.dart';

class Profilecard extends StatefulWidget {
  Profilecard({super.key});

  @override
  State<Profilecard> createState() => _ProfilecardState();
}

class _ProfilecardState extends State<Profilecard> {
  final HomeFeedController _controller = HomeFeedController();
  final ScrollController _scrollController = ScrollController();

  int calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;

    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }

    return age;
  }

  @override
  void initState() {
    super.initState();
    _loadFeed();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadFeed() async {
    final me = await Users.useAuth();
    await _controller.loadInitial(me.id);
    setState(() {
      
    });
  }

  void _onScroll() async {
    if (_scrollController.position.extentAfter < 300) {
      final me = await Users.useAuth();
      await _controller.loadMore(me.id);
      setState(() {});
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refreshFeed() async {
    final me = await Users.useAuth();
    await _controller.loadInitial(me.id);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Mostrar loading si está cargando y no hay perfiles aún
    if (_controller.isLoading && _controller.profiles.isEmpty) {
      return Center(child: CircularProgressIndicator());
    }

    // Si no hay perfiles
    if (_controller.profiles.isEmpty) {
      return Center(child: Text('No hay usuarios disponibles'));
    }

    return RefreshIndicator(
      onRefresh: _refreshFeed,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _controller.profiles.length,
        itemBuilder: (context, index) {
          final user = _controller.profiles[index];

          return GestureDetector(
            onTap: () {},
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withOpacity(0.2)
                        : Colors.black.withOpacity(0.1),
                  ),
                  bottom: BorderSide(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withOpacity(0.2)
                        : Colors.black.withOpacity(0.1),
                  ),
                ),
              ),
              margin: EdgeInsets.only(left: 10, bottom: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(
                      user.profile_image ??
                          'https://cdn-icons-png.flaticon.com/512/149/149071.png',
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Text(
                                    user.username.toString(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: user.gender == "Male"
                                          ? const Color.fromARGB(
                                              255,
                                              14,
                                              146,
                                              255,
                                            )
                                          : Color.fromARGB(255, 255, 86, 142),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          user.gender == "Male"
                                              ? Icons.male
                                              : Icons.female_outlined,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                        
                                        Text(
                                          calculateAge(
                                            DateTime.parse(
                                              user.birth_date.toString(),
                                            ),
                                          ).toString(),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 6),
                        Text(
                          user.description ?? 'Este usuario es nuevo',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
