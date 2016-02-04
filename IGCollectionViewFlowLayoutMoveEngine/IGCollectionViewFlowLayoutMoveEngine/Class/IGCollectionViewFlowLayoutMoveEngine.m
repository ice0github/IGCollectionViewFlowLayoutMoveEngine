//
//  IGFlowCollectionViewMoveDelegate.m
//  T_CollectionMoveable
//
//  Created by GavinHe on 16/2/4.
//  Copyright © 2016年 GavinHe. All rights reserved.
//

#import "IGCollectionViewFlowLayoutMoveEngine.h"


typedef NS_ENUM(NSInteger, IGMoveDirction) {
    IGMoveDirctionNone,
    IGMoveDirctionUp,
    IGMoveDirctionDown
};


@interface IGCollectionViewFlowLayoutMoveEngine ()<UIGestureRecognizerDelegate>

@property (nonatomic, weak  ) UICollectionView             *collectionView;

@property (nonatomic, strong) UIPanGestureRecognizer       *panGesture;
@property (nonatomic, strong) UILongPressGestureRecognizer *longPressGesture;

@property (nonatomic, strong) CADisplayLink                *displayLink;

@property (nonatomic, strong) UIView                       *cellFakeView;
@property (nonatomic, assign) NSIndexPath                  *reorderingCellIndexPath;

@property (nonatomic, assign) CGPoint                      reorderingCellCenter;
@property (nonatomic, assign) CGPoint                      cellFakeViewCenter;
@property (nonatomic, assign) CGPoint                      panTranslation;

@property (nonatomic, assign) IGMoveDirction               moveDirction;

@end

@implementation IGCollectionViewFlowLayoutMoveEngine

- (instancetype)initWithCollectionView:(UICollectionView*)cv{
    self = [super init];
    if (self) {
        [self setupWithCollectionView:cv];
    }
    return self;

}

- (void)setupWithCollectionView:(UICollectionView*)cv{
    [self clean];
    
    _collectionView = cv;
    
    [self setupGesture];
}

- (void)clean{
    if (_collectionView) {
        [self cleanGesture];
        [self invalidateDisplayLink];

        _collectionView = nil;
    }
    
    if (_cellFakeView) {
        [_cellFakeView removeFromSuperview];
        _cellFakeView = nil;
    }
    
    _reorderingCellIndexPath = nil;
    
    _reorderingCellCenter = CGPointZero;
    _cellFakeViewCenter   = CGPointZero;
    _panTranslation       = CGPointZero;
    
    _scrollTrigePadding     = UIEdgeInsetsZero;
    _scrollTrigerEdgeInsets = UIEdgeInsetsZero;
    
}

