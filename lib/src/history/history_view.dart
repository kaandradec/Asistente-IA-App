import 'package:flutter/material.dart';
import 'package:al_ia/src/home/home_view.dart';
import 'package:al_ia/src/settings/settings_controller.dart';
import 'package:al_ia/util/common.dart';

class HistoryView extends StatefulWidget {
  final SettingsController controller;
  static const routeName = '/history';
  const HistoryView({Key? key, required this.controller}) : super(key: key);
  @override
  HistoryViewState createState() => HistoryViewState();
}

class HistoryViewState extends State<HistoryView> {
  List<Map> history = [];

  @override
  void initState() {
    history = widget.controller.appHistory;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial'),
        actions: [
          widget.controller.appHistory.isNotEmpty
              ? IconButton(
                onPressed: () {
                  widget.controller.clearAppHistory();
                  history.clear();
                  showAlert(
                    context,
                    "Has eliminado tu historial satisfactoriamente.",
                  );
                  setState(() {});
                },
                icon: const Icon(Icons.delete_sweep),
              )
              : const SizedBox(),
        ],
      ),
      body:
          history.isNotEmpty
              ? ListView.builder(
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final item = history[index];
                  return Dismissible(
                    key: Key(item['query']),
                    direction: DismissDirection.endToStart,
                    onDismissed: (direction) async {
                      history.removeAt(index);
                      await widget.controller.updateAppHistory([...history]);
                      // ignore: use_build_context_synchronously
                      showAlert(
                        context,
                        "Has eliminado tu historial satisfactoriamente.",
                      );
                      setState(() {});
                    },
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      child: const Padding(
                        padding: EdgeInsets.only(right: 20),
                        child: Icon(Icons.delete, color: Colors.white70),
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 4.0,
                        horizontal: 15.0,
                      ),
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['query'],
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Opacity(
                            opacity: 0.6,
                            child: Text(
                              item['time'],
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        // logger.i(item);
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            settings: const RouteSettings(name: '/'),
                            builder:
                                (context) => HomeView(
                                  controller: widget.controller,
                                  query: item['query'],
                                ),
                          ),
                        );
                      },
                    ),
                  );
                },
              )
              : const SizedBox.expand(
                child: Padding(
                  padding: EdgeInsets.all(15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Nada que mostrar",
                        style: TextStyle(fontSize: 18.0),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 4),
                      Opacity(
                        opacity: 0.6,
                        child: Text(
                          "Verás tu historial aquí cuando esté disponible",
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
