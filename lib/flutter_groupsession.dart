library flutter_groupsession;

import 'dart:convert';
import 'package:xml/xml.dart' as xml;
import 'package:http/http.dart' as http;

/// Group Session accessor
class GSessionAccessor {
  /// GroupSession のログインID
  final String _loginId;

  /// GroupSession のパスワード
  final String _pw;

  /// GroupSession 接続URL(http(s):// から必要)
  final String _baseUrl;

  /// アクセストークンヘッダ
  late Map<String, String> _tokenHeader;

  /// GroupSession ID
  late String _sid;

  /// 名前
  late String name;

  /// 所属
  late String belongTo;

  /// コンストラクタ
  GSessionAccessor(String id, pw, url)
      : _loginId = id,
        _pw = pw,
        _baseUrl = url {
    _tokenHeader = {
      'Authorization': "Basic ${base64Encode(utf8.encode("$_loginId:$_pw"))}"
    };
  }

  /// リクエスト送信
  Future<xml.XmlDocument> _request(String url) async {
    final uri = Uri.parse(_baseUrl + url);
    final resp = await http.get(uri, headers: _tokenHeader);
    if (resp.statusCode != 200) {
      throw Exception('${resp.statusCode}');
    }
    return (xml.XmlDocument.parse(resp.body));
  }

  /// ログインしてトークンとユーザ情報を取得します。
  Future<void> login() async {
    var xd = await _request('/api/cmn/login.do');
    final token = xd.getElement('Result')!.getElement('Token')!.text;
    _tokenHeader = {'Authorization': "Bearer $token"};

    xd = await _request('/api/user/whoami.do');
    final rs = xd.getElement('ResultSet');
    final r = rs!.getElement('Result');
    _sid = r!.getElement('Usid')!.text;
    name = "${r.getElement('NameSei')!.text} ${r.getElement('NameMei')!.text}";
    belongTo = r.getElement('Syozoku')!.text;
  }

  /// Dump this class
  String dump() {
    return '名前: $name($_loginId($_sid) <$belongTo>)';
  }

  /// DateTime to YY/MM/DD
  String dateTime2YYMMDD(DateTime dt) {
    return "${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}";
  }

  /// schedule API を使用してスケジュールをロードする
  Future<List<GSEvent>> getEvents(DateTime start, int days) async {
    String from = dateTime2YYMMDD(start);
    String to = dateTime2YYMMDD(start.add(Duration(days: days)));
    final url =
        "/api/schedule/search.do?usid=$_sid&startFrom=$from&startTo=$to";
    final xd = await _request(url);
    return xd
        .findAllElements('Result')
        .map((node) => GSEvent.fromXml(node))
        .toList();
  }

  /// バージョン取得
  Future<String> getVersion() async {
    final xd = await _request('/api/main/version.do');
    return xd.getElement('Result')!.text;
  }

  /// ラベル一覧を取得
  Future<void> getLabelList() async {
    final xd = await _request('/api/user/labellist.do');
    print(xd);
  }

  /// ラベルカテゴリ一覧を取得
  Future<void> getLabelCategoryList() async {
    final xd = await _request('/api/user/labelcategorylist.do');
    print(xd);
  }
}

/// GSEvent は GroupSession のカレンダーイベント1件を表現します。
class GSEvent {
  /// ID
  String? id = "";

  /// 公開区分
  int schKf = 0;

  /// タイトル
  String title = "";

  ///	内容
  String naiyo = "";

  /// 開始日時
  DateTime start;

  /// 終了日時
  DateTime end;

  /// 文字色 1:青 2:赤 3:緑 4:黄 5:黒
  int? color = 1;

  static const Map<int, String> _colorStr = {
    1: '青',
    2: '赤',
    3: '緑',
    4: '黄',
    5: '黒',
  };

  /// Dump
  String dump() {
    return '''
ID($id) $title($start - $end) カラー:${_colorStr[color]}
内容: $naiyo
''';
  }

  /// コンストラクタ
  GSEvent(this.schKf, this.title, this.naiyo, this.start, this.end,
      [this.id, this.color]);

  /// XMLからのコンストラクタ
  GSEvent.fromXml(xml.XmlElement node)
      : id = node.getElement('Schsid')!.text,
        schKf = int.parse(node.getElement('SchEf')!.text),
        title = node.getElement('Title')!.text,
        naiyo = node.getElement('Naiyo')!.text,
        start = DateTime.parse(
            node.getElement('StartDateTime')!.text.replaceAll('/', '-')),
        end = DateTime.parse(
            node.getElement('EndDateTime')!.text.replaceAll('/', '-')),
        color = int.parse(node.getElement('ColorKbn')!.text);
}
