#!/bin/bash

# 设置颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 显示错误信息并退出
error_exit() {
    echo -e "${RED}错误: $1${NC}" >&2
    exit 1
}

# 显示信息
info() {
    echo -e "${YELLOW}$1${NC}"
}

# 显示成功信息
success() {
    echo -e "${GREEN}$1${NC}"
}

# 转换为大写
to_upper() {
    echo "$1" | tr '[:lower:]' '[:upper:]'
}

# 创建工作目录
create_dirs() {
    info "创建工作目录..."
    for dir in font bdf code maps; do
        mkdir -p $dir
    done
    success "目录创建完成"
}

# 生成头文件
generate_header() {
    local font_name=$1
    local source_name=$2
    local upper_name=$(to_upper "$source_name")
    
    # 创建头文件
    echo "#ifndef _${upper_name}_H" > "code/${source_name}.h"
    echo "#define _${upper_name}_H" >> "code/${source_name}.h"
    cat header1.txt >> "code/${source_name}.h"
    echo "extern const uint8_t ${source_name}[] U8G2_FONT_SECTION(\"${source_name}\");" >> "code/${source_name}.h"
    cat header2.txt >> "code/${source_name}.h"
}

# 完成源代码处理
finish_source_code() {
    local font_name=$1
    local source_name=$2
    
    if [ ! -f "code/${source_name}.c" ]; then
        info "警告: 源文件 ${source_name}.c 不存在"
        return 1
    fi
    
    # 添加头文件包含
    echo "#include \"${source_name}.h\"" > "code/temp.c"
    cat "code/${source_name}.c" >> "code/temp.c"
    mv "code/temp.c" "code/${source_name}.c"
    
    # 生成头文件
    generate_header "$font_name" "$source_name"
}

# 检查必要工具
check_tools() {
    info "检查必要工具..."
    
    for tool in otf2bdf bdfconv; do
        if ! command -v $tool >/dev/null 2>&1; then
            error_exit "$tool 未安装。请先安装必要工具。"
        fi
    done
    
    success "工具检查完成"
}

