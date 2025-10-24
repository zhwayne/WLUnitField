# WLUnitField

一个优雅简洁的密码/验证码输入框，支持多种样式和自定义选项。

An elegant and concise password/verification code text field with multiple styles and customization options.

![](./demo.gif)

## 功能特点（Features）

- ✅ **自动布局支持** - 完全支持 Auto Layout
- ✅ **多种界面样式** - 边框样式和下划线样式
- ✅ **自动填充支持** - 支持 iOS 12+ 的验证码自动填充
- ✅ **光标控制** - 支持显示/隐藏光标
- ✅ **主题集成** - 与系统 tintColor 完美集成
- ✅ **Swift Package Manager** - 支持 SPM 集成
- ✅ **Interface Builder** - 支持 Storyboard 可视化配置

## 安装方式（Installation）

### Swift Package Manager

在 Xcode 中：
1. File > Add Packages...
2. 输入仓库 URL: `https://github.com/zhwayne/WLUnitField.git`
3. 选择版本并添加

或在 Package.swift 中添加：
```swift
dependencies: [
    .package(url: "https://github.com/zhwayne/WLUnitField.git", from: "1.0.0")
]
```

### 手动集成

将 `WLUnitField/Classes/` 目录下的文件添加到你的项目中。

## 基本使用（Basic Usage）

### 创建实例

```objc
// 创建 4 位验证码输入框
WLUnitField *unitField = [[WLUnitField alloc] initWithInputUnitCount:4];

// 或指定样式
WLUnitField *unitField = [[WLUnitField alloc] initWithStyle:WLUnitFieldStyleBorder 
                                            inputUnitCount:6];
```

### 基本配置

```objc
// 设置代理
unitField.delegate = self;

// 设置间距
unitField.unitSpace = 12;

// 设置圆角
unitField.borderRadius = 4;

// 设置边框宽度
unitField.borderWidth = 1;

// 设置单元大小
unitField.unitSize = CGSizeMake(44, 44);
```

### 颜色配置

```objc
// 设置文本颜色
unitField.textColor = [UIColor blackColor];

// 设置边框/下划线颜色
unitField.strokeColor = [UIColor systemBlueColor];

// 设置已完成单元的颜色
unitField.trackTintColor = [UIColor systemGreenColor];

// 设置光标颜色（使用系统 tintColor）
unitField.tintColor = [UIColor systemOrangeColor];
```

### 光标控制

```objc
// 显示光标（默认）
unitField.showsCursor = YES;

// 隐藏光标
unitField.showsCursor = NO;
```

### 事件监听

```objc
[unitField addTarget:self 
              action:@selector(unitFieldEditingChanged:) 
    forControlEvents:UIControlEventEditingChanged];

- (IBAction)unitFieldEditingChanged:(WLUnitField *)sender {
    NSLog(@"输入内容: %@", sender.text);
}
```

## 高级功能（Advanced Features）

### 自动填充支持

```objc
// 支持 iOS 12+ 验证码自动填充
if (@available(iOS 12.0, *)) {
    unitField.textContentType = UITextContentTypeOneTimeCode;
}
```

### 输入验证

```objc
// 只允许数字输入
unitField.allowedCharacterSet = [NSCharacterSet decimalDigitCharacterSet];

// 自定义字符集
NSMutableCharacterSet *customSet = [NSMutableCharacterSet alphanumericCharacterSet];
unitField.allowedCharacterSet = customSet;
```

### 自动完成处理

```objc
// 输入完成后自动取消第一响应者
unitField.autoResignFirstResponderWhenInputFinished = YES;
```

### 代理方法

```objc
- (BOOL)unitField:(WLUnitField *)unitField 
shouldChangeCharactersInRange:(NSRange)range 
replacementString:(NSString *)string {
    // 自定义输入验证逻辑
    return YES;
}
```

## Interface Builder 支持

所有属性都支持 Interface Builder，可以在 Storyboard 中直接配置：

- `inputUnitCount` - 输入单元数量
- `style` - 界面样式
- `unitSpace` - 单元间距
- `borderRadius` - 圆角半径
- `borderWidth` - 边框宽度
- `textColor` - 文本颜色
- `strokeColor` - 边框颜色
- `trackTintColor` - 已完成单元颜色
- `showsCursor` - 是否显示光标
- `autoResignFirstResponderWhenInputFinished` - 自动完成处理

## 样式示例（Style Examples）

### 边框样式
```objc
WLUnitField *unitField = [[WLUnitField alloc] initWithStyle:WLUnitFieldStyleBorder 
                                            inputUnitCount:4];
unitField.unitSpace = 12;
unitField.borderRadius = 4;
unitField.borderWidth = 1;
```

### 下划线样式
```objc
WLUnitField *unitField = [[WLUnitField alloc] initWithStyle:WLUnitFieldStyleUnderline 
                                            inputUnitCount:6];
unitField.unitSpace = 8;
unitField.borderWidth = 2;
```

## 系统要求（Requirements）

- iOS 9.0+
- Xcode 11.0+
- Swift 5.0+

## 许可证（License）

MIT License