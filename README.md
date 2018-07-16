# WLUnitField

https://github.com/zhwayne/WLUnitField

这是一个优雅简洁的密码/验证码输入框，你可以像使用`UITextField`一样去使用`WLUnitField`。

![](./demo.gif)


## 使用

`WLUnitField`的使用非常简单。它继承自`UIControl`，你可以给它添加以下 3 种`UIControlEvent`：
* UIControlEventEditingDidBegin
* UIControlEventEditingChanged
* UIControlEventEditingDidEnd

其他一些非必须的 event 已被忽略。

使用示例:

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

## License
MIT License
