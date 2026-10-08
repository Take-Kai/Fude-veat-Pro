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
- **Font**：YujiSyuku（SIL Open Font License）

---

## 📁 主要システムの構造
現在のメインシステムは[fude_veatpro_android8](./fude_veatpro_android8/)です．以前の版は[fude_veatpro_android6](./fude_veatpro_android6/)に残しています（android6からの変更点は[下記](#-android6からの変更点)）．

### 1. 書道表現を再現する筆跡描画アルゴリズム
毛筆特有の掠れや筆跡を再現するため，様々な手法を考案．
- **タッチ検知と筆圧による線の太さ変化**
  - [surfaceTouchEvent.pde](./fude_veatpro_android8/surfaceTouchEvent.pde)
    - タブレット画面へのタッチを検知し，画面に加わった圧力値を取得する．
    - 取得した圧力値は非常に小さく，その変化も微小なため，累乗変換をして筆跡に適用．
- **掠れ線の描画**
  - 掠れ線にするかの判定は[scene_play.pde](./fude_veatpro_android8/scene_play.pde)で行う．筆を一定速度以上で描画/墨量が一定量以上減少すると掠れ線へ移行する．
  - [KasureBrush.pde](./fude_veatpro_android8/KasureBrush.pde)
    - 筆が通った範囲のピクセルを1つずつ判定し，毛に残っている墨の量が「紙の凹凸」+「毛1本ごとのムラ」より多い時だけ墨を付ける（[Kasure_test16](#ピクセル単位で墨の付き方を判定する掠れ表現)の方式）．
    - 掠れの強さと毛の粗さは，墨残量メーターの減り方から自動で決める．
    - 輪郭ははっきり残したまま内側に白い筋が出て，墨が減るほど毛の跡だけが残るようになる．
  - [Kasure.pde](./fude_veatpro_android8/Kasure.pde)
    - 以前の方式（複数の線と点を同時に描画する手法）．現在は使っていない．
- **永字八法の再現**
  - 永字八法（とめ・はね・はらいなど）を再現するため，4つの図形を組み合わせた「筆跡モデル」を考案．
  - 筆跡モデルは，1.黒線，2.雫型透過画像，3.毛先の広がり線，4.側面補間線により構成．
  - [fude_line.pde](./fude_veatpro_android8/fude_line.pde)
    - 毛先の広がり線の広がり方を筆圧によって制御．他の図形は[scene_play.pde](./fude_veatpro_android8/scene_play.pde)にて制御．
  - [deg_get.pde](./fude_veatpro_android8/deg_get.pde) / [deg_reset.pde](./fude_veatpro_android8/deg_reset.pde)
    - 書道は筆は細かく回転し，その挙動によって筆跡が変化する．
    - 現在の筆の進行方向などを取得し，目標の筆角度になるように筆跡モデルを回転制御．

### 2. 作品データベース管理
- [ConnectToDatabase.pde](./fude_veatpro_android8/ConnectToDatabase.pde) / [DBHelper.pde](./fude_veatpro_android8/DBHelper.pde)
  - SQLiteを用いたデータベースの管理，アクセスの制御．
- [SaveScreenshotToDatabase.pde](./fude_veatpro_android8/SaveScreenshotToDatabase.pde)
  - タイトル入力画面で入力されたタイトルと作品の画像を，バイト列（Blob）へ変換しデータベースへ格納．
- [LoadImageFromBytes.pde](./fude_veatpro_android8/LoadImageFromBytes.pde) / [LoadImages.pde](./fude_veatpro_android8/LoadImages.pde)
  - データベースから取り出したバイト列を画像に変換してロード．
- [DisplayGallery.pde](./fude_veatpro_android8/DisplayGallery.pde)
  - ロードした作品を和紙の台紙に載せて作品閲覧画面に表示．スクロールに対応．
- [SelectImage.pde](./fude_veatpro_android8/SelectImage.pde) / [ShowImageInfo.pde](./fude_veatpro_android8/ShowImageInfo.pde)
  - 表示された任意の作品をタップすると，作品の題名・作成日と，削除・書き出し・閉じるボタンを表示．
- [DeleteSelectedImage.pde](./fude_veatpro_android8/DeleteSelectedImage.pde) / [RemoveImageFromArray.pde](./fude_veatpro_android8/RemoveImageFromArray.pde)
  - 選択した任意の作品を削除する（画面表示/データベース両方削除）．
- [SaveImageToMediaStore.pde](./fude_veatpro_android8/SaveImageToMediaStore.pde)
  - 選択した作品を端末の`Pictures/MyDrawings`に画像として書き出す．
- [clearGallery.pde](./fude_veatpro_android8/clearGallery.pde)
  - 他画面に遷移した際に，作品閲覧画面に表示されている作品を画面から削除する．

### 3. シーン別の処理
- [fude_veatpro_android8.pde](./fude_veatpro_android8/fude_veatpro_android8.pde)
  - 全てのシーンへの遷移やシステムのメイン動作の処理．
- [display_change.pde](./fude_veatpro_android8/display_change.pde)
  - 他シーンに移る際の待ち時間．
- [scene_title.pde](./fude_veatpro_android8/scene_title.pde) / [scene_play.pde](./fude_veatpro_android8/scene_play.pde) / [scene_help.pde](./fude_veatpro_android8/scene_help.pde) / [scene_gallery.pde](./fude_veatpro_android8/scene_gallery.pde) / [scene_save.pde](./fude_veatpro_android8/scene_save.pde)
  - 各シーン別の処理．特にプレイ画面の制御では，書道特有の筆跡描画に関する記述があります．
  - タイトル入力画面（scene_save）は，プレイ画面で「保存」を押すと表示され，タイトルを入力してから保存する．

### 4. UI制御
- [Button.pde](./fude_veatpro_android8/Button.pde)
  - ボタン変数の宣言とボタンクラスの作成．
- [image.pde](./fude_veatpro_android8/image.pde)
  - 各種ボタン，硯，筆，描画領域，タイトル画面などのイラストの宣言．
- [ui_wafuu.pde](./fude_veatpro_android8/ui_wafuu.pde)
  - 和紙の背景，巻物ボタン，筆文字フォント（YujiSyuku）など，タイトル入力画面・作品閲覧画面を和風にするための部品．
- [TitleEditText.pde](./fude_veatpro_android8/TitleEditText.pde)
  - タイトル入力欄．Android標準の入力欄（EditText）を重ねて表示し，日本語で入力できるようにしている．
- [TextBox.pde](./fude_veatpro_android8/TextBox.pde)
  - テキストボックス変数の宣言とテキストボックスクラスの作成（以前のタイトル入力欄. 英字のみ入力可能）．
- [clearDrawing.pde](./fude_veatpro_android8/clearDrawing.pde)
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

### Kasure_test13の改良版
- [Kasure_test14.pde](./Kasure_test14/Kasure_test14.pde)
- 掠れの筋は「同じ穴が同じ位置に押され続ける」ことで生まれるため，筋を壊さない形で改良．
- **運筆方向へのブラシ回転**
  - 運筆方向に合わせてブラシを回転させ，筋がストロークに沿って曲がるようにした．
- **墨量による掠れの変化**
  - 墨量`inkAmount`が減るほど穴が増えるブラシを8段階用意．前の段階の穴を残したまま穴を追加するため，筋が途切れずに増えていく．
- **ストロークごとの掠れパターン**
  - 一画ごとに穴の配置を作り直し，毎回異なる掠れになるようにした．
- **なめらかなずらし**
  - 抜けるピクセルのずらしを`noise()`でストロークに沿ってゆっくり揺らすようにした．
- **とめの描画をcanvasへ**
  - とめの図形を画面ではなくPGraphicsに描画し，描画処理を描画スレッドにまとめた．


### 毛のモデルによる掠れ表現
- [Kasure_test15.pde](./Kasure_test15/Kasure_test15.pde)
- test14では真横・真縦の線で筋が平行に並び，掠れが単調に見えたため，掠れの生成方法を「ランダムな穴」から「毛（筋）のモデル」に変更．
- **毛のモデル**
  - 筆を線の幅方向に並んだ毛の集まりとみなし，毛ごとに墨が切れているか（=白い筋になるか）を`noise()`で決定．
  - ストロークの途中で筋が始まったり終わったりし，筋の位置もゆっくり揺れる．
  - 筆の縁ほど掠れやすくした．
- **運筆方向による太さの変化**
  - 筆の穂の向き`nibAngle`を考慮し，横画はやや細く，縦画は太めになるようにした．
- **墨の仕様**
  - 画をまたいで墨が減り，INKボタンで補充する．速く書くほど掠れやすくした．
- **入筆・とめ・はね・はらい**
  - 書き始めに雫形を描画．とめは筆の幅に合わせた丸い形に変更．
  - 速く離した時は離す直前の向きと曲がり具合のまま小さくしながら抜き，はね・はらいを表現．
- **検証用スライダー**
  - `dryness`：墨満タンでの掠れやすさ．`streakWidth`：筋の太さ．

### ピクセル単位で墨の付き方を判定する掠れ表現
- [Kasure_test16.pde](./Kasure_test16/Kasure_test16.pde)
- test15ではブラシ画像を重ねて押すため細かい模様が塗りつぶされ，掠れが「黒い線を彫刻刀で削った」ように見えたため，描画方法を変更．
- **ピクセル単位の判定**
  - 筆が通った範囲のピクセルを1つずつ判定し，そのピクセルに当たる毛の墨の量が「紙の凹凸」+「毛1本ごとのムラ」より多い時だけ墨を付ける．
  - 墨の量を連続値で扱うので，墨が減るほど「黒地に白い筋」から「白地に毛の跡」へ少しずつ変わる．
- **輪郭のはっきりした掠れ**
  - 線の外側の毛は掠れにくくし，輪郭ははっきり残したまま内側に白い筋が出るようにした．墨が減ると輪郭も崩れる．
- **墨の減り方**
  - 墨が多いうちはほとんど掠れず，少なくなってから急に掠れるようにした．
- **Processing Androidのバグ回避**
  - `PImage.updatePixels(x, y, w, h)`で一部だけ更新するとアプリが落ちるため，小さい画像に範囲をコピーして全体を更新する方式にした．

---

## 🔄 android6からの変更点
[fude_veatpro_android8]({A})で，android6から変更した内容です．
- **掠れ表現の統合**
  - [Kasure_test16](#ピクセル単位で墨の付き方を判定する掠れ表現)の方式を[KasureBrush.pde]({A}KasureBrush.pde)として統合．掠れ線にするかの判定はandroid6のまま．
  - test16では検証用スライダーで決めていた掠れの強さと毛の粗さを，墨残量メーターの減り方から自動で決めるようにした．
  - 画面に直接描き重ねる方式のため，前のフレームから増えた墨だけを描き，半透明部分が濃くならないようにした．
- **保存の流れ**
  - 描画領域の上部に常に出ていたタイトル入力欄をなくし，「保存」を押すとタイトル入力画面へ移るようにした．
  - Android標準の入力欄を重ね，日本語でタイトルを入力できるようにした．
  - タイトル入力画面から戻った時は，保存を押す前の画面を描き戻し，続きを書けるようにした．
- **和風UI**
  - タイトル入力画面と作品閲覧画面を，タイトル画面・プレイ画面のイラスト（和紙の背景，巻物ボタン，文字画像）を使って同じ雰囲気にした．
  - 作品閲覧画面の赤い四角のボタンをなくし，巻物ボタン（終了・削除・書き出し・閉じる）にした．
  - 文字画像がない文字は筆文字フォント（YujiSyuku）で表示．
- **不具合の修正**
  - 筆圧が0.211を超えると角度計算がNaNになり，アプリが固まる問題．
  - 作品の情報を一度閉じると，次に開こうとした時に落ちる問題．
  - スクロール後に選ばれる作品がずれる問題，スクロールしただけで作品が選ばれる問題．
  - 作品閲覧でデータベースを毎フレーム読み込んでいた問題．
  - `surfaceTouchEvent`から`touchMoved()`/`touchEnded()`が二重に呼ばれていた問題．
- **その他**
  - アプリのパッケージ名を`processing.test.fude_veatpro_android8`にし，android6とは別のアプリとしてインストールされるようにした．
