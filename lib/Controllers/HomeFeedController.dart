


import 'package:kaia/Data/Users.dart';
import 'package:kaia/Service/FeedService.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeFeedController {
  final _supabase = Supabase.instance.client;

  final List<Users> _profiles = [];

  int _offset = 0;
  final int _limit = 10;

  bool _isLoading = false;
  bool _hasMore = true;

  List<Users> get profiles => _profiles;

  bool get hasMore => _hasMore;

  bool get isLoading => _isLoading;

  Future<void> loadInitial(String userId) async {

    _offset = 0;
    _profiles.clear();

    final users = await FeedService().getFeedUsers(
      userId,
      _limit,
      _offset,
    );

    _profiles.addAll(users);

    _offset += users.length;

  }

  Future<void> loadMore(String userId) async {

    if (_isLoading || !_hasMore) return;

    _isLoading = true;

    final users = await FeedService().getFeedUsers(
      userId,
      _limit,
      _offset,
    );

    if(users.isEmpty){
      _hasMore = false;
    }else{
      _profiles.addAll(users);
      _offset += users.length;
    }

    _isLoading = false;
  }
}