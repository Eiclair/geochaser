import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MapPlayHistory extends StatefulWidget {
  @override
  State<MapPlayHistory> createState() => _MapPlayHistoryState();
}

class _MapPlayHistoryState extends State<MapPlayHistory> {
  GoogleMapController? mapController;

  LatLng _center = const LatLng(35.681236, 139.767125); // 東京駅
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  void initState() {
    super.initState();
    _loadLastPositionAndPath();
  }

  /// 起動時に最後の履歴を読み込み表示
  Future<void> _loadLastPositionAndPath() async {
    final data = await loadHistoryRaw();
    if (data.isEmpty) return;

    final lastKey = data.keys.last;
    _updateMapWithPositions(data[lastKey]!);
  }

  /// ピンと軌跡を更新する共通関数
  void _updateMapWithPositions(List<List<double>> positions) {
    if (positions.isEmpty) return;

    final lastLatLng = LatLng(positions.last[0], positions.last[1]);

    final markers = <Marker>{};
    for (int i = 0; i < positions.length; i++) {
      final pos = positions[i];
      markers.add(
        Marker(
          markerId: MarkerId(pos.toString()),
          position: LatLng(pos[0], pos[1]),
          icon: i == positions.length - 1
              ? BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueRed) // 最後のピンを赤
              : BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueBlue), // 他は青
        ),
      );
    }

    final polyline = Polyline(
      polylineId: const PolylineId('history_path'),
      points: positions.map((p) => LatLng(p[0], p[1])).toList(),
      color: Colors.blue,
      width: 4,
    );

    setState(() {
      _center = lastLatLng;
      _markers = markers;
      _polylines = {polyline};
    });

    // 地図を移動
    mapController?.animateCamera(CameraUpdate.newLatLngZoom(lastLatLng, 13));
  }

  /// 削除確認
  Future<void> _showClearConfirmDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('データを削除しますか？'),
        content: const Text('この操作は取り消せません。'),
        actions: [
          TextButton(
            child: const Text('いいえ'),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: const Text('はい'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (result == true) {
      await clearHistory();
      setState(() {
        _markers.clear();
        _polylines.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('履歴をクリアしました')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('プレイ履歴'),
        leading: const BackButton(), // ←戻るボタン
        actions: [
          IconButton(
            tooltip: "履歴を削除",
            onPressed: () => _showClearConfirmDialog(context),
            icon: const Icon(Icons.restart_alt),
          ),
        ],
      ),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: _center,
          zoom: 11.0,
        ),
        markers: _markers,
        polylines: _polylines,
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.history),
        onPressed: () async {
          await showHistoryDialog(
              context, mapController, _updateMapWithPositions);
        },
      ),
    );
  }
}

/// 履歴データを読み込む
Future<Map<String, List<List<double>>>> loadHistoryRaw() async {
  final prefs = await SharedPreferences.getInstance();
  final keys = prefs.getKeys().toList()..sort((a, b) => a.compareTo(b));

  final Map<String, List<List<double>>> result = {};
  for (final key in keys) {
    final historyStrings = prefs.getStringList(key);
    if (historyStrings != null) {
      final positions = historyStrings.map((e) {
        final parts = e.split(',');
        return [double.parse(parts[0]), double.parse(parts[1])];
      }).toList();
      result[key] = positions;
    }
  }
  return result;
}

/// 履歴一覧ダイアログ
Future<void> showHistoryDialog(
  BuildContext context,
  GoogleMapController? mapController,
  void Function(List<List<double>>) onSelectHistory,
) async {
  final data = await loadHistoryRaw();
  if (data.isEmpty) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('履歴'),
        content: const Text('履歴がありません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
    return;
  }

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('履歴を選択'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: ListView(
          children: data.entries.map((entry) {
            final key = entry.key;
            final positions = entry.value;
            final last = positions.last;
            return ListTile(
              title: Text(key),
              subtitle: Text(
                  "履歴数: ${positions.length} / 最後: (${last[0].toStringAsFixed(4)}, ${last[1].toStringAsFixed(4)})"),
              onTap: () {
                Navigator.of(context).pop(); // ダイアログ閉じる
                onSelectHistory(positions); // 地図更新
              },
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('閉じる'),
        ),
      ],
    ),
  );
}

/// 履歴削除
Future<void> clearHistory() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
}


/*import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MapPlayHistory extends StatefulWidget {
  @override
  State<MapPlayHistory> createState() => _MyAppState();
}

class _MyAppState extends State<MapPlayHistory> {
  String? fdp;
  late GoogleMapController mapController;
  final LatLng _center; // 東京駅の座標
  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  void initState() {
    super.initState();
    _loadFdp(); // 起動時に読み込み
  }

  Future<void> _loadFdp() async {
    final items = await loadHistoryItems();

    // 例: "2025-10-05: (35.68,139.76) -> (35.69,139.77)"
    // のような文字列の最後の座標だけを取りたい場合
    final lastItem = items.last;

    final regex = RegExp(r'\(([-0-9.]+),\s*([-0-9.]+)\)');
    final matches = regex.allMatches(lastItem);
    if (matches.isNotEmpty) {
      final lastMatch = matches.last;
      final lat = double.parse(lastMatch.group(1)!);
      final lng = double.parse(lastMatch.group(2)!);

      setState(() {
        _center = LatLng(lat, lng);
      });
    }

    Widget build(BuildContext context) {
      return MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            actions: [
              IconButton(
                tooltip: "目的地をリセット",
                onPressed: () {
                  /* getHistory(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('履歴をクリアしました')),*/
                  clearHistory();
                },
                icon: const Icon(Icons.restart_alt),
              ),
            ],
          ),
          body: GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _center,
              zoom: 11.0,
            ), // CameraPosition
          ), // GoogleMap
        ), // Scaffold
      ); // MaterialApp
    }
  }
}

class History extends StatelessWidget {
  final List<String> items;

  History({required this.items});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(items[index]),
        );
      },
    );
  }
}

Future<List<String>> loadHistoryItems() async {
  final prefs = await SharedPreferences.getInstance();
  final keys = prefs.getKeys().toList()..sort((a, b) => b.compareTo(a));
  final items = <String>[];
  for (final key in keys) {
    final historyStrings = prefs.getStringList(key);
    if (historyStrings != null) {
      final positions = historyStrings.map((e) => '($e)').join(' -> ');
      items.add('$key: $positions');
    }
  }
  return items.isEmpty ? ['履歴がありません。'] : items;
}

Future<void> showHistoryDialog(BuildContext context) async {
  final items = await loadHistoryItems();
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('履歴'),
      content: SizedBox(
        width: double.maxFinite,
        child: History(items: items),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('閉じる'),
        ),
      ],
    ),
  );
}

void clearHistory() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.clear();
}
*/