#pragma mark - DisplayLink
- (void)setupDisplayLink{
    if (_displayLink) {
        return;
    }
    
    _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(autoScroll)];
    [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

-  (void)invalidateDisplayLink{
    [_displayLink invalidate];
    _displayLink = nil;
}

- (void)autoScroll{
    CGPoint contentOffset     = _collectionView.contentOffset;
    UIEdgeInsets contentInset = _collectionView.contentInset;
    CGSize contentSize        = _collectionView.contentSize;
    CGSize boundsSize         = _collectionView.bounds.size;
    CGFloat increment         = 0;
    
    if (_moveDirction == IGMoveDirctionDown) {
        CGFloat percentage = (((CGRectGetMaxY(_cellFakeView.frame) - contentOffset.y) - (boundsSize.height - _scrollTrigerEdgeInsets.bottom - _scrollTrigePadding.bottom)) / _scrollTrigerEdgeInsets.bottom);
        increment = 10 * percentage;
        if (increment >= 10.f) {
            increment = 10.f;
        }
    }else if (_moveDirction == IGMoveDirctionUp) {
        CGFloat percentage = (1.f - ((CGRectGetMinY(_cellFakeView.frame) - contentOffset.y - _scrollTrigePadding.top) / _scrollTrigerEdgeInsets.top));
        increment = -10.f * percentage;
        if (increment <= -10.f) {
            increment = -10.f;
        }
    }
    
    if (contentOffset.y + increment <= -contentInset.top) {
        [UIView animateWithDuration:.07f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            CGFloat diff = -contentInset.top - contentOffset.y;
            _collectionView.contentOffset = CGPointMake(contentOffset.x, -contentInset.top);
            _cellFakeViewCenter = CGPointMake(_cellFakeViewCenter.x, _cellFakeViewCenter.y + diff);
            _cellFakeView.center = CGPointMake(_cellFakeViewCenter.x + _panTranslation.x, _cellFakeViewCenter.y + _panTranslation.y);
        } completion:nil];
        [self invalidateDisplayLink];
        return;
    }else if (contentOffset.y + increment >= contentSize.height - boundsSize.height - contentInset.bottom) {
        [UIView animateWithDuration:.07f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            CGFloat diff = contentSize.height - boundsSize.height - contentInset.bottom - contentOffset.y;
            _collectionView.contentOffset = CGPointMake(contentOffset.x, contentSize.height - boundsSize.height - contentInset.bottom);
            _cellFakeViewCenter = CGPointMake(_cellFakeViewCenter.x, _cellFakeViewCenter.y + diff);
            _cellFakeView.center = CGPointMake(_cellFakeViewCenter.x + _panTranslation.x, _cellFakeViewCenter.y + _panTranslation.y);
        } completion:nil];
        [self invalidateDisplayLink];
        return;
    }
    
    [_collectionView performBatchUpdates:^{
        _cellFakeViewCenter = CGPointMake(_cellFakeViewCenter.x, _cellFakeViewCenter.y + increment);
        _cellFakeView.center = CGPointMake(_cellFakeViewCenter.x + _panTranslation.x, _cellFakeViewCenter.y + _panTranslation.y);
        _collectionView.contentOffset = CGPointMake(contentOffset.x, contentOffset.y + increment);
    } completion:nil];
    [self moveItemIfNeeded];

}

#pragma mark - ----> Setup Gesture
- (void)setupGesture{
    if (!_longPressGesture) {
        _longPressGesture          = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressGesture:)];
        _longPressGesture.delegate = self;
    }

    if (!_panGesture) {
        _panGesture          = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
        _panGesture.delegate = self;
    }

    if (_collectionView) {
        for (UIGestureRecognizer *gestureRecognizer in _collectionView.gestureRecognizers) {
            if ([gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]]) {
                [gestureRecognizer requireGestureRecognizerToFail:_longPressGesture]; }}
        [_collectionView addGestureRecognizer:_longPressGesture];
        [_collectionView addGestureRecognizer:_panGesture];
    }
}

- (void)cleanGesture{
    if (_longPressGesture) {
        [_collectionView removeGestureRecognizer:_longPressGesture];
        _longPressGesture = nil;
    }
    
    if (_panGesture) {
        [_collectionView removeGestureRecognizer:_panGesture];
        _panGesture = nil;
    }
}


#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if ([_panGesture isEqual:gestureRecognizer]) {
        if (_longPressGesture.state == 0 || _longPressGesture.state == 5) {
            return NO;
        }
    }else if ([_longPressGesture isEqual:gestureRecognizer]) {
        if (_collectionView.panGestureRecognizer.state != 0 && _collectionView.panGestureRecognizer.state != 5) {
            return NO;
        }
    }
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if ([_panGesture isEqual:gestureRecognizer]) {
        if (_longPressGesture.state != 0 && _longPressGesture.state != 5) {
            if ([_longPressGesture isEqual:otherGestureRecognizer]) {
                return YES;
            }
            return NO;
        }
    }else if ([_longPressGesture isEqual:gestureRecognizer]) {
        if ([_panGesture isEqual:otherGestureRecognizer]) {
            return YES;
        }
    }else if ([_collectionView.panGestureRecognizer isEqual:gestureRecognizer]) {
        if (_longPressGesture.state == 0 || _longPressGesture.state == 5) {
            return NO;
        }
    }
    return YES;
}

