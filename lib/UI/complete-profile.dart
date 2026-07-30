import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kaia/UI/Home.dart';
import 'package:kaia/Service/NotificationService.dart';

class CompleteProfile extends StatefulWidget {
  const CompleteProfile({super.key});

  @override
  State<CompleteProfile> createState() => _CompleteProfileState();
}

class _CompleteProfileState extends State<CompleteProfile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  
  bool _isLoading = false;
  DateTime? _selectedDate;

  @override
  void initState() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _fetchAndSetUser();
    super.initState();
  }

  void _fetchAndSetUser() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final metadata = user.userMetadata ?? {};
      String fullName = metadata['full_name'] ?? '';
      List<String> nameParts = fullName.split(' ');
      if (mounted) {
        setState(() {
          _nameController.text = nameParts.isNotEmpty ? nameParts.first : '';
          _lastNameController.text = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _genderController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_nameController.text.isEmpty ||
        _lastNameController.text.isEmpty ||
        _usernameController.text.isEmpty ||
        _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('pleaseFillAllFields'.tr())),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final http = HttpClient();
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('No user found');

      final profileImageUrl = user.userMetadata?['avatar_url'];

      final responseIp = await http.getUrl(Uri.parse("https://ifconfig.me/all.json"));
      final response = await responseIp.close();
      final responseBody = await response.transform(utf8.decoder).join();
      
      final data = json.decode(responseBody);
      final IP = data['ip_addr'];

      final responseCountry = await http.getUrl(Uri.parse("http://ip-api.com/json/$IP"));
      final responseCoutry = await responseCountry.close();
      final responseBodyCountry = await responseCoutry.transform(utf8.decoder).join();
      final dataCountry = json.decode(responseBodyCountry);
      final country = dataCountry['country'];

      await Supabase.instance.client.from('users').insert({
        'id': user.id,
        'name': _nameController.text,
        'last_name': _lastNameController.text,
        'username': _usernameController.text,
        'birth_date': "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}",
        'profile_image': profileImageUrl,
        'gender': _genderController.text,
        'country': country,
      });

      final ageInYears = DateTime.now().difference(_selectedDate!).inDays / 365.25;

      int minAgeRange = 18;
      int maxAgeRange = 99;

      if (ageInYears < 16) {
        minAgeRange = 13;
        maxAgeRange = 16;
      } else if (ageInYears >= 16 && ageInYears < 18) {
        minAgeRange = 16;
        maxAgeRange = 25;
      } else {
        minAgeRange = 18;
        maxAgeRange = 25;
      }

      await Supabase.instance.client.from('user_preferences').insert({
        'user_id': user.id,
        'min_age_range': minAgeRange,
        'max_age_range': maxAgeRange,
        'genderFeed': 'All',
      });

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const Home()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: _controller
                    .drive(
                      Tween<Alignment>(
                        begin: Alignment.center,
                        end: Alignment.topLeft,
                      ),
                    )
                    .value,
                end: _controller
                    .drive(
                      Tween<Alignment>(
                        begin: Alignment.center,
                        end: Alignment.bottomRight,
                      ),
                    )
                    .value,
                colors: const [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Text(
                        'completeProfile'.tr(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'name'.tr(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _lastNameController,
                        decoration: InputDecoration(
                          labelText: 'lastName'.tr(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: 'username'.tr(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            builder: (BuildContext builder) {
                              final isDark = Theme.of(context).brightness == Brightness.dark;
                              return Container(
                                height: 250,
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(25),
                                  ),
                                ),
                                child: CupertinoDatePicker(
                                  mode: CupertinoDatePickerMode.date,
                                  initialDateTime: _selectedDate ?? DateTime(2005, 1, 1),
                                  minimumDate: DateTime(1900),
                                  maximumDate: DateTime.now(),
                                  onDateTimeChanged: (DateTime newDate) {
                                    setState(() {
                                      _selectedDate = newDate;
                                      _dateController.text =
                                          "${newDate.day}/${newDate.month}/${newDate.year}";
                                    });
                                  },
                                ),
                              );
                            },
                          );
                        },
                        child: AbsorbPointer(
                          absorbing: true,
                          child: TextField(
                            controller: _dateController,
                            decoration: InputDecoration(
                              labelText: 'bornDate'.tr(),
                              filled: true,
                              fillColor: Colors.white,
                              suffixIcon: const Icon(
                                Icons.calendar_today,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            builder: (BuildContext builder) {
                              final isDark = Theme.of(context).brightness == Brightness.dark;
                              return Container(
                                height: 250,
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(25),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Text(
                                        'selectGender'.tr(),
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: CupertinoPicker(
                                        itemExtent: 40,
                                        onSelectedItemChanged: (int index) {
                                          final options = [
                                            'male'.tr(),
                                            'female'.tr(),
                                            'other'.tr(),
                                          ];
                                          setState(() {
                                            _genderController.text =
                                                options[index];
                                          });
                                        },
                                        children: [
                                          Center(
                                            child: Text(
                                              'male'.tr(),
                                              style: TextStyle(
                                                fontSize: 20,
                                                color: isDark ? Colors.white : Colors.black,
                                              ),
                                            ),
                                          ),
                                          Center(
                                            child: Text(
                                              'female'.tr(),
                                              style: TextStyle(
                                                fontSize: 20,
                                                color: isDark ? Colors.white : Colors.black,
                                              ),
                                            ),
                                          ),
                                          Center(
                                            child: Text(
                                              'other'.tr(),
                                              style: TextStyle(
                                                fontSize: 20,
                                                color: isDark ? Colors.white : Colors.black,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                        child: AbsorbPointer(
                          absorbing: true,
                          child: TextField(
                            controller: _genderController,
                            decoration: InputDecoration(
                              labelText: 'gender'.tr(),
                              filled: true,
                              fillColor: Colors.white,
                              suffixIcon: const Icon(
                                Icons.arrow_drop_down,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator()
                              : Text(
                                  'saveProfile'.tr(),
                                  style: const TextStyle(
                                    color: Color(0xFF8E2DE2),
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
