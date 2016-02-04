//
//  IGCollectionViewCell.m
//  T_CollectionMoveable
//
//  Created by GavinHe on 16/2/4.
//  Copyright © 2016年 GavinHe. All rights reserved.
//

#import "CollectionViewCell.h"

@implementation CollectionViewCell

- (instancetype)init
{
    return [self initWithFrame:CGRectZero];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self buildUI];
    }
    return self;
}


-(void)layoutSubviews{
    [super layoutSubviews];
    [self layoutSelf];
}

-(void)buildUI{
    self.backgroundColor = [UIColor whiteColor];
    
    _label               = [[UILabel alloc] init];
    _label.frame         = self.bounds;
    _label.textAlignment = NSTextAlignmentCenter;
    [self addSubview:_label];
    
}

-(void)layoutSelf{
    _label.frame         = self.bounds;    
}

@end
