# 简介（Introduction）

这是一个优雅简洁的密码/验证码输入框，你可以像使用`UITextField`一样去使用`WLUnitField`。
This is an elegant and concise password/verification code text field. You can use `WLUnitField` just like `UITextField`.

![](./demo.gif)

# 功能特点（Features）
- 支持自动布局（Auto layout supports）
- 提供两种界面面样式：边框和下划线（Provide two UI styles: border-based and underline-based）
- 支持自动填充验证码，仅限 iOS 12 系统（Autofill One time code supports, only for iOS 12+）

# 安装方式（Installation）

## Swift Package Manager

在 Xcode 中：
1. File > Add Packages...
2. 输入仓库 URL: `https://github.com/username/WLUnitField.git`
3. 选择版本并添加

或在 Package.swift 中添加：
```swift
dependencies: [
    .package(url: "https://github.com/username/WLUnitField.git", from: "1.0.0")
]
```

## 手动集成

将 `WLUnitField/Classes/` 目录下的文件添加到你的项目中。

# 使用方式（Usage）

`WLUnitField`的使用非常简单。它继承自`UIControl`，你可以给它添加以下 3 种`UIControlEvents`：
`WLUnitField` is very sample to use. You use the following 3 kinds of `UIControlEvents`:

* UIControlEventEditingDidBegin
* UIControlEventEditingChanged
* UIControlEventEditingDidEnd

> 其他一些非必须的 event 已被忽略。
> Some other non-essential events have been ignored.

使用示例（Case）:

``` Objective-C
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    WLUnitField *uniField = [[WLUnitField alloc] initWithInputUnitCount:4];
    uniField.frame = CGRectMake(40, 40, 240, 1);
    uniField.delegate = self;
    uniField.unitSpace = 12;
    uniField.borderRadius = 4;
    [uniField sizeToFit];
    [uniField addTarget:self action:@selector(unitFieldEditingChanged:) forControlEvents:UIControlEventEditingChanged];
    
    [self.view addSubview:uniField];
}

- (IBAction)unitFieldEditingChanged:(WLUnitField *)sender {
     NSLog(@"%s, %@", __FUNCTION__, sender.text);
}
```

# License
MIT License
