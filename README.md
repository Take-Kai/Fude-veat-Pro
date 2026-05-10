# 水導電筆とタブレット端末を用いた書道インタラクションシステム

八戸高専本科5年生〜専攻科2年までの3年間，研究テーマとして取り組みました．

このシステムは、タブレット端末を用いて仮想的に書道表現を行うことができるシステムです．

実際の書道筆に導電加工を施した「水導電筆」とProcessingで構築した書道表現を再現するアルゴリズムを組み合わせ，デジタル上で本物に近い書道体験を実現できます．

背景や研究活動としての発表資料，詳細は[Notionページ](https://wholesale-beginner-8e9.notion.site/veat-Pro-Fude-veat-Pro-347306a87b4980c79177c44f07dcf865)からご覧いただけます．

---

## ⚒️ 開発環境
- **Main System**：Processing（Androidモード）
- **Database**：SQLite
- **Analysis**：Python, OpenCV（筆跡の画像解析） / EZR（統計解析）
- **Hardware**：HUAWEI / Xiaomiタブレット，自作の水導電筆

** 📁 主要システムの構造
### 1. 書道表現を再現する筆跡描画アルゴリズム
毛筆特有の掠れや筆跡を再現するため，様々な手法を考案．
- **タッチ検知と筆圧による線の太さ変化**
  - [surfaceTouchEvent.pde]
    - タブレット画面へのタッチを検知し，画面に加わった圧力値を取得する．
    - 取得した圧力値は非常に小さく，その変化も微小なため，累乗変換をして筆跡描画の適用．
- **掠れ線の描画**
  - [Kasure.pde]
    - 筆を一定速度以上で描画/墨量が一定量以上減少すると掠れ線へ移行する．
    - 掠れ線は複数の線と点を同時に描画する手法によって再現．
- **永字八法の再現**
  - 永字八法を再現するため，4つの図形を組み合わせた「筆跡モデル」を考案．
  - 筆跡モデルは，1.黒線，2.雫型透過画像，3.毛先の広がり線，4.側面補間線により構成．
  - [fude_line.pde]
    - 毛先の広がり線の広がり方を筆圧によって制御．他の図形は[scene_play.pde]にて制御．
  - [deg_get.pde] / [deg_reset.pde]
    - 書道は筆は細かく回転し，その挙動によって筆跡が変化する．
    - 現在の筆の進行方向などを取得し，目標の筆角度になるように筆跡モデルを回転制御．

### 2. 作品データベース管理
- [ConnectToDatabase.pde] / [DBHelper.pde]
  - SQLiteを用いたデータベースの管理，アクセスの制御．
- [saveScreenshotToDatabase.pde]
  - 描画画面をバイト列（Blob）へ変換しデータベースへ格納．
- [LoadImageFromBytes.pde] / [LoadImages.pde]
  - データベースから取り出したバイト列を画像に変換してロード．
- [DisplayGallery.pde]
  - ロードした作品をギャラリー画面に表示．
- [SelectImage.pde] / [ShowImageInfo.pde]
  - 表示された任意の作品をタップすると，作品の作成日時・タイトルなどの詳細を表示．
- [DeleteSelectedImage.pde] / [RemoveImageFromArray.pde]
  - 選択した任意の作品を削除する（画面表示/データベース両方削除）．
- [clearGallery.pde]
  - 他画面に遷移した際に，ギャラリー画面に表示されている作品を画面から削除する．
 
### 3. シーン別の処理
- [fude_veatpro_android6]
  - 全てのシーンへの遷移やシステムのメイン動作の処理．
- [display_change.pde]
  - 他シーンに映る際の待ち時間．
- [scene_title.pde] / [scene_play.pde] / [scene_help.pde] / [scene_gallery.pde]
  - 各シーン別の処理．特にプレイ画面の制御では，書道特有の筆跡描画に関する記述があります．

### 4. UI制御
- [Button.pde]
  - ボタン変数の宣言とボタンクラスの作成．
- [Image.pde]
  - 各種ボタン，硯，筆，描画領域，タイトル画面などのイラストの宣言．
- [TextBox.pde]
  - テキストボックス変数の宣言とテキストボックスクラスの作成．
- [clearDrawing.pde]
  - 描画領域のリセット．
