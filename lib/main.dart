import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';

// 全体構造
//__________________________________________________________________________________________________
// main()
//  └── runApp(MyApp)
//        └── MaterialApp
//              └── home: BluetoothHomePage()
//                    ├── createState()
//                    ├── initState()
//                    │    ├── requestBluetoothPermissions()
//                    │    └── _initBluetooth()
//                    ├── build()
//                    │    └── ListView → ListTile (各Bluetoothデバイス)
//                    │         └── onTap()（デバイスタップ）
//                    │              └── Navigator.push()
//                    │                    └── BluetoothChatPage(device)
//                    │                          ├── createState()
//                    │                          ├── initState()
//                    │                          │    └── _connectToDevice()
//                    │                          │          └── BluetoothConnection.toAddress(...)
//                    │                          │              └── 接続成功で入力ストリーム監視開始
//                    │                          └── build()
//                    │                                ├── メッセージ一覧表示
//                    │                                └── 入力欄 + 送信ボタン
//__________________________________________________________________________________________________

// main()	アプリ開始点
// runApp(MyApp)	アプリのルートウィジェットを実行
// MyApp.build()	MaterialApp（アプリ構成）を返す
// BluetoothHomePage	最初に表示される画面
// initState()	初期化処理：Bluetooth設定など
// build()	実際のUIを描く処理（ListViewなど）

// build() はいつ呼ばれる？
// 最初に runApp() → build()
// setState() されたとき（StatefulWidget の場合）
// Key が変わったとき
// 外的要因（画面回転など）でリビルドされるとき

// ステップ1: main() 関数
void main() {
  // ウィジェット（= アプリ全体のルート）を画面に表示する指示
  // MyApp インスタンス作成（const MyApp()）
  // Flutterがその build() を呼び出す
  // MaterialApp(...) が返される → アプリの中身がスタート
  runApp(const MyApp());
}

// ステップ2: MyApp ウィジェット
// StatelessWidget → 状態を持たない静的な構成
// MaterialApp を返している → Flutterアプリの基本構造（テーマ、ルーティング、ページ管理など）
// この中の home に設定された BluetoothHomePage() が最初の画面になる
class MyApp extends StatelessWidget {
  // const コンストラクタ（定数としてインスタンス化できる）
  // const は 「このウィジェットは不変（immutable）で再利用可能」 という意味。
  // super.key は、親クラス（StatelessWidget）の key パラメータを渡している
  // MyApp を const MyApp() のように使えるようにする

  // super.key って何？どんな値？
  // Flutter内部で ウィジェットの同一性を判定するための識別子。再描画や状態の保持の際に使われる。
  // デフォルトでは null、必要に応じて自分で Key() を渡すこともできる。

  // Flutterの「比較と再利用」の仕組み
  // Flutterの画面は再描画のたびに Widgetツリーを再構築する。そのとき、
  // key が同じ → 「同じウィジェット」として扱い、状態を保ったまま再描画できる
  // key が違う or 無し → 「別のウィジェット」として扱い、新規インスタンスとして初期化される

  // 今回は StatelessWidget なのでどうでもいい？
  // 基本的には Yes
  // StatelessWidget は状態を持たないため、毎回作り直しても影響は小さい
  // パフォーマンス最適化として key をつけるケースもありますが、無くても問題なし
  // StatefulWidget の場合は重要
  // ListView(
  //   children: [
  //     MyItemWidget(key: Key("item1")),
  //     MyItemWidget(key: Key("item2")),
  //   ],
  // );
  // このように key を付けておかないと、リストの順序が変わったときに Flutterが前の状態を再利用できず、バグやちらつきが発生することがある
  const MyApp({super.key});

  // MaterialAppはFlutterが提供するマテリアルデザイン（AndroidライクなUI）用のアプリ全体の枠組みウィジェット。
  // title: 'Bluetooth Classic'はアプリの名前
  // Androidのタスク一覧や、Webアプリの <title> 的な表示に使われます（表示されないことも多い）
  // home: BluetoothHomePage()
  // アプリを起動したときに最初に表示する画面を指定している。
  // BluetoothHomePage はユーザーが最初に見る画面（ペアリング済みデバイスの一覧）
  // なぜconstがついているか → パフォーマンス最適化
  // MaterialApp は引数がすべて const 扱い可能なので、Flutterがこのウィジェットを再生成せず再利用できる。
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Bluetooth Classic',
      home: BluetoothHomePage(), // コンストラクタ呼び出し→インスタンス生成
    );
  }
}

