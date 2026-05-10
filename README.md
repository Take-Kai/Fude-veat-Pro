# 水導電筆とタブレット端末を用いた書道インタラクションシステム

八戸高専本科5年生〜専攻科2年までの3年間，研究テーマとして取り組みました．

このシステムは、タブレット端末を用いて仮想的に書道表現を行うことができるシステムです．

実際の書道筆に導電加工を施した「水導電筆」とProcessingで構築した書道表現を再現するアルゴリズムを組み合わせ，デジタル上で本物に近い書道体験を実現できます．

背景や研究活動としての発表資料，詳細は[Notionページ](https://wholesale-beginner-8e9.notion.site/veat-Pro-Fude-veat-Pro-347306a87b4980c79177c44f07dcf865)からご覧いただけます．

---

## ⚒️ 開発環境
- **System

PC：MacBook Air Apple M3チップ，メモリ16GB

ソフトウェア：Processing，Python

データベース：SQLite

タブレット：HUAWEI HDN-W09，NEC LAVIE Tab 102K1，Xiaomi Pad 7 Pro


## ハードウェア / Hardware

使用するタブレットは上記の3つですが，主にHUAWEI HDN-W09で実装を進めました．

また，半紙の上に書いているような感覚を再現するために，タブレットの表面にペーパーライクフィルムと呼ばれる紙の質感を再現するフィルムを貼付しています．

<img width="500" alt="huawei" src="https://github.com/Take-Kai/Tablet-Calligraphy/assets/169955027/b8bce327-ad10-4a2e-aaec-b42bda95eba1">

Fig. 1 HUAWEI HDN-W09

<img width="500" alt="nec" src="https://github.com/Take-Kai/Tablet-Calligraphy/assets/169955027/98b59eb5-bda5-4c48-b5e3-ec3f94a8ba53">

Fig. 2 Xiaomi Pad 7 Pro


入力デバイスとして「水導電筆」と呼ばれる独自のデバイスを作成しました．

これは，実際の書道筆に導電性の糸を巻き付け，補佐機を水に濡らすことでタブレット画面に反応するようにしたものです．

<img width="500" alt="fude" src="https://github.com/Take-Kai/Tablet-Calligraphy/assets/169955027/3c0dd1a3-89ea-44c2-9ddb-ed3e1d63558f">

Fig. 3 水導電筆


## システムの実装 / Imprementation

### 保存・閲覧機能 / Save & Review


書いた作品を保存し，閲覧できるようにすることで作品の良い点と悪い点を分析できます．
この機能にはデータベースを用いていますが，本システムは大規模データの管理は必要なく，サーバを必要としないのでSQLiteを用いています．



### 筆圧による線の太さ変化 / Line Thickness Variation by Writing Pressure

筆圧によって線の太さが変わる表現は書道の特徴であり，表現技法のひとつです．

本研究では，圧力を検知するために画面へのタッチを判定するクラスTouchEventを用いています．



### 掠れ表現 / Fading Expression
掠れ表現を再現するために，Processingに標準搭載のPGraphicsというクラスを用いています．

PGraphicsを用いることで，1ピクセル単位で黒/白を指定でき，より細かい制御ができます．

ここに実装のイメージ図と実装の様子をのっける


### 永字八法 / Eiji-Happo （Eight techniques in one kanji "永"）



## システムの動作 / Operation



## システムの主観評価 / Subjective Evaluation



## システムの客観評価 / Objective Evaluation



## 課題と今後の展望 / Future Work




## 受賞・学会発表 / Presentaion　& Award

| 発表日 | 学会・コンテスト名 | 発表タイトル | 受賞 | URL |
| --- | --- | --- | --- | --- |
| 2024.2 | 令和5年度第2回芸術科学会東北支部研究会 | タブレット端末を用いた仮想書道体験システムにおける描画方法と書道表現実装の検討 | - | - |
| 2024.11 | 令和6年東北・北海道地区高等専門学校専攻科産学連携シンポジウム | 仮想書道体験システムにおけるタブレット端末上での書道技法実装の検討 | - | - |
| 2025.3 | 令和6年度第2回芸術科学会東北支部研究会 | 水導電筆とタブレットを用いた書道インタラクションシステムの試作 | - | - |
| 2025.6 | NICOGRAPH International 2025 | Prototype of Calligraphy Interaction System Using a Water Conductive Brush and Tablet | Best Poster Award | https://www.art-science.org/nicograph/nicoint2025/ |
| 2025.7 | 芸術科学会東北支部 アート&テクノロジー東北2025 | 筆veat Pro | 審査員特別賞 | http://www-cg.cis.iwate-u.ac.jp/AT2025/ |
| 2025.10 | 第4回北東北地区大学高専交流会 | 水導電筆とタブレットを用いた書道インタラクションシステムに関する研究 | 優秀発表賞 | - |
| 2026.2 | 令和7年度第2回芸術科学会東北支部研究会 | 水導電筆とタブレット端末を用いた書道インタラクションシステムにおける渇筆表現実装 | - | - |

