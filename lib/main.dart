import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './PlayHistory.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Geochaser',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: MyHomePage(title: ''),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, this.title}) : super(key: key);
  final String? title;
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

Future<bool> _ensureLocationPermission() async {
  final serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    await Geolocator.openLocationSettings();
    return false;
  }
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied) return false;
  if (permission == LocationPermission.deniedForever) {
    await Geolocator.openAppSettings();
    return false;
  }
  return true;
}

class _destination {
  final String name;
  final double latitude;
  final double longitude;
  const _destination(
      {required this.name, required this.latitude, required this.longitude});
  _destination copyWith({double? latitude, double? longitude}) => _destination(
        name: name,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
      );
}

class _count {
  final int count;
  const _count({required this.count});
  _count copyWith({int? count}) => _count(
        count: count ?? this.count,
      );
}

class _MyHomePageState extends State<MyHomePage> {
  String _location = "ゲームスタート！\nボタンを押して現在地を取得してください。";
  List<List<double>> _PositionHistory = []; //履歴保存リスト
  // ★ いま選ばれている目的地（nullなら未設定）
  _destination? _currentDestination;

  //何回押したか
  _count? _currentcount;
  //そのがいつ行われたか
  DateTime? _currentDateTime;
  // 目的地リスト
  static const List<_destination> _destinations = [
    _destination(name: "東京タワー", latitude: 35.6585805, longitude: 139.7454329),
    _destination(
        name: "東京スカイツリー", latitude: 35.7100627, longitude: 139.8107004),
    _destination(
        name: "渋谷スクランブル交差点", latitude: 35.6595003, longitude: 139.7004641),
    _destination(name: "新宿駅", latitude: 35.6894875, longitude: 139.6917064),
    _destination(name: "早稲田大学", latitude: 35.712677, longitude: 139.722201),
    _destination(name: "上野公園", latitude: 35.71222, longitude: 139.77111),
    _destination(name: "浅草寺", latitude: 35.714765, longitude: 139.796655),
    _destination(name: "明治神宮", latitude: 35.676397, longitude: 139.699325),
    _destination(name: "皇居", latitude: 35.685175, longitude: 139.752799),
    _destination(name: "六本木ヒルズ", latitude: 35.660516, longitude: 139.729062),
    _destination(name: "お台場", latitude: 35.627222, longitude: 139.776111),
    _destination(name: "代々木公園", latitude: 35.672343, longitude: 139.694932),
    _destination(name: "新国立競技場", latitude: 35.665474, longitude: 139.712372),
    _destination(name: "東京ドーム", latitude: 35.705444, longitude: 139.751596),
    _destination(name: "築地市場", latitude: 35.665498, longitude: 139.770050),
    _destination(name: "銀座", latitude: 35.671733, longitude: 139.764936),
    _destination(name: "秋葉原", latitude: 35.702069, longitude: 139.774474),
    _destination(name: "池袋駅", latitude: 35.728926, longitude: 139.71038),
    _destination(name: "東京都庁", latitude: 35.6895014, longitude: 139.6917337),
    _destination(name: "新国立競技場", latitude: 35.665474, longitude: 139.712372),
    _destination(name: "大阪城", latitude: 34.687315, longitude: 135.526201),
    _destination(name: "京都駅", latitude: 34.985849, longitude: 135.758766),
    _destination(name: "奈良公園", latitude: 34.685087, longitude: 135.843104),
    _destination(name: "神戸ポートタワー", latitude: 34.688056, longitude: 135.195556),
    _destination(name: "広島平和記念公園", latitude: 34.3955, longitude: 132.453333),
    _destination(name: "福岡タワー", latitude: 33.595052, longitude: 130.351807),
    _destination(name: "札幌時計台", latitude: 43.062095, longitude: 141.353292),
    _destination(name: "仙台駅", latitude: 38.268215, longitude: 140.869356),
    _destination(
        name: "横浜ランドマークタワー", latitude: 35.454056, longitude: 139.631944),
    _destination(name: "川崎大師", latitude: 35.560278, longitude: 139.7025),
    _destination(name: "鎌倉大仏", latitude: 35.316667, longitude: 139.533333),
    _destination(name: "箱根神社", latitude: 35.2325, longitude: 139.106111),
    _destination(name: "日光東照宮", latitude: 36.719444, longitude: 139.698333),
    _destination(name: "富士山", latitude: 35.360556, longitude: 138.727778),
    _destination(name: "伊勢神宮", latitude: 34.459167, longitude: 136.724444),
    _destination(name: "熊本城", latitude: 32.803056, longitude: 130.707778),
    _destination(name: "長崎平和公園", latitude: 32.744444, longitude: 129.873611),
    _destination(name: "金沢兼六園", latitude: 36.561389, longitude: 136.656389),
    _destination(name: "高松栗林公園", latitude: 34.3425, longitude: 134.043611),
    _destination(name: "松山城", latitude: 33.839167, longitude: 132.765556),
    _destination(name: "那覇首里城", latitude: 26.217222, longitude: 127.719444),
    _destination(name: "小樽運河", latitude: 43.190833, longitude: 141.0025),
    _destination(name: "函館山", latitude: 41.768611, longitude: 140.728333),
    _destination(name: "富良野", latitude: 43.3425, longitude: 142.384444),
    _destination(name: "旭山動物園", latitude: 43.770833, longitude: 142.364722),
    _destination(name: "知床五湖", latitude: 44.0925, longitude: 145.151111),
    _destination(name: "阿寒湖", latitude: 43.366667, longitude: 144.083333),
    _destination(name: "十和田湖", latitude: 40.416667, longitude: 140.916667),
    _destination(name: "弘前城", latitude: 40.6075, longitude: 140.464444),
    _destination(name: "角館武家屋敷", latitude: 39.718611, longitude: 140.568611),
    _destination(name: "松島", latitude: 38.361111, longitude: 141.030556),
    _destination(name: "蔵王温泉", latitude: 38.121111, longitude: 140.363611),
    _destination(name: "山寺", latitude: 38.256111, longitude: 140.3775),
    _destination(name: "会津若松城", latitude: 37.496389, longitude: 139.929722),
    _destination(name: "草津温泉", latitude: 36.619722, longitude: 138.594444),
    _destination(name: "軽井沢", latitude: 36.343056, longitude: 138.621667),
    _destination(name: "上高地", latitude: 36.239722, longitude: 137.859722),
    _destination(name: "松本城", latitude: 36.238611, longitude: 137.971667),
    _destination(name: "白川郷", latitude: 36.230556, longitude: 136.899722),
    _destination(name: "高山", latitude: 36.140278, longitude: 137.2525),
    _destination(name: "伊勢志摩", latitude: 34.4875, longitude: 136.724167),
    _destination(name: "鳥羽水族館", latitude: 34.481111, longitude: 136.844722),
    _destination(name: "熊野古道", latitude: 33.930278, longitude: 135.9925),
    _destination(name: "高野山", latitude: 34.216667, longitude: 135.583333),
    _destination(name: "姫路城", latitude: 34.839444, longitude: 134.693889),
    _destination(name: "明石海峡大橋", latitude: 34.6175, longitude: 135.021667),
    _destination(name: "淡路島", latitude: 34.3175, longitude: 134.933333),
    _destination(name: "鳴門の渦潮", latitude: 34.305556, longitude: 134.559722),
    _destination(name: "高知城", latitude: 33.559722, longitude: 133.531111),
    _destination(name: "桂浜", latitude: 33.551111, longitude: 133.531667),
    _destination(name: "松山道後温泉", latitude: 33.839167, longitude: 132.765556),
    _destination(name: "宇和島城", latitude: 33.2275, longitude: 132.560278),
    _destination(name: "佐賀城", latitude: 33.263611, longitude: 130.299722),
    _destination(name: "長崎グラバー園", latitude: 32.744722, longitude: 129.873889),
    _destination(name: "ハウステンボス", latitude: 32.964722, longitude: 129.8725),
    _destination(name: "宮島厳島神社", latitude: 34.295556, longitude: 132.319722),
    _destination(name: "尾道", latitude: 34.409167, longitude: 133.193611),
    _destination(name: "倉敷美観地区", latitude: 34.595833, longitude: 133.771667),
    _destination(name: "出雲大社", latitude: 35.393333, longitude: 132.7525),
    _destination(name: "鳥取砂丘", latitude: 35.503611, longitude: 134.241667),
    _destination(name: "金沢21世紀美術館", latitude: 36.561389, longitude: 136.656389),
    _destination(
        name: "富山立山黒部アルペンルート", latitude: 36.578056, longitude: 137.599444),
    _destination(name: "身延山久遠寺", latitude: 35.116667, longitude: 138.45),
    _destination(name: "河口湖", latitude: 35.498611, longitude: 138.793611),
    _destination(
        name: "御殿場プレミアムアウトレット", latitude: 35.279722, longitude: 138.935),
    _destination(name: "熱海温泉", latitude: 35.095556, longitude: 139.071667),
    _destination(name: "伊豆シャボテン公園", latitude: 34.848611, longitude: 138.9325),
    _destination(name: "下田海中水族館", latitude: 34.675, longitude: 138.950556),
    _destination(name: "三保の松原", latitude: 34.975, longitude: 138.499722),
    _destination(name: "浜名湖", latitude: 34.710278, longitude: 137.723611),
    _destination(name: "名古屋城", latitude: 35.185278, longitude: 136.899722),
    _destination(name: "レゴランド・ジャパン", latitude: 35.155, longitude: 136.899722),
    _destination(
        name: "ナガシマスパーランド", latitude: 34.883611, longitude: 136.631111),
    _destination(
        name: "セントレア（中部国際空港）", latitude: 34.858333, longitude: 136.804444),
    _destination(name: "犬山城", latitude: 35.386111, longitude: 136.946389),
    _destination(name: "岐阜城", latitude: 35.423611, longitude: 136.760278),
    _destination(
        name: "白浜アドベンチャーワールド", latitude: 33.7075, longitude: 135.364722),
    _destination(name: "和歌山城", latitude: 34.226111, longitude: 135.1675),
    _destination(name: "京都清水寺", latitude: 34.994856, longitude: 135.785047),
    _destination(name: "伏見稲荷大社", latitude: 34.967139, longitude: 135.772823),
    _destination(name: "嵐山", latitude: 35.009444, longitude: 135.6675),
    _destination(name: "金閣寺", latitude: 35.039444, longitude: 135.729722),
    _destination(name: "銀閣寺", latitude: 35.0275, longitude: 135.798611),
    _destination(name: "祇園", latitude: 35.003611, longitude: 135.778611),
    _destination(name: "天橋立", latitude: 35.450278, longitude: 135.201111),
    _destination(name: "伊根の舟屋", latitude: 35.569722, longitude: 135.330278),
    _destination(name: "舞鶴赤れんがパーク", latitude: 35.4675, longitude: 135.380556),
    _destination(name: "彦根城", latitude: 35.274722, longitude: 136.259722),
    _destination(name: "長浜城", latitude: 35.383611, longitude: 136.264167),
    _destination(name: "福井県立恐竜博物館", latitude: 36.101111, longitude: 136.219722),
    _destination(name: "越前海岸", latitude: 36.123611, longitude: 136.208611),
    _destination(name: "能登半島", latitude: 37.400278, longitude: 137.300556),
    _destination(name: "輪島朝市", latitude: 37.400833, longitude: 137.034167),
    _destination(name: "和倉温泉", latitude: 37.016667, longitude: 137.133333),
    _destination(name: "富山城", latitude: 36.695278, longitude: 137.211111),
    _destination(name: "高岡大仏", latitude: 36.755, longitude: 137.015556),
    _destination(name: "黒部ダム", latitude: 36.578056, longitude: 137.599444),
    _destination(name: '原宿駅', latitude: 35.670205, longitude: 139.702765),
    _destination(name: '表参道ヒルズ', latitude: 35.667236, longitude: 139.706349),
    _destination(name: '国立新美術館', latitude: 35.665337, longitude: 139.726659),
    _destination(name: '東京ミッドタウン', latitude: 35.665498, longitude: 139.730671),
    _destination(name: '上野動物園', latitude: 35.715231, longitude: 139.773007),
    _destination(name: '東京国立博物館', latitude: 35.71883, longitude: 139.776202),
    _destination(name: '浅草花やしき', latitude: 35.717657, longitude: 139.795819),
    _destination(name: '両国国技館', latitude: 35.696887, longitude: 139.793046),
    _destination(name: '東京ドーム', latitude: 35.705639, longitude: 139.751891),
    _destination(name: '後楽園遊園地', latitude: 35.707221, longitude: 139.751624),
    _destination(
        name: '池袋サンシャインシティ', latitude: 35.728926, longitude: 139.717069),
    _destination(name: '代官山蔦屋書店', latitude: 35.648135, longitude: 139.698224),
    _destination(name: '中目黒駅', latitude: 35.644093, longitude: 139.698388),
    _destination(name: '自由が丘駅', latitude: 35.607394, longitude: 139.668604),
    _destination(name: '二子玉川ライズ', latitude: 35.611727, longitude: 139.626999),
    _destination(name: '三軒茶屋駅', latitude: 35.643703, longitude: 139.669582),
    _destination(name: '下北沢駅', latitude: 35.661977, longitude: 139.667273),
    _destination(name: '吉祥寺駅', latitude: 35.703306, longitude: 139.580777),
    _destination(name: '立川駅', latitude: 35.69758, longitude: 139.414574),
    _destination(name: '昭和記念公園', latitude: 35.704291, longitude: 139.404146),
    _destination(name: '葛西臨海公園', latitude: 35.640987, longitude: 139.861553),
    _destination(
        name: '羽田空港第1ターミナル', latitude: 35.549393, longitude: 139.784079),
    _destination(name: '品川駅', latitude: 35.628471, longitude: 139.73876),
    _destination(name: '東京駅', latitude: 35.681236, longitude: 139.767125),
    _destination(name: '神田明神', latitude: 35.703222, longitude: 139.767219),
    _destination(name: '上野アメ横商店街', latitude: 35.708962, longitude: 139.774412),
    _destination(name: '巣鴨地蔵通り商店街', latitude: 35.733373, longitude: 139.738731),
    _destination(name: '王子駅', latitude: 35.752217, longitude: 139.737932),
    _destination(name: '北千住駅', latitude: 35.749431, longitude: 139.804847),
    _destination(name: '錦糸町駅', latitude: 35.697456, longitude: 139.813942),
    _destination(name: '豊洲市場', latitude: 35.642564, longitude: 139.792005),
    _destination(name: '有明アリーナ', latitude: 35.634281, longitude: 139.793812),
    _destination(name: '国立競技場', latitude: 35.678384, longitude: 139.714871),
    _destination(name: '新国立劇場', latitude: 35.683313, longitude: 139.686702),
    _destination(name: '新宿御苑', latitude: 35.685176, longitude: 139.710052),
    _destination(name: '目黒川桜並木', latitude: 35.641536, longitude: 139.700859),
    _destination(name: '東京芸術劇場', latitude: 35.729565, longitude: 139.708939),
    _destination(name: '日比谷公園', latitude: 35.674835, longitude: 139.757731),
    _destination(name: '築地本願寺', latitude: 35.664517, longitude: 139.770363),
    _destination(name: '東京ビッグサイト', latitude: 35.6298, longitude: 139.79757),
    _destination(name: '汐留シオサイト', latitude: 35.664066, longitude: 139.759931),
    _destination(name: '恵比寿駅', latitude: 35.646685, longitude: 139.710037),
    _destination(name: '高円寺駅', latitude: 35.705179, longitude: 139.649295),
    _destination(name: '阿佐ヶ谷駅', latitude: 35.704477, longitude: 139.63598),
    _destination(name: '荻窪駅', latitude: 35.703069, longitude: 139.620856),
    _destination(name: '国分寺駅', latitude: 35.699513, longitude: 139.480147),
    _destination(name: '調布駅', latitude: 35.650704, longitude: 139.540364),
    _destination(name: '府中駅', latitude: 35.673378, longitude: 139.477243),
    _destination(name: '多摩センター駅', latitude: 35.625666, longitude: 139.425341),
    _destination(name: '町田駅', latitude: 35.541297, longitude: 139.445548),
    _destination(name: '高尾山口駅', latitude: 35.63117, longitude: 139.243084),
    _destination(name: '中野駅', latitude: 35.70545, longitude: 139.66573),
    _destination(name: '西荻窪駅', latitude: 35.70318, longitude: 139.59937),
    _destination(name: '吉祥寺パルコ', latitude: 35.70349, longitude: 139.57944),
    _destination(name: '井の頭自然文化園', latitude: 35.69885, longitude: 139.57041),
    _destination(name: '三鷹の森ジブリ美術館', latitude: 35.69613, longitude: 139.57043),
    _destination(name: '練馬駅', latitude: 35.73757, longitude: 139.65412),
    _destination(name: '石神井公園', latitude: 35.73546, longitude: 139.60532),
    _destination(name: '光が丘公園', latitude: 35.75777, longitude: 139.62092),
    _destination(name: '板橋駅', latitude: 35.74573, longitude: 139.71933),
    _destination(name: '赤羽駅', latitude: 35.77713, longitude: 139.72077),
    _destination(name: '王子神社', latitude: 35.75313, longitude: 139.73602),
    _destination(name: '日暮里駅', latitude: 35.72709, longitude: 139.77186),
    _destination(name: '谷中銀座商店街', latitude: 35.72657, longitude: 139.76582),
    _destination(name: '根津神社', latitude: 35.71876, longitude: 139.76286),
    _destination(name: '千駄木駅', latitude: 35.72566, longitude: 139.76351),
    _destination(name: '文京区役所展望ラウンジ', latitude: 35.70702, longitude: 139.75211),
    _destination(name: '神楽坂通り', latitude: 35.70339, longitude: 139.73683),
    _destination(name: '飯田橋駅', latitude: 35.70145, longitude: 139.74553),
    _destination(name: '九段下駅', latitude: 35.69591, longitude: 139.75189),
    _destination(name: '靖国神社', latitude: 35.69404, longitude: 139.74374),
    _destination(name: '竹橋駅', latitude: 35.68882, longitude: 139.75738),
    _destination(name: '霞ヶ関ビルディング', latitude: 35.67266, longitude: 139.75098),
    _destination(name: '赤坂サカス', latitude: 35.67292, longitude: 139.73648),
    _destination(name: '永田町駅', latitude: 35.67641, longitude: 139.74106),
    _destination(name: '虎ノ門ヒルズ', latitude: 35.66663, longitude: 139.74951),
    _destination(name: '浜離宮恩賜庭園', latitude: 35.65912, longitude: 139.76343),
    _destination(name: '新橋駅', latitude: 35.66627, longitude: 139.75892),
    _destination(name: '汐留駅', latitude: 35.66446, longitude: 139.75964),
    _destination(name: '大井競馬場', latitude: 35.58838, longitude: 139.74947),
    _destination(name: '大森駅', latitude: 35.58897, longitude: 139.72852),
    _destination(name: '蒲田駅', latitude: 35.56227, longitude: 139.71634),
    _destination(name: '洗足池公園', latitude: 35.59553, longitude: 139.69112),
    _destination(name: '五反田駅', latitude: 35.62669, longitude: 139.72321),
    _destination(name: '目黒駅', latitude: 35.63382, longitude: 139.71525),
    _destination(name: '白金台駅', latitude: 35.63662, longitude: 139.72547),
    _destination(name: '広尾駅', latitude: 35.65226, longitude: 139.72085),
    _destination(name: '代々木上原駅', latitude: 35.66957, longitude: 139.68009),
    _destination(name: '経堂駅', latitude: 35.65525, longitude: 139.63782),
    _destination(name: '成城学園前駅', latitude: 35.63636, longitude: 139.60666),
    _destination(name: '祖師ヶ谷大蔵駅', latitude: 35.64553, longitude: 139.61314),
    _destination(name: '千歳烏山駅', latitude: 35.66739, longitude: 139.59954),
    _destination(name: '芦花公園', latitude: 35.67358, longitude: 139.61931),
    _destination(name: '蘆花恒春園', latitude: 35.67196, longitude: 139.61381),
    _destination(name: '杉並区立大田黒公園', latitude: 35.70599, longitude: 139.62672),
    _destination(name: '井草八幡宮', latitude: 35.72325, longitude: 139.59812),
    _destination(name: '練馬区立美術館', latitude: 35.73846, longitude: 139.64857),
    _destination(
        name: 'としまえん跡地（ハリポタスタジオツアー東京）',
        latitude: 35.74229,
        longitude: 139.65219),
    _destination(name: '江戸東京たてもの園', latitude: 35.72056, longitude: 139.49563),
    _destination(name: '小金井公園', latitude: 35.71059, longitude: 139.50957),
    _destination(name: '多摩動物公園', latitude: 35.66117, longitude: 139.40554),
    _destination(name: '国立天文台三鷹', latitude: 35.67556, longitude: 139.54062),
    _destination(name: '狛江駅', latitude: 35.63349, longitude: 139.57819),
    _destination(name: '稲城市立中央公園', latitude: 35.63678, longitude: 139.50743),
  ];