# 检查并清理旧数据
check_and_clean() {
    if [ -d "code" ] && [ "$(ls -A code 2>/dev/null)" ]; then
        info "发现已存在的生成文件"
        read -p "是否清空已有数据？[Y/n] " response
        response=${response:-Y}
        if [[ $response =~ ^[Yy] ]]; then
            rm -rf code/* bdf/*
            success "已清空旧数据"
        else
            info "保留旧数据"
        fi
    fi
}

# 选择字体文件
select_font() {
    local font_files=()
    local i=1
    
    echo "可用的字体文件："
    while IFS= read -r -d $'\0' file; do
        font_files+=("$file")
        echo "$i) $(basename "$file")"
        ((i++))
    done < <(find font -type f \( -name "*.ttf" -o -name "*.otf" \) -print0)
    
    if [ ${#font_files[@]} -eq 0 ]; then
        error_exit "没有找到任何字体文件，请将字体文件(.ttf或.otf)放入font目录"
    fi
    
    while true; do
        read -p "请选择字体文件 (1-${#font_files[@]}): " font_num
        if [[ "$font_num" =~ ^[0-9]+$ ]] && [ "$font_num" -ge 1 ] && [ "$font_num" -le "${#font_files[@]}" ]; then
            selected_font="${font_files[$((font_num-1))]}"
            selected_font_name=$(basename "${selected_font%.*}" | tr '[:upper:]' '[:lower:]' | tr ' ' '_')
            break
        else
            info "请输入有效的数字 (1-${#font_files[@]})"
        fi
    done
    
    echo "已选择: $(basename "$selected_font")"
}

# 输入字体大小
input_font_sizes() {
    while true; do
        read -p "请输入要生成的字体大小（多个大小用空格分隔，如：16 24 32）: " sizes
        if [[ "$sizes" =~ ^[0-9[:space:]]+$ ]]; then
            selected_sizes=($sizes)
            break
        else
            info "请输入有效的数字，用空格分隔"
        fi
    done
    
    echo "将生成以下字体大小: ${selected_sizes[*]}"
}

# 选择字库映射文件
select_maps() {
    local available_maps=()
    local selected_maps=()
    local i=1
    
    echo "可用的字库映射文件："
    while IFS= read -r -d $'\0' file; do
        available_maps+=("$(basename "$file" .map)")
        echo "$i) $(basename "$file" .map)"
        ((i++))
    done < <(find maps -type f -name "*.map" -print0)
    
    if [ ${#available_maps[@]} -eq 0 ]; then
        error_exit "没有找到任何映射文件，请确保maps目录中有.map文件"
    fi
    
    echo "请选择要使用的字库映射文件（多选，用空格分隔，直接回车选择全部）："
    echo "0) 仅生成基本字体（number/tu/tr）"
    read -p "请选择 (0 或 1-${#available_maps[@]}): " -a map_nums
    
    if [ ${#map_nums[@]} -eq 0 ]; then
        selected_maps=("${available_maps[@]}")
        info "已选择所有字库映射"
    elif [ "${map_nums[0]}" = "0" ]; then
        info "仅生成基本字体"
    else
        for num in "${map_nums[@]}"; do
            if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le "${#available_maps[@]}" ]; then
                selected_maps+=("${available_maps[$((num-1))]}")
            fi
        done
    fi
    
    echo "已选择的字库映射: ${selected_maps[*]:-无}"
    SELECTED_MAPS=("${selected_maps[@]}")
}

# 生成BDF字体
process_font() {
    local font_file=$1
    local font_name=$2
    local font_size=$3
    local bdf_file="bdf/${font_name}-${font_size}.bdf"
    
    info "正在处理字体: $font_name ($font_size pt)"
    
    # 生成BDF字体
    info "生成BDF字体..."
    otf2bdf -v -r 100 -p "$font_size" -o "$bdf_file" "$font_file"
    
    if [ ! -f "$bdf_file" ] || [ ! -s "$bdf_file" ]; then
        error_exit "BDF文件生成失败或为空"
    fi
    
    success "BDF字体生成成功"
    
    # 生成基本字体
    info "生成数字字体..."
    bdfconv -b 0 -f 1 -m "48-57" \
        -n "u8g2_${font_name}_${font_size}_number" \
        -o "code/u8g2_${font_name}_${font_size}_number.c" "$bdf_file"
    finish_source_code "$font_name" "u8g2_${font_name}_${font_size}_number"
    
    info "生成基本ASCII字体..."
    bdfconv -b 0 -f 1 -m "32-95" \
        -n "u8g2_${font_name}_${font_size}_tu" \
        -o "code/u8g2_${font_name}_${font_size}_tu.c" "$bdf_file"
    finish_source_code "$font_name" "u8g2_${font_name}_${font_size}_tu"
    
    info "生成扩展ASCII字体..."
    bdfconv -b 0 -f 1 -m "32-127" \
        -n "u8g2_${font_name}_${font_size}_tr" \
        -o "code/u8g2_${font_name}_${font_size}_tr.c" "$bdf_file"
    finish_source_code "$font_name" "u8g2_${font_name}_${font_size}_tr"
    
    # 生成选择的中文字体
    if [ ${#SELECTED_MAPS[@]} -gt 0 ]; then
        for map in "${SELECTED_MAPS[@]}"; do
            info "生成 ${map} 字体..."
            if [ -f "maps/${map}.map" ]; then
                bdfconv -b 0 -f 1 -M "maps/${map}.map" \
                    -n "u8g2_${font_name}_${font_size}_${map}" \
                    -o "code/u8g2_${font_name}_${font_size}_${map}.c" "$bdf_file"
                finish_source_code "$font_name" "u8g2_${font_name}_${font_size}_${map}"
            else
                info "警告: 找不到映射文件 maps/${map}.map"
            fi
        done
    fi
    
    return 0
}

# 主函数
main() {
    echo "=== U8G2字体生成工具 ==="
    
    # 检查必要工具
    check_tools
    
    # 检查并清理旧数据
    check_and_clean
    
    # 创建必要目录
    create_dirs
    
    # 选择字体文件
    select_font
    
    # 输入字体大小
    input_font_sizes
    
    # 选择字库映射
    select_maps
    
    # 处理字体
    for size in "${selected_sizes[@]}"; do
        process_font "$selected_font" "$selected_font_name" "$size"
    done
    
    success "所有任务完成！"
    info "生成的源代码文件在 code 目录中"
}

# 运行主程序
main
