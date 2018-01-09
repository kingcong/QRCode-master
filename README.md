# QRCode-master
仿微信二维码扫描

##最近有时间研究下iOS下的二维码扫描，以前是用ZBar做扫描的，现在用系统原生的AVFoundation框架也可以做到了，下面分享一下自己的实现过程：
### 1.首先演示一下具体效果：
![演示地址](http://o8847agtd.bkt.clouddn.com/gif1.gif)
### 2. 下面说一下实现过程：
. 1 首先需要创建二维码扫描对象

``` objc 
// 显示扫描后的结果
@property (weak, nonatomic) IBOutlet UILabel *resultLab;

// 高度约束
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *containerHeightCons;

// 扫描线
@property (weak, nonatomic) IBOutlet UIImageView *scanLineView;

// 扫描线的约束，这里很重要，动画效果主要是根据设置这个的值实现的
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *scanLineCons;

// 自定义ToolBar
@property (weak, nonatomic) IBOutlet UITabBar *customTabBar;

// 会话
@property (nonatomic, strong) AVCaptureSession *session;

// 输入设备
@property (nonatomic, strong) AVCaptureDeviceInput *deviceInput;

// 输出设备
@property (nonatomic, strong) AVCaptureMetadataOutput *output;

// 预览图层
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;

// 会话图层
@property (nonatomic, strong) CALayer *drawLayer;
```
. 2 然后对这些对象进行懒加载：

``` objc
#pragma mark - 懒加载
// 会话
- (AVCaptureSession *)session
{
    if (_session == nil) {
        _session = [[AVCaptureSession alloc] init];
    }
    return _session;
}
// 拿到输入设备
- (AVCaptureDeviceInput *)deviceInput
{
    if (_deviceInput == nil) {
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        
        _deviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:device error:nil];
    }
    return _deviceInput;
}
// 拿到输出对象
- (AVCaptureMetadataOutput *)output
{
    if (_output == nil) {
        _output = [[AVCaptureMetadataOutput alloc] init];
    }
    return _output;
}
// 创建预览图层
- (AVCaptureVideoPreviewLayer *)previewLayer
{
    if (_previewLayer == nil) {
        _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
        _previewLayer.frame = [UIScreen mainScreen].bounds;
    }
    return _previewLayer;
}
// 创建用于绘制边线的图层
- (CALayer *)drawLayer
{
    if (_drawLayer == nil) {
        _drawLayer = [[CALayer alloc] init];
        _drawLayer.frame = [UIScreen mainScreen].bounds;
    }
    return _drawLayer;
}

```

. 3 创建完对象之后，我们先实现二维码扫描的动态效果，然后再去执行扫描二维码的操作：

``` objc 
// 这里主要是通过设置约束，让扫描线不停的执行动画
- (void)startAnimation
{
    // 让约束从顶部开始
    self.scanLineCons.constant = 0;
    [self.view layoutIfNeeded];

    // 设置动画指定的次数

    [UIView animateWithDuration:2.0 animations:^{
        // 1.修改约束
        self.scanLineCons.constant = self.containerHeightCons.constant;
        
        [UIView setAnimationRepeatCount:MAXFLOAT];
        
        // 2.强制更新界面
        [self.view layoutIfNeeded];
    }];
}

```

. 4 动画实现之后，看了微信的二维码扫描之后，发现下面有个toolbar，可以扫描不同的类型，不同类型需要改变扫描View的高度，实现过程如下

``` objc
/**
 *  选择tabBar时进行跳转
 *
 *  @param tabBar tabbar
 *  @param item   tabBar的item
 */
- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
    if (item.tag == 1) {
        self.containerHeightCons.constant = 300;
    } else {
        self.containerHeightCons.constant = 150;
    }
    
    // 2.停止动画
    [self.view.layer removeAllAnimations];
    [self.scanLineView.layer removeAllAnimations];
    
    // 3.重新开始动画
    [self startAnimation];
}
```

. 4 下面是最重要的一步了，就要开始二维码扫描，这里需要判断输入输出会话是否可以正确添加，添加完成之后，需要设置二维码支持的类型，一般默认是全部，然后还需要添加预览图层：

``` objc
- (void)startScan
{
    // 1.判断是否能够将输入添加到会话中
    if (![self.session canAddInput:self.deviceInput]) {
        return;
    }
    
    // 2.判断是否能够将输出添加到会话中
    if (![self.session canAddOutput:self.output]) {
        return;
    }
    
    // 3.将输入和输出都添加到会话中
    [self.session addInput:self.deviceInput];
    
    [self.session addOutput:self.output];
    
    // 4.设置输出能够解析的数据类型
    // 注意: 设置能够解析的数据类型, 一定要在输出对象添加到会员之后设置, 否则会报错
    self.output.metadataObjectTypes = self.output.availableMetadataObjectTypes;
    [self.output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    
    // 如果想实现只扫描一张图片, 那么系统自带的二维码扫描是不支持的
    // 只能设置让二维码只有出现在某一块区域才去扫描
//    self.output.rectOfInterest = CGRectMake(0.0, 0.0, 1, 1);
    
    // 5.添加预览图层
    [self.view.layer insertSublayer:self.previewLayer atIndex:0];
    
    // 添加绘制图层
    [self.previewLayer addSublayer:self.drawLayer];
    
    // 6.告诉session开始扫描
    [self.session startRunning];
}

```

. 5 二维码扫描获得信息时，就会执行下面的代理方法，我们可以在下面的代理方法中执行我们需要执行的操作：

``` objc
/**
 *  当从二维码中获取到信息时，就会调用下面的方法
 *
 *  @param captureOutput   输出对象
 *  @param metadataObjects 信息
 *  @param connection
 */
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    // 0.清空图层
    [self clearCorners];
    
    if (metadataObjects.count == 0 || metadataObjects == nil) {
        return;
    }
    
    // 1.获取扫描到的数据
    // 注意: 要使用stringValue
    self.resultLab.text = [metadataObjects.lastObject stringValue];
    [self.resultLab sizeToFit];
    
    // 2.获取扫描到的二维码的位置
    // 2.1转换坐标
    for (AVMetadataObject *object in metadataObjects) {
        // 2.1.1判断当前获取到的数据, 是否是机器可识别的类型
        if ([object isKindOfClass:[AVMetadataMachineReadableCodeObject class]]) {
            // 2.1.2将坐标转换界面可识别的坐标
            AVMetadataMachineReadableCodeObject *codeObject = (AVMetadataMachineReadableCodeObject *)[self.previewLayer transformedMetadataObjectForMetadataObject:object];
            // 2.1.3绘制图形
            [self drawCorners:codeObject];
        }
    }
}

```

. 6 对扫描到的二维码，我们可以画出它的具体位置：

``` objc
/**
 *  画出二维码的边框
 *
 *  @param codeObject 保存了坐标的对象
 */
- (void)drawCorners:(AVMetadataMachineReadableCodeObject *)codeObject
{
    if (codeObject.corners.count == 0) {
        return;
    }
    
    // 1.创建一个图层
    CAShapeLayer *layer = [[CAShapeLayer alloc] init];
    layer.lineWidth = 4;
    layer.strokeColor = [UIColor redColor].CGColor;
    layer.fillColor = [UIColor clearColor].CGColor;
    
    // 2.创建路径
    UIBezierPath *path = [[UIBezierPath alloc] init];
    CGPoint point = CGPointZero;
    NSInteger index = 0;
    
    // 2.1移动到第一个点
    // 从corners数组中取出第0个元素, 将这个字典中的x/y赋值给point
    CGPointMakeWithDictionaryRepresentation((CFDictionaryRef)codeObject.corners[index++], &point);
    [path moveToPoint:point];
    
    // 2.2移动到其它的点
    while (index < codeObject.corners.count) {
        CGPointMakeWithDictionaryRepresentation((CFDictionaryRef)codeObject.corners[index++], &point);
        [path addLineToPoint:point];
    }
    // 2.3关闭路径
    [path closePath];
    
    // 2.4绘制路径
    layer.path = path.CGPath;
    
    // 3.将绘制好的图层添加到drawLayer上
    [self.drawLayer addSublayer:layer];
}

/**
 *  清除边线
 */
- (void)clearCorners
{
    if (self.drawLayer.sublayers == nil || self.drawLayer.sublayers.count == 0) {
        return;
    }
    
    for (CALayer *subLayer in self.drawLayer.sublayers) {
        [subLayer removeFromSuperlayer];
    }
}

```

### 3.这里面也有一些注意事项：
. 确保输入输出对象被正确的添加到会话中

. 实现动画主要是设置扫描线的顶部距离父控件的顶部的高度实现的
### 4.下面分享一下源代码：
[github地址](https://github.com/kingcong/QRCode-master)
