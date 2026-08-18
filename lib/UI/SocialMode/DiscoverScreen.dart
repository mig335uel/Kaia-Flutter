import 'package:flutter/material.dart';
import 'Discover/ForYou.dart';
import 'package:easy_localization/easy_localization.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // TODO: Cambia length a 2 cuando agregues la pestaña de 'Siguiendo'
    _tabController = TabController(length: 1, vsync: this);
    _tabController.addListener(() {
      setState(
        () {},
      ); // Reconstruye la UI para aplicar el gradiente solo al seleccionado
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TabBar(
          controller: _tabController,
          unselectedLabelColor:
              Colors.grey, // Color del texto cuando NO está seleccionado

          tabs: [
            Tab(
              child: _tabController.index == 0
                  ? ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          Color(0xFF6A5BFC),
                          Color(0xFF7575FF),
                          Color(0xFF3FCECC),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ).createShader(bounds),
                      child: Text(
                        "foryou".tr(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    )
                  : Text("foryou".tr()),
            ),
            // Cuando agregues el tab de "Following", harías lo mismo pero verificando _tabController.index == 1
          ],
        ),
      ),
      body: TabBarView(controller: _tabController, children: [Foryou()]),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: 80.0),
        child: FloatingActionButton(
          child: Icon(Icons.add, color: Colors.white),
          backgroundColor: Color(0xFF8E2DE2),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              builder: (context) {
                return Container(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Color(0xFF1F2937)
                      : Colors.white,
                  padding: EdgeInsets.all(10),
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Center(
                      child: Row(
                        children: [
                          TextField(
                            maxLines: null,
                            minLines: null,
                            expands: true,
                            autocorrect: true,
                            keyboardType: TextInputType.text,

                            decoration: InputDecoration(
                              hintText: "whatshappend".tr(),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              hintStyle: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
