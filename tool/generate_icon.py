"""
生成 Chrono Calendar 应用图标
渐变背景 + 白色日历图标 + 圆角
"""

from PIL import Image, ImageDraw, ImageFont
import math
import os

def create_gradient(width, height, color1, color2):
    """创建线性渐变图像（左上到右下）"""
    image = Image.new('RGBA', (width, height))
    draw = ImageDraw.Draw(image)

    r1, g1, b1 = color1
    r2, g2, b2 = color2

    for y in range(height):
        for x in range(width):
            # 计算渐变进度（左上到右下对角线）
            progress = (x + y) / (width + height - 2)

            r = int(r1 + (r2 - r1) * progress)
            g = int(g1 + (g2 - g1) * progress)
            b = int(b1 + (b2 - b1) * progress)

            draw.point((x, y), fill=(r, g, b, 255))

    return image

def add_rounded_corners(image, radius):
    """添加圆角"""
    # 创建圆角遮罩
    mask = Image.new('L', image.size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle([(0, 0), image.size], radius=radius, fill=255)

    # 应用遮罩
    result = Image.new('RGBA', image.size, (0, 0, 0, 0))
    result.paste(image, mask=mask)
    return result

def draw_calendar_icon(draw, center_x, center_y, size, color):
    """绘制日历图标"""
    # 计算边界
    half = size // 2
    left = center_x - half
    top = center_y - half
    right = center_x + half
    bottom = center_y + half

    # 线条宽度
    line_width = max(size // 12, 8)
    corner_radius = size // 8

    # 日历主体（圆角矩形）
    body_top = top + size // 5
    draw.rounded_rectangle(
        [(left, body_top), (right, bottom)],
        radius=corner_radius,
        outline=color,
        width=line_width
    )

    # 填充顶部区域（表示日历头部）
    header_bottom = body_top + size // 4
    draw.rounded_rectangle(
        [(left, body_top), (right, header_bottom)],
        radius=corner_radius,
        fill=color
    )
    # 覆盖底部圆角
    draw.rectangle(
        [(left, header_bottom - corner_radius), (right, header_bottom)],
        fill=color
    )

    # 日历挂钩（两个小矩形）
    hook_width = line_width
    hook_height = size // 6
    hook_y = top

    # 左挂钩
    hook1_x = left + size // 4
    draw.rounded_rectangle(
        [(hook1_x - hook_width//2, hook_y),
         (hook1_x + hook_width//2, hook_y + hook_height)],
        radius=hook_width//3,
        fill=color
    )

    # 右挂钩
    hook2_x = right - size // 4
    draw.rounded_rectangle(
        [(hook2_x - hook_width//2, hook_y),
         (hook2_x + hook_width//2, hook_y + hook_height)],
        radius=hook_width//3,
        fill=color
    )

    # 日历网格点（3x2）
    grid_top = header_bottom + size // 10
    grid_left = left + size // 5
    grid_right = right - size // 5
    grid_bottom = bottom - size // 8

    dot_size = size // 12
    cols = 3
    rows = 2

    h_spacing = (grid_right - grid_left) / (cols - 1) if cols > 1 else 0
    v_spacing = (grid_bottom - grid_top) / (rows - 1) if rows > 1 else 0

    for row in range(rows):
        for col in range(cols):
            dx = grid_left + col * h_spacing
            dy = grid_top + row * v_spacing
            draw.ellipse(
                [(dx - dot_size//2, dy - dot_size//2),
                 (dx + dot_size//2, dy + dot_size//2)],
                fill=color
            )

def generate_app_icon(size=1024, output_path='app_icon.png'):
    """生成应用图标"""
    # 颜色定义
    primary_color = (37, 99, 235)    # #2563EB - 蓝色
    tertiary_color = (8, 145, 178)   # #0891B2 - 青色
    white = (255, 255, 255)

    # 创建渐变背景
    print(f"创建 {size}x{size} 渐变背景...")
    image = create_gradient(size, size, primary_color, tertiary_color)

    # 添加圆角
    corner_radius = int(size * 0.2)  # 20% 圆角
    print(f"添加圆角 (radius={corner_radius})...")
    image = add_rounded_corners(image, corner_radius)

    # 绘制日历图标
    draw = ImageDraw.Draw(image)
    icon_size = int(size * 0.55)  # 图标占 55%
    print(f"绘制日历图标 (size={icon_size})...")
    draw_calendar_icon(draw, size // 2, size // 2, icon_size, white)

    # 保存
    print(f"保存图标到 {output_path}...")
    image.save(output_path, 'PNG')
    print("完成!")

    return image

def main():
    # 确保输出目录存在
    output_dir = 'assets/icons'
    os.makedirs(output_dir, exist_ok=True)

    # 生成主图标 (1024x1024)
    output_path = os.path.join(output_dir, 'app_icon.png')
    generate_app_icon(1024, output_path)

    # 同时生成一个前景图标（用于 Android 自适应图标）
    # 这个图标需要有足够的安全边距
    fg_path = os.path.join(output_dir, 'app_icon_foreground.png')
    generate_foreground_icon(1024, fg_path)

    print(f"\n图标已生成:")
    print(f"  - {output_path}")
    print(f"  - {fg_path}")

def generate_foreground_icon(size=1024, output_path='app_icon_foreground.png'):
    """生成自适应图标的前景层（带安全边距的白色日历图标）"""
    image = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)

    # 自适应图标需要留出约 25% 的安全边距
    # 所以图标实际只占中间 50% 的区域
    icon_size = int(size * 0.45)
    white = (255, 255, 255)

    print(f"生成前景图标 (size={icon_size})...")
    draw_calendar_icon(draw, size // 2, size // 2, icon_size, white)

    image.save(output_path, 'PNG')

if __name__ == '__main__':
    main()
