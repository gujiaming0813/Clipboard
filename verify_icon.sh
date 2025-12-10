#!/bin/bash

# 验证应用图标配置脚本

echo "🔍 检查应用图标配置..."
echo ""

# 检查 Assets.xcassets 是否存在
if [ -d "Clipboard/Clipboard/Assets.xcassets/AppIcon.appiconset" ]; then
    echo "✅ Assets.xcassets/AppIcon.appiconset 存在"
else
    echo "❌ Assets.xcassets/AppIcon.appiconset 不存在"
    exit 1
fi

# 检查所有图标文件
echo ""
echo "📦 检查图标文件..."
icon_count=0
for icon in Clipboard/Clipboard/Assets.xcassets/AppIcon.appiconset/icon_*.png; do
    if [ -f "$icon" ]; then
        icon_count=$((icon_count + 1))
        echo "  ✅ $(basename $icon)"
    fi
done

if [ $icon_count -eq 10 ]; then
    echo ""
    echo "✅ 所有 10 个图标文件都存在"
else
    echo ""
    echo "⚠️  只找到 $icon_count/10 个图标文件"
fi

# 检查 Contents.json
if [ -f "Clipboard/Clipboard/Assets.xcassets/AppIcon.appiconset/Contents.json" ]; then
    echo "✅ Contents.json 存在"
else
    echo "❌ Contents.json 不存在"
    exit 1
fi

# 检查项目配置
echo ""
echo "⚙️  检查项目配置..."
if grep -q "ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon" Clipboard/Clipboard.xcodeproj/project.pbxproj; then
    echo "✅ 项目配置正确 (ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon)"
else
    echo "❌ 项目配置缺失"
    exit 1
fi

echo ""
echo "🎉 图标配置验证完成！"
echo ""
echo "📝 导出应用时的注意事项："
echo "   1. 在 Xcode 中选择 Product > Archive"
echo "   2. 在 Organizer 中选择 Distribute App"
echo "   3. 选择 Copy App 导出 .app 文件"
echo "   4. 导出的 .app 会自动包含图标"
echo ""
echo "💡 验证导出的 .app 是否包含图标："
echo "   cd /path/to/exported/Clipboard.app/Contents/Resources"
echo "   ls -la | grep AppIcon"

