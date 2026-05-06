import cv2
import numpy as np
import matplotlib.pyplot as plt

IMAGE_PATH = "kasure_pg_test.png"

# =========================
# 画像読み込み
# =========================
img = cv2.imread(IMAGE_PATH)
gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
gray_blur = cv2.GaussianBlur(gray, (5, 5), 0)

# =========================
# 線領域抽出
# =========================
binary = cv2.adaptiveThreshold(
    gray_blur, 255,
    cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
    cv2.THRESH_BINARY_INV,
    31, 5
)

# =========================
# 輪郭（エッジ）検出
# =========================
edges = cv2.Canny(gray_blur, 50, 150)

# 線領域かつ非輪郭 = 内部
inner_mask = (binary > 0) & (edges == 0)

# =========================
# 掠れ強度定義
# =========================
# 白に近いほど掠れ強
kasure_strength = np.zeros_like(gray, dtype=np.float32)
kasure_strength[inner_mask] = gray[inner_mask] / 255.0

# =========================
# 可視化用
# =========================
kasure_map = np.zeros_like(kasure_strength)
kasure_map[inner_mask] = kasure_strength[inner_mask]

kasure_values = kasure_strength[inner_mask]

# =========================
# 表示
# =========================
plt.figure(figsize=(16, 9))

plt.subplot(2, 3, 1)
plt.title("Original")
plt.imshow(cv2.cvtColor(img, cv2.COLOR_BGR2RGB))
plt.axis("off")

plt.subplot(2, 3, 2)
plt.title("Binary (Stroke)")
plt.imshow(binary, cmap="gray")
plt.axis("off")

plt.subplot(2, 3, 3)
plt.title("Inner Stroke Mask")
plt.imshow(inner_mask, cmap="gray")
plt.axis("off")

plt.subplot(2, 3, 4)
plt.title("Kasure Strength Map")
plt.imshow(kasure_map, cmap="hot")
plt.colorbar()
plt.axis("off")

plt.subplot(2, 3, 5)
plt.title("Kasure Histogram (Inner Stroke)")
plt.hist(kasure_values, bins=50)
plt.xlabel("Kasure Strength")
plt.ylabel("Frequency")

plt.tight_layout()
plt.show()