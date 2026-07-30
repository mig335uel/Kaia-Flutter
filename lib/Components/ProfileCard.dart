import 'package:flutter/material.dart';
import 'package:kaia/Data/Users.dart';
import 'package:kaia/Service/FeedService.dart';

class Profilecard extends StatefulWidget {
  const Profilecard({super.key});

  @override
  State<Profilecard> createState() => _ProfilecardState();
}

class _ProfilecardState extends State<Profilecard> {
  late Users _me;

  @override
  void initState() async {
    super.initState();
    _me = await Users.useAuth();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: FeedService.getFeedUsers(_me.id),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return ListView.builder(
            itemBuilder: (context, index) {
              return Container(
                child: Row(
                  children: [
                    Image(
                      image: NetworkImage(
                        snapshot.data![index].profile_image.toString(),
                      ),
                    ),
                    Column(
                      children: [
                        Text(snapshot.data![index].username.toString()),
                        Text(snapshot.data![index].description.toString()),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        }
        return Center(child: CircularProgressIndicator());
      },
    );
  }
}