// StatefulWidget は「状態を持つことができる画面部品」。
// Flutter では、ユーザー操作やデータ変更などで UI を動的に変化させるには、StatefulWidget が必要
// 例えるなら（C#/WPF経験者向け）
// StatelessWidget ＝ 常に同じ内容の UserControl（プロパティや状態を持たない）
// StatefulWidget ＝ 状態（ViewModelや内部フィールド）を持ち、動的に変わる UserControl
// BluetoothHomePage は 外枠。再利用される「定義」的なもの。
// createState() で返す State クラスが 中身の本体。ここに状態や処理を書く。
// なぜ分離されているのか？
// Flutterでは、UIの描画効率を最大化するために、
// **Widget（外枠）**は不変（immutable）
// **State（中身）**だけを更新して描画を最小限に抑える

// ステップ3: BluetoothHomePage ウィジェットの表示
// BluetoothHomePage インスタンスを生成
// createState() を呼び出して _BluetoothHomePageState を作成
// initState() を自動的に実行 ← 🔧 初期化処理（Bluetoothなど）
// build() を呼び出して画面構築 ← 🎨 画面の見た目を作る
class BluetoothHomePage extends StatefulWidget {
  const BluetoothHomePage({super.key});

  // BluetoothHomePage() の コンストラクタが呼ばれる
  // Flutterが createState() を自動で呼び出す
  // createState() が返す BluetoothHomePageState（= _BluetoothHomePageState）を作成
  // その State インスタンスの initState() → build() が呼ばれる
  // 処理のイメージ
  // BluetoothHomePage widget = BluetoothHomePage();
  // BluetoothHomePageState state = widget.createState();
  // state.initState();
  // state.build(context);
  // Dart の 「短縮関数（arrow syntax）=> ラムダではない」 で書かれた 通常のメソッド定義 =
  // @override
  // State<BluetoothHomePage> createState() {
  //   return _BluetoothHomePageState();
  // }
  @override
  State<BluetoothHomePage> createState() => _BluetoothHomePageState();
}

class _BluetoothHomePageState extends State<BluetoothHomePage> {
  List<BluetoothDevice> _devices = [];

