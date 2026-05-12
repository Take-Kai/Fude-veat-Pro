# 水導電筆とタブレット端末を用いた書道インタラクションシステム

八戸高専本科5年生〜専攻科2年までの3年間，研究テーマとして取り組みました．

このシステムは，タブレット端末を用いて仮想的に書道表現を行うことができるシステムです．

実際の書道筆に導電加工を施した「水導電筆」とProcessingで構築した書道表現を再現するアルゴリズムを組み合わせ，デジタル上で本物に近い書道体験を実現できます．

背景や研究活動としての発表資料，詳細は[Notionページ](https://wholesale-beginner-8e9.notion.site/veat-Pro-Fude-veat-Pro-347306a87b4980c79177c44f07dcf865)からご覧いただけます．

---

## ⚒️ 開発環境
- **Main System**：Processing（Androidモード）
- **Database**：SQLite
- **Analysis**：Python, OpenCV（筆跡の画像解析） / EZR（統計解析）
- **Hardware**：HUAWEI / Xiaomiタブレット，自作の水導電筆

---

## 📁 主要システムの構造
### 1. 書道表現を再現する筆跡描画アルゴリズム
毛筆特有の掠れや筆跡を再現するため，様々な手法を考案．
- **タッチ検知と筆圧による線の太さ変化**
  - [surfaceTouchEvent.pde](./fude_veatpro_android6/surfaceTouchEvent.pde)
    - タブレット画面へのタッチを検知し，画面に加わった圧力値を取得する．
    - 取得した圧力値は非常に小さく，その変化も微小なため，累乗変換をして筆跡に適用．
- **掠れ線の描画**
  - [Kasure.pde](./fude_veatpro_android6/Kasure.pde)
    - 筆を一定速度以上で描画/墨量が一定量以上減少すると掠れ線へ移行する．
    - 掠れ線は複数の線と点を同時に描画する手法によって再現．
- **永字八法の再現**
  - 永字八法（とめ・はね・はらいなど）を再現するため，4つの図形を組み合わせた「筆跡モデル」を考案．
  - 筆跡モデルは，1.黒線，2.雫型透過画像，3.毛先の広がり線，4.側面補間線により構成．
  - [fude_line.pde](./fude_veatpro_android6/fude_line.pde)
    - 毛先の広がり線の広がり方を筆圧によって制御．他の図形は[scene_play.pde](./fude_veatpro_android6/scene_play.pde)にて制御．
  - [deg_get.pde](./fude_veatpro_android6/deg_get.pde) / [deg_reset.pde](./fude_veatpro_android6/deg_reset.pde)
    - 書道は筆は細かく回転し，その挙動によって筆跡が変化する．
    - 現在の筆の進行方向などを取得し，目標の筆角度になるように筆跡モデルを回転制御．

### 2. 作品データベース管理
- [ConnectToDatabase.pde](./fude_veatpro_android6/ConnectToDatabase.pde) / [DBHelper.pde](./fude_veatpro_android6/DBHelper.pde)
  - SQLiteを用いたデータベースの管理，アクセスの制御．
- [SaveScreenshotToDatabase.pde](./fude_veatpro_android6/SaveScreenshotToDatabase.pde)
  - 描画画面をバイト列（Blob）へ変換しデータベースへ格納．
- [LoadImageFromBytes.pde](./fude_veatpro_android6/LoadImageFromBytes.pde) / [LoadImages.pde](./fude_veatpro_android6/LoadImages.pde)
  - データベースから取り出したバイト列を画像に変換してロード．
- [DisplayGallery.pde](./fude_veatpro_android6/DisplayGallery.pde)
  - ロードした作品をギャラリー画面に表示．
- [SelectImage.pde](./fude_veatpro_android6/SelectImage.pde) / [ShowImageInfo.pde](./fude_veatpro_android6/ShowImageInfo.pde)
  - 表示された任意の作品をタップすると，作品の作成日時・タイトルなどの詳細を表示．
- [DeleteSelectedImage.pde](./fude_veatpro_android6/DeleteSelectedImage.pde) / [RemoveImageFromArray.pde](./fude_veatpro_android6/RemoveImageFromArray.pde)
  - 選択した任意の作品を削除する（画面表示/データベース両方削除）．
- [clearGallery.pde](./fude_veatpro_android6/clearGallery.pde)
  - 他画面に遷移した際に，ギャラリー画面に表示されている作品を画面から削除する．
 
### 3. シーン別の処理
- [fude_veatpro_android6](./fude_veatpro_android6/fude_veatpro_android6.pde)
  - 全てのシーンへの遷移やシステムのメイン動作の処理．
- [display_change.pde](./fude_veatpro_android6/display_change.pde)
  - 他シーンに移る際の待ち時間．
- [scene_title.pde](./fude_veatpro_android6/scene_title.pde) / [scene_play.pde](./fude_veatpro_android6/scene_play.pde) / [scene_help.pde](./fude_veatpro_android6/scene_help.pde) / [scene_gallery.pde](./fude_veatpro_android6/scene_gallery.pde)
  - 各シーン別の処理．特にプレイ画面の制御では，書道特有の筆跡描画に関する記述があります．

### 4. UI制御
- [Button.pde](./fude_veatpro_android6/Button.pde)
  - ボタン変数の宣言とボタンクラスの作成．
- [image.pde](./fude_veatpro_android6/image.pde)
  - 各種ボタン，硯，筆，描画領域，タイトル画面などのイラストの宣言．
- [TextBox.pde](./fude_veatpro_android6/TextBox.pde)
  - テキストボックス変数の宣言とテキストボックスクラスの作成．
- [clearDrawing.pde](./fude_veatpro_android6/clearDrawing.pde)
  - 描画領域のリセット．

 ---

## 📈 客観的な評価
- システム評価のため，高専祭（高専の文化祭）や書道展などに出展しユーザからの意見を集めましたがこれは主観評価であり，研究の評価として客観評価も必要になります．
- そこで，画像処理により掠れ線にフォーカスした客観評価手法を検討しました．
- 本手法により，「なんとなく上手」などといった感覚的な評価だけでなく理想的な掠れの分布を数値で示すことが可能になりました．

### 掠れの定量化アルゴリズム
- [kasure_analysis_test2.py](./kasure_analysis_test/kasure_analysis_test2.py)
  - **濃度勾配の算出**：描画データの輝度値を解析し，黒から白（またはその逆）への色の変化（濃度勾配）を算出．
  - **ヒートマップ可視化**：算出した勾配値により色分けをし，掠れ線画像をヒートマップで可視化．
  - **ヒストグラムでの評価**：算出した濃度勾配をヒストグラムで表示し，掠れの頻度を定量的に提示．

---

## 🖌️ 掠れ表現の改良
- 私が考案してきた掠れ表現の手法は主に，図形の組み合わせによるものでした．
- しかし，その手法にはリアルさを追求すると処理が重くなるというトレードオフが生じたため，新たにPGraphicsによる手法を考えました．
- PGraphicsはProcessingの描画バッファのひとつであり，ピクセル単位で描画を管理できます．
- 以下のプログラムにより新たな掠れ表現手法を考案しました．

### PGraphicsによるピクセルレベルでの掠れ表現手法
- [Kasure_test13.pde](./Kasure_test13/Kasure_test13.pde)
- **各種パラメータ**
  - `holeCount`：ピクセルの抜け数を管理し，掠れの密度を制御．
  - `holeRadius`：抜けるピクセルのまとまりの大きさを制御．
- **接触面積による線の太さ変化の実装**
  - 筆圧による線の太さ変化ではなく，筆と画面の接触面積をパラメータとして採用．
- **検証用スライダーの実装**
  - リアルタイムでパラメータを制御して好みの掠れ具合に調整できるようにするため，スライダーを設置してholeCountとholeRadiusを画面上で制御．