  // リセットボタンで目的地をクリア
  void _resetDestination() {
    setState(() {
      _currentDestination = null;
      _currentcount = null;
      _currentDateTime = null;
      _location = "目的地をリセットしました。ボタンで再取得してください。";
      _PositionHistory = [];
    });
  }

  Future<void> getLocation() async {
    try {
      final ok = await _ensureLocationPermission();
      if (!ok) {
        setState(() => _location = "位置情報が許可されていません。設定から許可してください。");
        return;
      }

      // 現在地取得
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      // 目的地が未設定なら抽選ロジックを実行
      if (_currentDestination == null) {
        final destination = (_destinations.toList()..shuffle()).first;
        final distanceInMeters = Geolocator.distanceBetween(
          destination.latitude,
          destination.longitude,
          position.latitude,
          position.longitude,
        );

        if (distanceInMeters > 1000 || distanceInMeters < 50) {
          // 1km超もしくは50m以内なら再抽選（再帰）
          await getLocation();
          return;
        } else {
          _currentDestination = destination; // ← 確定
          setState(() {
            _location = //"目的地: ${destination.name}\n"
                "回数: 1\n"
                //"現在地: (${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)})\n"
                // "${_currentDateTime.toString()}\n"
                "直線距離: ${distanceInMeters.toStringAsFixed(0)} m";
            _currentcount = _count(count: 1);
            _currentDateTime = DateTime.now();
            _PositionHistory.add([position.latitude, position.longitude]);
          });
          return;
        }
      }
      if (_currentcount == null) {
        _currentcount = _count(count: 2);
      } else {
        _currentcount =
            _currentcount!.copyWith(count: _currentcount!.count + 1);
      }
      final ph = _PositionHistory;
      ph.add([position.latitude, position.longitude]);
      _PositionHistory = ph;
      // 目的地が既にある場合は、目的地はそのままに距離だけ更新
      final d = Geolocator.distanceBetween(
        _currentDestination!.latitude,
        _currentDestination!.longitude,
        position.latitude,
        position.longitude,
      );
      if (d < 50) {
        setState(() {
          _PositionHistory.add([position.latitude, position.longitude]);
        });
        // 到着したら履歴を保存
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        final key = _currentDateTime?.toIso8601String() ??
            DateTime.now().toIso8601String();

        final historyStrings =
            _PositionHistory.map((e) => '${e[0]},${e[1]}').toList();
        await prefs.setStringList(key, historyStrings);

        setState(() {
          _location =
              "おめでとうございます！目的地「${_currentDestination!.name}」に${_currentcount!.count}回で到着しました！";
          _currentDestination = null; // 到着したらリセット
          _currentcount = null;
          _currentDateTime = null;
          _PositionHistory = [];
        });
        return;
      }
      setState(() {
        _location = //"目的地: ${_currentDestination!.name}\n"
            "回数: ${_currentcount!.count}\n"
            //"現在地: (${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)})\n"
            //"${_currentDateTime.toString()}\n"
            // "${_PositionHistory.toString()}\n"
            "直線距離: ${d.toStringAsFixed(0)} m";
      });
    } on PermissionDeniedException {
      setState(() => _location = "権限が拒否されました。設定から位置情報を許可してください。");
    } on LocationServiceDisabledException {
      setState(() => _location = "端末の位置サービスがOFFです。ONにして再試行してください。");
    } catch (e) {
      setState(() => _location = "取得に失敗しました: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? ""),
        actions: [
          IconButton(
            tooltip: "目的地をリセット",
            onPressed: _resetDestination,
            icon: const Icon(Icons.restart_alt),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding:
              const EdgeInsets.only(top: 10, right: 40, bottom: 400, left: 40),
          child: Text(
            _location,
            textAlign: TextAlign.center,
            style: TextStyle(/*fontFamily: 'Zen_Maru_Gothic',*/ fontSize: 32),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // リセット（小）
          FloatingActionButton.small(
            heroTag: null,
            tooltip: "目的地リセット",
            onPressed: _resetDestination,
            child: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 16),
          // 距離を測定（既存の抽選ロジックは未設定時のみ実行）
          FloatingActionButton.large(
            heroTag: null,
            tooltip: "距離を測る",
            onPressed: getLocation,
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            child: const Icon(Icons.navigation),
          ),
          const SizedBox(width: 8),
          FloatingActionButton.small(
            heroTag: null,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => MapPlayHistory()),
            ),
            child: const Icon(Icons.history),
          ),
        ],
      ),
    );
  }
}
