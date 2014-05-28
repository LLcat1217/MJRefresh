//
//  MJRefreshHeaderView.m
//  MJRefresh
//
//  Created by mj on 13-2-26.
//  Copyright (c) 2013年 itcast. All rights reserved.
//  下拉刷新

#import "MJRefreshConst.h"
#import "MJRefreshHeaderView.h"

@interface MJRefreshHeaderView()
// 最后的更新时间
@property (nonatomic, strong) NSDate *lastUpdateTime;
@end

@implementation MJRefreshHeaderView

+ (instancetype)header
{
    return [[MJRefreshHeaderView alloc] init];
}

#pragma mark - UIScrollView相关
#pragma mark 重写设置ScrollView
- (void)setScrollView:(UIScrollView *)scrollView
{
    [super setScrollView:scrollView];
    
    // 1.设置边框
    self.frame = CGRectMake(0, - MJRefreshViewHeight, scrollView.frame.size.width, MJRefreshViewHeight);
    
    // 2.加载时间
    self.lastUpdateTime = [[NSUserDefaults standardUserDefaults] objectForKey:MJRefreshHeaderTimeKey];
}

#pragma mark - 状态相关
#pragma mark 设置最后的更新时间
- (void)setLastUpdateTime:(NSDate *)lastUpdateTime
{
    _lastUpdateTime = lastUpdateTime;
    
    // 1.归档
    [[NSUserDefaults standardUserDefaults] setObject:lastUpdateTime forKey:MJRefreshHeaderTimeKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // 2.更新时间
    [self updateTimeLabel];
}

#pragma mark 更新时间字符串
- (void)updateTimeLabel
{
    if (!self.lastUpdateTime) return;
    
    // 1.获得年月日
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSUInteger unitFlags = NSYearCalendarUnit| NSMonthCalendarUnit | NSDayCalendarUnit |NSHourCalendarUnit |NSMinuteCalendarUnit;
    NSDateComponents *cmp1 = [calendar components:unitFlags fromDate:_lastUpdateTime];
    NSDateComponents *cmp2 = [calendar components:unitFlags fromDate:[NSDate date]];
    
    // 2.格式化日期
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    if ([cmp1 day] == [cmp2 day]) { // 今天
        formatter.dateFormat = @"今天 HH:mm";
    } else if ([cmp1 year] == [cmp2 year]) { // 今年
        formatter.dateFormat = @"MM-dd HH:mm";
    } else {
        formatter.dateFormat = @"yyyy-MM-dd HH:mm";
    }
    NSString *time = [formatter stringFromDate:self.lastUpdateTime];
    
    // 3.显示日期
    self.lastUpdateTimeLabel.text = [NSString stringWithFormat:@"最后更新：%@", time];
}

#pragma mark 设置状态
- (void)setState:(MJRefreshState)state
{
    // 1.一样的就直接返回
    if (self.state == state) return;
    
    // 2.保存旧状态
    MJRefreshState oldState = self.state;
    
    // 3.调用父类方法
    [super setState:state];
    
    // 4.根据状态执行不同的操作
	switch (state) {
		case MJRefreshStatePulling: // 松开可立即刷新
        {
            // 设置文字
            self.statusLabel.text = MJRefreshHeaderReleaseToRefresh;
            // 执行动画
            [UIView animateWithDuration:MJRefreshAnimationDuration animations:^{
                self.arrowImage.transform = CGAffineTransformMakeRotation(M_PI);
                UIEdgeInsets inset = self.scrollView.contentInset;
                inset.top = self.scrollViewInitInset.top;
                self.scrollView.contentInset = inset;
            }];
			break;
        }
            
		case MJRefreshStateNormal: // 下拉可以刷新
        {
            // 设置文字
			self.statusLabel.text = MJRefreshHeaderPullToRefresh;
            // 执行动画
            [UIView animateWithDuration:MJRefreshAnimationDuration animations:^{
                self.arrowImage.transform = CGAffineTransformIdentity;
                UIEdgeInsets inset = self.scrollView.contentInset;
                inset.top = self.scrollViewInitInset.top;
                self.scrollView.contentInset = inset;
            }];
            
            // 刷新完毕
            if (MJRefreshStateRefreshing == oldState) {
                // 保存刷新时间
                self.lastUpdateTime = [NSDate date];
            }
			break;
        }
            
		case MJRefreshStateRefreshing: // 正在刷新中
        {
            // 设置文字
            self.statusLabel.text = MJRefreshHeaderRefreshing;
            // 执行动画
            [UIView animateWithDuration:MJRefreshAnimationDuration animations:^{
                self.arrowImage.transform = CGAffineTransformIdentity;
                // 1.增加65的滚动区域
                UIEdgeInsets inset = self.scrollView.contentInset;
                inset.top = self.scrollViewInitInset.top + MJRefreshViewHeight;
                self.scrollView.contentInset = inset;
                // 2.设置滚动位置
                self.scrollView.contentOffset = CGPointMake(0, - self.scrollViewInitInset.top - MJRefreshViewHeight);
            }];
            
            // 通知代理
            if ([self.delegate respondsToSelector:@selector(refreshHeaderViewBeginRefreshing:)]) {
                [self.delegate refreshHeaderViewBeginRefreshing:self];
            }
            
            // 回调
            if (self.beginRefreshingCallback) {
                self.beginRefreshingCallback(self);
            }
			break;
        }
            
        default:
            break;
	}
}

#pragma mark - 在父类中用得上
// 合理的Y值(刚好看到下拉刷新控件时的contentOffset.y，取相反数)
- (CGFloat)validY
{
    return self.scrollViewInitInset.top;
}

// view的类型
- (int)viewType
{
    return MJRefreshViewTypeHeader;
}
@end