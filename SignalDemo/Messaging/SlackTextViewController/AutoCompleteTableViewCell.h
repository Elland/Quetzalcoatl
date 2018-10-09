//
//  MessageTableViewCell.h
//  Messenger
//
//  Created by Ignacio Romero Zurbuchen on 9/1/14.
//  Copyright (c) 2014 Slack Technologies, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AutoCompleteTableViewCell : UITableViewCell

@property (nonatomic, strong, nonnull) UILabel *titleLabel;
@property (nonatomic, strong, nonnull) UILabel *bodyLabel;
@property (nonatomic, strong, nonnull) UIImageView *thumbnailView;

@property (nonatomic, strong, nonnull) NSIndexPath *indexPath;

+ (CGFloat)defaultFontSize;

@end
