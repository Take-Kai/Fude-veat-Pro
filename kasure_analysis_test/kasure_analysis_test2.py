import cv2
import numpy as np
import matplotlib.pyplot as plt

# =========================
# 設定
# =========================
IMAGE_PATH = "ronbun_b.png"   # 入力画像. 同一フォルダ内におく必要がある
GRAD_THRESHOLD = 20              # 濃度勾配が強い = 掠れが発生していると判定する閾値
                                 # Sobelフィルタ後の勾配値は画像濃度(0-255)とフィルタサイズに依存????
SMALL_AREA_THRESH = 50           # 掠れによって線が分断された部分の最小ピクセル. 50以下の黒画像部分を掠れによる分断片とみなす


# =========================
# 画像読み込み
# =========================
img = cv2.imread(IMAGE_PATH)    # 画像を読み込んでimgに格納
if img is None:
    raise FileNotFoundError("画像が読み込めません。パスを確認してください。")   # 画像が読み込めなかった時の処理

gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)    # グレースケール化した画像をgrayに格納

# ノイズ軽減（ガウシアンフィルタ）
# 周囲5×5画素を使って平滑化
gray_blur = cv2.GaussianBlur(gray, (5, 5), 0)


# ============================================================
# 線が書かれている部分のみを抽出
# スクショを読み込んでいるのでUIなどが含まれてるかもだから
# 結果として, 薄れたり掠れたりしても「墨が存在した可能性がある領域」を推定
# ============================================================
binary = cv2.adaptiveThreshold(
    gray_blur,      # 入力画像（ノイズ除去後）
    255,            # 二値化後の輝度（255は白）
    cv2.ADAPTIVE_THRESH_GAUSSIAN_C,     # フィルタの種類：ガウシアンフィルタ
    cv2.THRESH_BINARY_INV,      # 二値化の種類（INVがつくと白黒反転）
    31,             # 閾値計算に使う近傍サイズ
    5               # 局所平均から引く定数
)


# =========================
# 濃度勾配計算
# 濃度勾配 = (d/dx, d/dy)
# =========================
# Sobelフィルタ -> 微分と平滑化を同時に行う
# cv2.Sobel(入力画像, 浮動小数点, x方向に1階微分, 3×3のカーネル　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　z)
grad_x = cv2.Sobel(gray_blur, cv2.CV_64F, 1, 0, ksize=3)
grad_y = cv2.Sobel(gray_blur, cv2.CV_64F, 0, 1, ksize=3)

# 掠れの方向, つまりプラマイは判定しなくて良い -> 大きさを求めている
grad_mag = np.sqrt(grad_x**2 + grad_y**2)

# 線領域のみを対象にする
grad_line = grad_mag[binary > 0]
# grad_inner = grad_mag[inner_mask > 0]


# =========================
# 掠れ指標の算出
# =========================
mean_grad = np.mean(grad_line)  # 平均勾配. 線全体としてどれくらい濃度にばらつきがあるか.
std_grad  = np.std(grad_line)   # 標準偏差. この値が大きいほど掠れが点在することになる.
p90_grad  = np.percentile(grad_line, 90)    # 掠れている強さが上位10%の部分
high_grad_ratio = np.sum(grad_line > GRAD_THRESHOLD) / len(grad_line)   # どれくらいの割合が明確に掠れているかを判定


# 黒線の塊を検出 = 少しでも繋がっていたら塊と判定
num_labels, labels, stats, _ = cv2.connectedComponentsWithStats(binary)
small_components = np.sum(stats[1:, cv2.CC_STAT_AREA] < SMALL_AREA_THRESH)


# 結果表示
print("==== 掠れ評価指標 ====")
print(f"平均勾配値            : {mean_grad:.2f}")
print(f"勾配標準偏差          : {std_grad:.2f}")
print(f"上位10%勾配値 : {p90_grad:.2f}")
print(f"高勾配画素率          : {high_grad_ratio:.3f}")
print(f"連結成分数          : {small_components}")


# =========================
# 表示
# =========================
plt.figure(figsize=(15, 8))

# 元画像
plt.subplot(2, 3, 1)
plt.title("Original")
plt.imshow(cv2.cvtColor(img, cv2.COLOR_BGR2RGB))
plt.axis("off")

# グレースケール
plt.subplot(2, 3, 2)
plt.title("Grayscale")
plt.imshow(gray, cmap="gray")
plt.axis("off")

# 二値画像
plt.subplot(2, 3, 3)
plt.title("Binary (Stroke Mask)")
plt.imshow(binary, cmap="gray")
plt.axis("off")

# 勾配強度
plt.subplot(2, 3, 4)
plt.title("Gradient Magnitude")
plt.imshow(grad_mag, cmap="inferno")
plt.colorbar(fraction=0.046)
plt.axis("off")

# 勾配（線領域のみ）
masked_grad = np.zeros_like(grad_mag)
masked_grad[binary > 0] = grad_mag[binary > 0]

plt.subplot(2, 3, 5)
plt.title("Gradient on Stroke")
plt.imshow(masked_grad, cmap="inferno")
plt.axis("off")

# 勾配ヒストグラム
plt.subplot(2, 3, 6)
plt.title("Gradient Histogram (Stroke)")
plt.hist(grad_line, bins=50)
plt.xlabel("Gradient Magnitude")
plt.ylabel("Frequency")

plt.tight_layout()
plt.show()