#pragma mark - ----> Gesture Action

- (void)handleLongPressGesture:(UILongPressGestureRecognizer*)longPress{
    switch (longPress.state) {
        case UIGestureRecognizerStateBegan: {

            NSIndexPath *indexPath = [_collectionView indexPathForItemAtPoint:[longPress locationInView:_collectionView]];

            if (!indexPath) {
                return;
            }
            if (_moveDelegate &&
                [_moveDelegate respondsToSelector:@selector(collectionView:canMoveItemAtIndexPath:)]
                && ![_moveDelegate collectionView:_collectionView canMoveItemAtIndexPath:indexPath]) {
                return;
            }
            
            _reorderingCellIndexPath     = indexPath;

            _collectionView.scrollsToTop = NO;

            UICollectionViewCell *cell = [_collectionView cellForItemAtIndexPath:indexPath];
            
            _cellFakeView                         = [[UIView alloc] initWithFrame:cell.frame];
            _cellFakeView.layer.shadowColor       = [UIColor blackColor].CGColor;
            _cellFakeView.layer.shadowOffset      = CGSizeMake(0, 0);
            _cellFakeView.layer.shadowOpacity     = .5f;
            _cellFakeView.layer.shadowRadius      = 3.f;
            
            UIImageView *cellFakeImageView        = [[UIImageView alloc] initWithFrame:cell.bounds];
            UIImageView *highlightedImageView     = [[UIImageView alloc] initWithFrame:cell.bounds];

            cellFakeImageView.contentMode         = UIViewContentModeScaleAspectFill;
            highlightedImageView.contentMode      = UIViewContentModeScaleAspectFill;
            
            cellFakeImageView.autoresizingMask    = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
            highlightedImageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
            
            cell.highlighted                      = YES;
            [self setCellCopiedImage:cell toImageView:highlightedImageView];
            
            cell.highlighted                      = NO;
            [self setCellCopiedImage:cell toImageView:cellFakeImageView];
            
            
            [_cellFakeView addSubview:cellFakeImageView];
            [_cellFakeView addSubview:highlightedImageView];
            
            cell.hidden = YES;
            
            [_collectionView addSubview:_cellFakeView];
            
            _reorderingCellCenter = cell.center;
            _cellFakeViewCenter   = _cellFakeView.center;
            [_collectionView.collectionViewLayout invalidateLayout];
            
            CGSize itemSize = CGSizeEqualToSize(_itemSizeWhenMoving, CGSizeZero)?cell.bounds.size:_itemSizeWhenMoving;
            CGRect fakeViewRect = CGRectMake(cell.center.x - (itemSize.width / 2.f), cell.center.y - (itemSize.height / 2.f), itemSize.width, itemSize.height);
            [UIView animateWithDuration:.3f delay:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut animations:^{
                _cellFakeView.center       = cell.center;
                _cellFakeView.frame        = fakeViewRect;
                _cellFakeView.transform    = CGAffineTransformMakeScale(1.1f, 1.1f);
                highlightedImageView.alpha = 0;
            } completion:^(BOOL finished) {
                [highlightedImageView removeFromSuperview];
            }];
            break;
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled: {
            NSIndexPath *currentCellIndexPath = _reorderingCellIndexPath;

            _collectionView.scrollsToTop = YES;

            [self invalidateDisplayLink];
            
            UICollectionViewLayoutAttributes *attributes = [self layoutAttributesForItemAtIndexPath:currentCellIndexPath];
            [UIView animateWithDuration:.3f delay:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut animations:^{
                _cellFakeView.transform = CGAffineTransformIdentity;
                _cellFakeView.frame     = attributes.frame;
                
            } completion:^(BOOL finished) {
                UICollectionViewCell *cell = [_collectionView cellForItemAtIndexPath:currentCellIndexPath];
                if (cell) {
                    cell.hidden = NO;
                }
                
                [_cellFakeView removeFromSuperview];
                _cellFakeView            = nil;
                _reorderingCellIndexPath = nil;
                _reorderingCellCenter    = CGPointZero;
                _cellFakeViewCenter      = CGPointZero;
                
                [_collectionView.collectionViewLayout invalidateLayout];
            }];
            break;
        }
        default:
            break;
    }
    
}

- (void)handlePanGesture:(UIPanGestureRecognizer *)pan
{
    switch (pan.state) {
        case UIGestureRecognizerStateChanged: {
            _panTranslation = [pan translationInView:_collectionView];
            _cellFakeView.center = CGPointMake(_cellFakeViewCenter.x + _panTranslation.x, _cellFakeViewCenter.y + _panTranslation.y);

            [self moveItemIfNeeded];

            if (CGRectGetMaxY(_cellFakeView.frame) >= _collectionView.contentOffset.y + (_collectionView.bounds.size.height - _scrollTrigerEdgeInsets.bottom -_scrollTrigePadding.bottom)) {
                if (ceilf(_collectionView.contentOffset.y) < _collectionView.contentSize.height - _collectionView.bounds.size.height) {
                    _moveDirction = IGMoveDirctionDown;
                    [self setupDisplayLink];
                }
            }else if (CGRectGetMinY(_cellFakeView.frame) <= _collectionView.contentOffset.y + _scrollTrigerEdgeInsets.top + _scrollTrigePadding.top) {
                if (_collectionView.contentOffset.y > -_collectionView.contentInset.top) {
                    _moveDirction = IGMoveDirctionUp;
                    [self setupDisplayLink];
                }
            }else {
                _moveDirction = IGMoveDirctionNone;
                [self invalidateDisplayLink];
            }
            break;
        }
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateEnded:
            [self invalidateDisplayLink];
            break;
        default:
            break;
    }
}
#pragma mark - ----> Collection View

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath{
    UICollectionViewLayoutAttributes *attribute = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    UICollectionViewCell *cell = [_collectionView cellForItemAtIndexPath:indexPath];
    attribute.frame = cell.frame;
    attribute.alpha = 0;
    return attribute;
}

- (void)moveItemIfNeeded
{
    NSIndexPath *atIndexPath = _reorderingCellIndexPath;
    NSIndexPath *toIndexPath = [_collectionView indexPathForItemAtPoint:_cellFakeView.center];
    
    if (!toIndexPath) {
        return;
    }
    
    if (_moveDelegate &&
        [_moveDelegate respondsToSelector:@selector(collectionView:itemAtIndexPath:canMoveToIndexPath:)] &&
        ![_moveDelegate collectionView:_collectionView
                        itemAtIndexPath:atIndexPath
                     canMoveToIndexPath:toIndexPath]) {
        return;
    }
    
    if (_moveDelegate &&
        [_moveDelegate respondsToSelector:@selector(collectionView:itemAtIndexPath:willMoveToIndexPath:)]) {
        [_moveDelegate collectionView:_collectionView itemAtIndexPath:atIndexPath willMoveToIndexPath:toIndexPath];
    }
    
    [_collectionView performBatchUpdates:^{
        _reorderingCellIndexPath = toIndexPath;
        [_collectionView moveItemAtIndexPath:atIndexPath toIndexPath:toIndexPath];

        if (_moveDelegate &&
            [_moveDelegate respondsToSelector:@selector(collectionView:itemAtIndexPath:didMoveToIndexPath:)]) {
            [_moveDelegate collectionView:_collectionView itemAtIndexPath:atIndexPath didMoveToIndexPath:toIndexPath];
        }
    } completion:nil];
}

#pragma mark - ----> Tools
- (void)setCellCopiedImage:(UICollectionViewCell *)cell toImageView:(UIImageView*)iv{
    UIGraphicsBeginImageContextWithOptions(cell.bounds.size, NO, 4.f);
    [cell.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    iv.image = image;
}


@end
