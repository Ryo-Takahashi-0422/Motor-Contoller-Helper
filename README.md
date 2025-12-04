# Motor-Controller-Helper

現在制作中のFlutterアプリです。

## システム概要

- 本アプリ（Motor Controller Helper）とマイコンを Bluetooth(HC-05) でハンドシェイクし UART 通信
  ファームウェアは以下を参照ください。
  https://github.com/Ryo-Takahashi-0422/Motor-Contoller
- マイコンは EEPROM(24LC64)、Bluetooth(HC-05)、モータードライバ(L298N) と接続
- モータードライバ(L298N) は DC ギアモータ (25GA370) に接続

## 2025/12/4 時点

### 実装済の主な機能

- スマホアプリ・マイコン間のハンドシェイクと UART 相互通信
- アプリ → マイコン：コマンド送信（コマンド名＋EEPROMアドレス、デリミタ "\r\n"）
- マイコン：関数ポインタを使ったコマンド受付・検索・実行
- マイコン ↔ EEPROM の I2C 通信、読み書き
- スマホのスライドバー（0〜100）→ デューティ比計算 → PWM（MTU 書き込み）でモータ制御

## 今後実装予定の機能

1. スマホアプリで波形生成
    - 例：モータ速度を 10ms 間隔で 100 サンプル取得 → rpm に変換 → アプリ送信 → 波形描画
2. PID モデル構築（オシロ使用）
3. PID を用いた速度制御・位置制御
4. スマホで PID 値入力 → マイコンへ反映

## 開発環境

- Android Studio

## 動作環境

- OS : Xiaomi HyperOS(1.0.13.0.UGTMIXM) (ベースはAndroid14)
- 端末 : REDMI 14C