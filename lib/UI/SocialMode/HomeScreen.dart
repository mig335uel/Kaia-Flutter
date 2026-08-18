import 'package:flutter/material.dart';
import 'package:kaia/Components/GameCards.dart';
import 'package:kaia/Components/ProfileCard.dart';
import 'package:kaia/Service/AuthService.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Estado real de las preferencias en la clase
  RangeValues _ageRange = const RangeValues(18, 30);
  String _genderPref = 'todos'; // 'chicos', 'chicas' o 'todos'
  bool _isUnder16 = false;

  @override
  void initState() {
    super.initState();
    _fetchPreferences();
  }

  Future<void> _fetchPreferences() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final userData = await Supabase.instance.client
            .from('users')
            .select('birth_date')
            .eq('id', user.id)
            .maybeSingle();

        if (userData != null && userData['birth_date'] != null) {
          final birthDate = DateTime.parse(userData['birth_date']);
          final age = DateTime.now().difference(birthDate).inDays / 365.25;
          _isUnder16 = age < 16;
        }

        final prefData = await Supabase.instance.client
            .from('user_preferences')
            .select()
            .eq('user_id', user.id)
            .maybeSingle();

        if (prefData != null && mounted) {
          setState(() {
            double minAge = (prefData['min_age_range'] as num).toDouble();
            double maxAge = (prefData['max_age_range'] as num).toDouble();
            if (_isUnder16) {
              minAge = 13;
              maxAge = 16;
            }
            _ageRange = RangeValues(minAge, maxAge);

            final genderFeed = prefData['genderFeed'] as String;
            if (genderFeed == 'Male') {
              _genderPref = 'chicos';
            } else if (genderFeed == 'Female') {
              _genderPref = 'chicas';
            } else {
              _genderPref = 'todos';
            }
          });
        }
      } catch (e) {
        print("Error fetching preferences: $e");
      }
    }
  }

  void _updatePreferencesAndReloadFeed(
    RangeValues newAge,
    String newGender,
  ) async {
    setState(() {
      _ageRange = newAge;
      _genderPref = newGender;
    });

    print(
      "📡 Subiendo a BD -> Edad: ${_ageRange.start.round()}-${_ageRange.end.round()}, Género: $_genderPref",
    );

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      String genderFeed = 'All';
      if (_genderPref == 'chicos')
        genderFeed = 'Male';
      else if (_genderPref == 'chicas')
        genderFeed = 'Female';

      try {
        await Supabase.instance.client
            .from('user_preferences')
            .update({
              'min_age_range': _isUnder16 ? 13 : _ageRange.start.round(),
              'max_age_range': _isUnder16 ? 16 : _ageRange.end.round(),
              'genderFeed': genderFeed,
            })
            .eq('user_id', user.id);
      } catch (e) {
        print("Error updating preferences: $e");
      }
    }

    _loadFeed();
  }

  void _loadFeed() {
    print("🔄 Recargando el feed de usuarios con las nuevas preferencias...");
    // Aquí harás el SELECT a Supabase para buscar usuarios
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Image.asset("assets/kaia.png", width: 40, height: 40),
            Text(
              "Inicio",
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            GestureDetector(
              onTap: () {
                // Variables temporales mientras el modal está abierto
                RangeValues tempAgeRange = _ageRange;
                String tempGender = _genderPref;

                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (context) {
                    return StatefulBuilder(
                      builder: (BuildContext context, StateSetter setModalState) {
                        final isDark =
                            Theme.of(context).brightness == Brightness.dark;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 24,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1C1C1E)
                                : Colors.white,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(25),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize
                                .min, // ¡Esto es clave para que no dé error de altura infinita!
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Center(
                                child: Container(
                                  width: 40,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: Colors.grey,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  margin: const EdgeInsets.only(bottom: 20),
                                ),
                              ),
                              Text(
                                "Preferencias de Feed",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                              const SizedBox(height: 11),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      setModalState(() {
                                        tempGender = 'chicos';
                                      });
                                    },
                                    child: Container(
                                      height: 96,
                                      width: 96,
                                      decoration: BoxDecoration(
                                        color: tempGender == 'chicos'
                                            ? (isDark
                                                  ? Colors.blue.shade900
                                                  : const Color(0xFF87C8FF))
                                            : (isDark
                                                  ? Colors.grey.shade800
                                                  : Colors.grey.shade200),
                                        borderRadius: BorderRadius.circular(15),
                                        border: tempGender == 'chicos'
                                            ? Border.all(
                                                color: const Color(0xFF0085FF),
                                                width: 2,
                                              )
                                            : null,
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.male,
                                            color: tempGender == 'chicos'
                                                ? const Color(0xFF0085FF)
                                                : Colors.grey,
                                            size: 48,
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            "Chicos",
                                            style: TextStyle(
                                              color: tempGender == 'chicos'
                                                  ? const Color(0xFF0085FF)
                                                  : Colors.grey,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      setModalState(() {
                                        tempGender = 'chicas';
                                      });
                                    },
                                    child: Container(
                                      height: 96,
                                      width: 96,
                                      decoration: BoxDecoration(
                                        color: tempGender == 'chicas'
                                            ? (isDark
                                                  ? Colors.pink.shade900
                                                  : const Color(0xFFFF87C8))
                                            : (isDark
                                                  ? Colors.grey.shade800
                                                  : Colors.grey.shade200),
                                        borderRadius: BorderRadius.circular(15),
                                        border: tempGender == 'chicas'
                                            ? Border.all(
                                                color: const Color(0xFFFF0085),
                                                width: 2,
                                              )
                                            : null,
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.female,
                                            color: tempGender == 'chicas'
                                                ? const Color(0xFFFF0085)
                                                : Colors.grey,
                                            size: 48,
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            "Chicas",
                                            style: TextStyle(
                                              color: tempGender == 'chicas'
                                                  ? const Color(0xFFFF0085)
                                                  : Colors.grey,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      setModalState(() {
                                        tempGender = 'todos';
                                      });
                                    },
                                    child: Container(
                                      height: 96,
                                      width: 96,
                                      decoration: BoxDecoration(
                                        color: tempGender == 'todos'
                                            ? (isDark
                                                  ? Colors.purple.shade900
                                                  : const Color(0xFFD0B3F2))
                                            : (isDark
                                                  ? Colors.grey.shade800
                                                  : Colors.grey.shade200),
                                        borderRadius: BorderRadius.circular(15),
                                        border: tempGender == 'todos'
                                            ? Border.all(
                                                color: const Color(0xFF8E2DE2),
                                                width: 2,
                                              )
                                            : null,
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.wc,
                                            color: tempGender == 'todos'
                                                ? const Color(0xFF8E2DE2)
                                                : Colors.grey,
                                            size: 48,
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            "Todos",
                                            style: TextStyle(
                                              color: tempGender == 'todos'
                                                  ? const Color(0xFF8E2DE2)
                                                  : Colors.grey,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 30),
                              Text(
                                _isUnder16
                                    ? "Rango de Edad (Fijo por ser menor de 16 años)"
                                    : "Rango de Edad",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                              const SizedBox(height: 15),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "${_isUnder16 ? 13 : tempAgeRange.start.round()} años",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                  Text(
                                    "${_isUnder16 ? 16 : tempAgeRange.end.round()} años",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: const Color(0xFF8E2DE2),
                                  inactiveTrackColor: isDark
                                      ? Colors.grey.shade800
                                      : Colors.grey.shade300,
                                  thumbColor: const Color(0xFF8E2DE2),
                                  overlayColor: const Color(
                                    0xFF8E2DE2,
                                  ).withOpacity(0.2),
                                ),
                                child: RangeSlider(
                                  values: _isUnder16
                                      ? const RangeValues(13, 16)
                                      : tempAgeRange,
                                  min: _isUnder16 ? 13 : 18,
                                  max: _isUnder16 ? 16 : 99,
                                  divisions: _isUnder16 ? 3 : 81,
                                  onChanged: _isUnder16
                                      ? null
                                      : (RangeValues values) {
                                          setModalState(() {
                                            tempAgeRange = values;
                                          });
                                        },
                                ),
                              ),
                              const SizedBox(height: 30),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF8E2DE2),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text(
                                  "Guardar y Cerrar",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ).whenComplete(() {
                  // SE ACABA DE CERRAR EL MODAL
                  // Comprobamos si hubo algún cambio real antes de llamar a la base de datos
                  if (_ageRange != tempAgeRange || _genderPref != tempGender) {
                    _updatePreferencesAndReloadFeed(tempAgeRange, tempGender);
                  }
                });
              },
              child: Icon(
                Icons.settings,
                color: Theme.of(context).textTheme.bodyLarge?.color,
                size: 30,
              ),
            ),
          ],
        ),
      ),

      body: Column(
        children: [
          GameCards(),
          ElevatedButton(
            onPressed: () {
              AuthService.signOut();
            },
            child: Text("Cerrar Sesión"),
          ),
          Expanded(child: Profilecard()),
        ],
      ),
    );
  }
}
