import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:kaia/Data/Users.dart';
import 'package:kaia/Service/FeedService.dart';

class Profilecard extends StatefulWidget {
  Profilecard({super.key});

  @override
  State<Profilecard> createState() => _ProfilecardState();
}

class _ProfilecardState extends State<Profilecard> {
  late Future<List<Users>> _feedUsersFuture;
  int calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;

    // Verificar si el cumpleaños ya pasó este año
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }

    return age;
  }

  @override
  void initState() {
    super.initState();
    _feedUsersFuture = _fetchFeedUsers();
  }

  Future<List<Users>> _fetchFeedUsers() async {
    final me = await Users.useAuth();
    return await FeedService().getFeedUsers(me.id);
  }

  Future<void> _refreshFeed() async {
    setState(() {
      _feedUsersFuture = _fetchFeedUsers();
    });
    // Esperar a que termine para que el RefreshIndicator sepa cuándo ocultarse
    await _feedUsersFuture;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Users>>(
      future: _feedUsersFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshFeed,
              child: ListView.builder(
                itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
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
                        Image(
                          image: NetworkImage(
                            snapshot.data![index].profile_image ??
                                'https://cdn-icons-png.flaticon.com/512/149/149071.png',
                          ),
                          width: 60,
                          height: 60,
                        ),
                        SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  snapshot.data![index].username.toString(),
                                  textAlign: TextAlign.justify,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                  ),
                                ),
                                SizedBox(width: 5),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 5),
                                  decoration: BoxDecoration(
                                    color:
                                        snapshot.data![index].gender == "Male"
                                        ? const Color.fromARGB(
                                            255,
                                            14,
                                            146,
                                            255,
                                          )
                                        : Color.fromARGB(255, 255, 86, 142),
                                    borderRadius: BorderRadius.circular(9999),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        snapshot.data![index].gender == "Male"
                                            ? Icons.male
                                            : Icons.female,
                                        size: 15,
                                        color: Colors.white,
                                      ),
                                      Text(
                                        calculateAge(
                                          DateTime.parse(
                                            snapshot.data![index].birth_date
                                                .toString(),
                                          ),
                                        ).toString(),
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              snapshot.data![index].description ??
                                  'Este usuario es nuevo',
                              textAlign: TextAlign.justify,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            ),
          );
        }
        if (snapshot.hasError) {
          return Expanded(
            child: Center(
              child: Text('Ha ocurrido un error: ${snapshot.error}'),
            ),
          );
        }
        return const Expanded(
          child: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
