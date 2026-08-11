import 'package:kaia/UI/DatingMode/Home.dart';
import 'package:kaia/UI/SocialMode/Home.dart';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ModeViewController {
  String? appMode;


  ModeViewController({
    required this.appMode
  });


  Widget AppModeContext(){
    if(appMode == 'dating'){
      return DatingHome();
    }else{
      return SocialHome();
    }
  }
  Stream<Widget> appmodeChange(String userId) {
    Supabase.instance.client
        .channel('public:users')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'users',
          callback: (payload) {
            switch (payload.newRecord['app_mode']) {
              case 'Social':
                appMode = 'social';
                break;
              case 'Dating':
                appMode = 'dating';
                break;
              case null:
                appMode = 'social';
                break;
            }
          },
        )
        .subscribe();

    switch(appMode){
      case 'social':
        return Stream.value(SocialHome());
      case 'dating':
        return Stream.value(DatingHome());
      default:
        return Stream.value(SocialHome());
    }
  }
}