  // List<Permission> と推論できるので、候補が明確になる
  // Permission.bluetoothなどが出ない理由
  // Permission は「アプリが使いたい機能の権限（パーミッション）」の種類を表す。
  // ここでは、Bluetooth関連の3つのパーミッションと、位置情報（ロケーション）をリクエストしている。
  // .request() はユーザーに許可を求めるメソッドで、**許可の結果を受け取るまで待つ（await）**ことを意味する。
  // 結果は、各パーミッションが許可されたかどうかを表す Map （辞書型）で返ってくる。
  // ユーザーの操作を待つためrequest() メソッドは非同期（Future）
  // ユーザーに「このアプリに Bluetooth や位置情報の使用を許可しますか？」というダイアログを表示する。
  // ユーザーが「許可」または「拒否」をタップするまで待つ。
  // 全てのパーミッションの結果を Map<Permission, PermissionStatus> として取得する
  Future<void> requestBluetoothPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location, // ロケーションも要求（安全のため）
    ].request();

    if (statuses[Permission.bluetoothConnect] != PermissionStatus.granted ||
        statuses[Permission.bluetoothScan] != PermissionStatus.granted) {
      // パーミッションが拒否された場合の処理
      print("❌ 必要なパーミッションが拒否されました");
    } else {
      print("✅ パーミッションOK");
    }
  }

  // ステップ4: initState() の中で初期処理
  // Bluetoothの使用許可をユーザーにリクエスト
  // ペアリング済みのデバイス一覧を取得
  // 画面を更新（setState()）してデバイスをリスト表示
  @override
  void initState() {
    super.initState();
    requestBluetoothPermissions();
    _initBluetooth();
  }

  Future<void> _initBluetooth() async {
    // Bluetooth ON 要求
    await FlutterBluetoothSerial.instance.requestEnable();

    // ペアリング済みデバイス取得
    List<BluetoothDevice> devices =
    await FlutterBluetoothSerial.instance.getBondedDevices();

    setState(() {
      _devices = devices;
    });
  }

  // ステップ5: build() で画面構築
  // ListView(...)　スクロールできるリストビュー
  // children:　中に並べたいウィジェットのリスト
  // _devices は Bluetoothデバイスのリスト（List<BluetoothDevice>など）
  // .map((device) => ...) は Dart のリストの関数で、リストの中身を一つずつ別の形（ウィジェットなど）に変換する
  // .toList() は IterableからListに変換する（children は List型を期待するため）
  @override
  Widget build(BuildContext context) {
    return Scaffold( // ←画面の骨組み（AppBar付き）
      appBar: AppBar(title: const Text("Bluetooth Devices")), // ←上のタイトルバー
      body: ListView( // ←デバイス一覧を縦に並べて表示
        children: _devices.map((device) {
          return ListTile(
            title: Text(device.name ?? "Unknown"),
            subtitle: Text(device.address),
            onTap: () {
              Navigator.push( // ←デバイスをタップしたら別画面へ遷移
                context,
                MaterialPageRoute(
                  builder: (_) => BluetoothChatPage(device: device),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}

class SpeedSliderWithSendButton extends StatefulWidget {
  final void Function(double value) onSend;

  const SpeedSliderWithSendButton({super.key, required this.onSend});

  @override
  State<SpeedSliderWithSendButton> createState() => _SpeedSliderWithSendButtonState();
}

class _SpeedSliderWithSendButtonState extends State<SpeedSliderWithSendButton> {
  double _value = 0;
  bool _canSend = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text("速度: ${_value.round()}"),
        Slider(
          value: _value,
          min: 0,
          max: 100,
          divisions: 100,
          label: _value.round().toString(),
          onChanged: (double newValue) {
            setState(() {
              _value = newValue;
            });
          },
        ),
        ElevatedButton(
          onPressed: _canSend
              ? () {
            widget.onSend(_value); // 送信処理を呼び出す

            setState(() {
              _canSend = false; // 一時的にボタン無効
            });

            Future.delayed(const Duration(milliseconds: 1000), () {
              if (mounted) {
                setState(() {
                  _canSend = true; // 0.5秒後に再び有効
                });
              }
            });
          }
              : null, // 無効状態（グレーアウト）
          child: const Text("送信"),
        ),
      ],
    );
  }
}


// BluetoothChatPage は BluetoothHomePageでデバイスを選択したあとに遷移する「通信画面」
// つまり、アプリの第2の画面として main() からの流れに続く重要な一部
class BluetoothChatPage extends StatefulWidget {
  final BluetoothDevice device;

  // ステップ1. 遷移時に受け取るもの→選ばれた Bluetooth デバイス（BluetoothDevice）の情報を受け取る
  const BluetoothChatPage({super.key, required this.device});

  @override
  State<BluetoothChatPage> createState() => _BluetoothChatPageState();


}

class _BluetoothChatPageState extends State<BluetoothChatPage> {
  BluetoothConnection? _connection;
  bool _isConnecting = true;
  bool _isConnected = false;
  TextEditingController _textController = TextEditingController();
  List<String> _messages = [];
  double _value = 0;

  // ステップ2. 初期処理（initState()）
  // ウィジェットが「画面に追加された直後」に呼ばれる。
  // 通常、初期化処理（非同期処理、イベントリスナー登録など）をここでやる。
  // 毎フレーム呼ばれるわけではなく、一度だけ呼ばれる。
  @override
  void initState() {
    super.initState();
    // Bluetooth接続処理を開始
    _connectToDevice();
  }

  // 接続処理
  Future<void> _connectToDevice() async {
    try {
      // ステップ3. Bluetoothに接続（非同期）
      // 指定されたアドレスにBluetoothで接続
      // 成功したら _connection.input.listen(...) で受信を監視開始
      BluetoothConnection connection =
      await BluetoothConnection.toAddress(widget.device.address);
      setState(() {
        _connection = connection;
        _isConnecting = false;
        _isConnected = true;
      });

      // ステップ4. メッセージ受信処理（listen）
      // データを受け取るたびに ListView に表示される（setState()）
      // _connection!.input?.listen((Uint8List data) {
      //   final incomingText = utf8.decode(data);
      //   setState(() {
      //     _messages.add("受信: $incomingText");
      //   });
      // }).onDone(() {
      //   setState(() {
      //     _isConnected = false;
      //   });
      // });

      String _buffer = "";

      // listen(...) は Dart の ストリーム（Stream） に対する処理。一度だけ登録している。
      // ストリーム は「非同期に何回も値を届ける」もの
      // たとえば Bluetooth、WebSocket、センサー、タイマーなどがデータをストリームで送ってくる
      // .listen(...) は「新しいデータが来たらこの関数を実行する」と登録するメソッド
      // _connection は null ではないと仮定し、その input が存在すれば（nullでなければ：null安全）.listen(...) を呼び出す
      // _connection!.input?.listen((Uint8List data) {
      //   final incomingText = utf8.decode(data);
      //   _buffer += incomingText;
      //
      //   // 区切り文字（ここでは \n）で分割する
      //   while (_buffer.contains("\n")) {
      //     final index = _buffer.indexOf("\n");
      //     final completeMessage = _buffer.substring(0, index);
      //     _buffer = _buffer.substring(index + 1); // 残りのバッファを保存
      //     setState(() {
      //       _messages.add("受信: $completeMessage");
      //     });
      //   }
      // });
      _connection!.input?.listen((Uint8List data) {
        final incomingText = utf8.decode(data);
        _buffer += incomingText;

        while (_buffer.contains("\n")) {
          final index = _buffer.indexOf("\n");
          final completeMessage = _buffer.substring(0, index);
          _buffer = _buffer.substring(index + 1);

          setState(() {
            _messages.add("受信: $completeMessage");
          });

          // 少し遅らせてスクロール（build 完了後にスクロール）
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        }
      });


    } catch (e) {
      print('接続エラー: $e');
      setState(() {
        _isConnecting = false;
        _isConnected = false;
      });
    }
  }

  final ScrollController _scrollController = ScrollController();

  // // ステップ5. メッセージ送信処理
  // void _sendMessage(String text) {
  //   if (_connection != null && _isConnected) {
  //     // ステップ5. メッセージ送信処理
  //     _connection!.output.add(Uint8List.fromList(utf8.encode("$text\r\n")));
  //     setState(() {
  //       _messages.add("送信: $text");
  //     });
  //     _textController.clear();
  //   }
  // }
  void _sendMessage(String text) {
    if (_connection != null && _isConnected) {
      _connection!.output.add(Uint8List.fromList(utf8.encode("$text\r\n")));
      setState(() {
        _messages.add("送信: $text");
      });
      _textController.clear();

      // メッセージ追加後にスクロール
      // Future.delayed(Duration(milliseconds: 100), () {
      //   if (_scrollController.hasClients) {
      //     _scrollController.animateTo(
      //       _scrollController.position.maxScrollExtent,
      //       duration: Duration(milliseconds: 300),
      //       curve: Curves.easeOut,
      //     );
      //   }
      // });
    }
  }

  // 画面を閉じたとき自動で呼ばれる
  @override
  void dispose() {
    _connection?.dispose();
    _connection = null;
    super.dispose();
  }

  // ステップ6. 画面構築（build()）
  // 接続中 → ローディング表示
  // 接続済み → メッセージ一覧 + 送信欄
  // 接続失敗 → エラーメッセージ表示

  @override
  Widget build(BuildContext context) {
    final deviceName = widget.device.name ?? "Unknown";

    return Scaffold(
      appBar: AppBar(
        title: Text("通信中: $deviceName"),
      ),
      body: Column(
        children: [
          if (_isConnecting)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            )
          else if (!_isConnected)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text("接続できませんでした"),
            )
          else
            Expanded(
              // flex: 3,
              // child: ListView(
              //   children:
              //   _messages.map((msg) => ListTile(title: Text(msg))).toList(),
              // ),
              flex: 3,
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return ListTile(title: Text(_messages[index]));
                },
              )
            ),
            Expanded(
              flex: 1,
              // child: Slider(
              //   value: _value,
              //   min: 0,
              //   max: 100,
              //   divisions: 100,
              //   label: _value.round().toString(),
              //   onChanged: (double newValue) {
              //     setState(() {
              //       _value = newValue;
              //     });
              //   },
              // ),
              child: SpeedSliderWithSendButton(
                onSend: (value) {
                  if (_isConnected && _connection != null) {
                    _connection!.output.add(
                      Uint8List.fromList(utf8.encode("${value.round()}\r\n")),
                    );
                    setState(() {
                      _messages.add("速度送信: ${value.round()}");
                    });
                  }
                },
              ),
            ),
          if (_isConnected)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(controller: _textController),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () {
                      if (_textController.text.trim().isNotEmpty) {
                        _sendMessage(_textController.text.trim());
                      }
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
