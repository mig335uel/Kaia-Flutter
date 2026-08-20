import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Voicematchmakingservice {
  final supabase = Supabase.instance.client;
  RealtimeChannel? _matchChannel;
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  Future<void> buscarChat({
    required String miUserId,
    required String miPreferenceId,
    required String myGender,
    required String myPrefGender,
    required int myAge,
    required int myMinAge,
    required int myMaxAge,
    required Function(String) onMatchFound,
  }) async {
    try {
      // DEBUG: Ver exactamente qué le estamos mandando a Supabase
      print('=== DATOS ENVIADOS A SUPABASE ===');
      print('p_my_user_id: $miUserId');
      print('p_my_gender: $myGender');
      print('p_my_pref_gender: $myPrefGender');
      print('p_my_age: $myAge');
      print('p_my_min_age: $myMinAge');
      print('p_my_max_age: $myMaxAge');
      print('preference_id (para la cola): $miPreferenceId');
      print('=================================');

      // 1. Llamamos a la función SQL optimizada pasando TODOS los parámetros
      final matchedUserId = await supabase.rpc(
        'find_voice_match',
        params: {
          'p_my_user_id': miUserId,
          'p_my_gender': myGender,
          'p_my_pref_gender': myPrefGender,
          'p_my_age': myAge,
          'p_my_min_age': myMinAge,
          'p_my_max_age': myMaxAge,
        },
      );

      // DEBUG: Ver qué devuelve Supabase
      print('=== RESULTADO DE SUPABASE ===');
      print('matchedUserId: $matchedUserId (tipo: ${matchedUserId.runtimeType})');
      print('=============================');

      if (matchedUserId != null) {
        // ¡MATCH INSTANTÁNEO! Había alguien esperando que cumple los requisitos
        print('¡Match instantáneo! ID: $matchedUserId');

        List<String> ids = [miUserId, matchedUserId.toString()];
        ids.sort();
        String chatId = '${ids[0]}_${ids[1]}';

        // 1.5 Crear el documento en Firestore antes de navegar

        // Avisamos a la UI para que navegue
        onMatchFound(chatId);
      } else {
        // NO HAY MATCH INMEDIATO.
        print('No hay match inmediato. Insertando en cola y esperando...');
        // 2. Metemos al usuario en la cola de Supabase
        await supabase.from('voice_matchmaking').insert({
          'user_id': miUserId,
          'preference_id': miPreferenceId, // Requerido según tu esquema
        });

        // 3. Activamos el socket para quedarnos esperando
        iniciarEscuchaDeMatch(miUserId, onMatchFound);
      }
    } catch (e) {
      print('Error buscando pareja: $e');
      // Aquí podrías manejar el error visualmente en la UI
    }
  }

  /// FUNCIÓN DE ESCUCHA (Cuando tú te quedas esperando en la cola)
  void iniciarEscuchaDeMatch(String miUserId, Function(String) onMatchFound) {
    // 1. Nos suscribimos a los UPDATES (actualizaciones) de NUESTRA fila en la tabla
    _matchChannel = supabase
        .channel(
          'public:social_voice_matchmaking',
        ) // Nombre del canal (puede ser cualquiera)
        .onPostgresChanges(
          event: PostgresChangeEvent
              .update, // ¡CAMBIO CLAVE! Escuchamos cuando ALGUIEN MÁS actualiza nuestra fila
          schema: 'public',
          table: 'social_voice_matchmaking',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: miUserId,
          ),
          callback: (PostgresChangePayload payload) {
            final registroActualizado = payload.newRecord;

            // Asumiendo que cuando alguien hace match contigo, tu fila se actualiza
            // y se llena un campo llamado 'matched_with' o similar.
            // *NOTA*: Asegúrate de que tu RPC de Supabase devuelva/guarde el ID del otro usuario aquí.
            final matchedUserId = registroActualizado['matched_with'];

            if (matchedUserId != null) {
              print(
                '¡Alguien me encontró en la cola! ID del otro: $matchedUserId',
              );

              // 2. Cerramos el canal inmediatamente para no seguir escuchando
              _detenerEscucha();

              // 3. Generamos el ID combinado para Firestore
              List<String> ids = [miUserId, matchedUserId.toString()];
              ids.sort();
              String chatId = '${ids[0]}_${ids[1]}';

              // 4. Creamos el documento en Firestore
              
            }
          },
        )
        .subscribe();
  }

  void _detenerEscucha() {
    if (_matchChannel != null) {
      supabase.removeChannel(_matchChannel!);
      _matchChannel = null;
    }
  }

  /// FUNCIÓN PARA CONECTAR CON FIRESTORE
  
}