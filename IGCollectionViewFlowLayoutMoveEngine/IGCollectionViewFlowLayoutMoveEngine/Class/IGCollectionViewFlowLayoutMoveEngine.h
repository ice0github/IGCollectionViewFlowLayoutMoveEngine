//
//  IGFlowCollectionViewMoveDelegate.h
//  T_CollectionMoveable
//
//  Created by GavinHe on 16/2/4.
//  Copyright © 2016年 GavinHe. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <UIKit/UIKit.h>

@protocol IGCollectionViewFlowLayoutMoveDelegate <NSObject>

// 能否移动这个Item
- (BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath;

// 能否移动到某个Item
- (BOOL)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath canMoveToIndexPath:(NSIndexPath *)toIndexPath;

// 将移动到某个Item到某个位置
- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath willMoveToIndexPath:(NSIndexPath *)toIndexPath;

// 已经移动某个Item到某个位置
- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath didMoveToIndexPath:(NSIndexPath *)toIndexPath;


@end

@interface IGCollectionViewFlowLayoutMoveEngine : NSObject

@property (nonatomic, weak) id<IGCollectionViewFlowLayoutMoveDelegate> moveDelegate;

@property (nonatomic, assign) CGSize itemSizeWhenMoving;

@property (nonatomic, assign) UIEdgeInsets                 scrollTrigerEdgeInsets;

@property (nonatomic, assign) UIEdgeInsets                 scrollTrigePadding;


- (instancetype)initWithCollectionView:(UICollectionView*)cv;

- (void)setupWithCollectionView:(UICollectionView*)cv;


@end
