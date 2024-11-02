# U8G2 Font Generator for macOS

一个为 macOS 用户设计的工具，用于将 TTF/OTF 字体转换为 U8G2 字库格式。支持中英文字体转换，可自定义字号和字符映射集。

A tool designed for macOS users to convert TTF/OTF fonts to U8G2 font format. Supports both Chinese and English font conversion with customizable font sizes and character mapping sets.

## 功能特点 | Features

- 支持 TTF/OTF 字体格式转换
- 自定义字号生成
- 可选择性生成不同字符集
- 自动生成头文件和源文件
- 支持中英文字符映射
- 命令行界面操作

- Support TTF/OTF font format conversion
- Custom font size generation
- Selective character set generation
- Automatic header and source file generation
- Support for Chinese and English character mapping
- Command-line interface operation

## 依赖项 | Dependencies

- otf2bdf
- bdfconv (U8G2 工具集)
- Homebrew

## 安装 | Installation

```bash
# 安装 otf2bdf
brew install otf2bdf

# 下载并编译 bdfconv
mkdir -p ~/temp && cd ~/temp
curl -LO https://github.com/olikraus/u8g2/archive/refs/heads/master.zip
unzip master.zip
cd u8g2-master/tools/font/bdfconv
make
sudo cp bdfconv /usr/local/bin/
```

## 使用方法 | Usage

1. 将字体文件(.ttf 或 .otf)放入 `font` 目录
2. 将字符映射文件(.map)放入 `maps` 目录
3. 运行脚本：
```bash
./generate_u8g2_font.sh
```
4. 按照提示选择：
   - 字体文件
   - 字号大小
   - 字符映射集

## 目录结构 | Directory Structure

```
.
├── font/           # 存放字体文件
├── maps/           # 存放字符映射文件
├── code/           # 生成的源代码文件
└── bdf/            # 临时 BDF 文件
```

## 输出文件 | Output Files

生成的文件将保存在 `code` 目录中：
- `.h` 文件：字体头文件
- `.c` 文件：字体数据文件

Files will be generated in the `code` directory:
- `.h` files: Font header files
- `.c` files: Font data files

## 注意事项 | Notes

- 确保系统已正确安装 otf2bdf 和 bdfconv
- 字体文件必须放在 `font` 目录下
- 字符映射文件必须放在 `maps` 目录下
- 生成大字号或大字符集可能需要较长时间

- Ensure otf2bdf and bdfconv are properly installed
- Font files must be placed in the `font` directory
- Mapping files must be placed in the `maps` directory
- Generating large font sizes or character sets may take time

## 许可证 | License

MIT License

## 联系方式 | Contact

如有问题或建议，请提交 Issue。

For questions or suggestions, please submit an Issue.
