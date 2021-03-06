//
//  HRPGGroupAboutTableViewController.m
//  Habitica
//
//  Created by Phillip Thelen on 16/02/16.
//  Copyright © 2016 Phillip Thelen. All rights reserved.
//

#import "HRPGGroupAboutTableViewController.h"
#import "Group.h"
#import "UIViewController+Markdown.h"
#import <DTAttributedTextView.h>
#import "HRPGGroupFormViewController.h"
#import "HRPGGroupTableViewController.h"
#import "UIColor+Habitica.h"
#import "HRPGProfileViewController.h"

@interface HRPGGroupAboutTableViewController ()
@property NSString *replyMessage;
@property DTAttributedTextView *sizeTextView;
@property NSMutableDictionary *attributes;

@end

@implementation HRPGGroupAboutTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.clearsSelectionOnViewWillAppear = NO;
    self.sizeTextView = [[DTAttributedTextView alloc] init];
    [self configureMarkdownAttributes];
    
    [self setupBarButton];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) setupBarButton {
    UIBarButtonItem *barButton;
    if (self.isLeader) {
        barButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(openGroupForm)];
    } else {
        if ([self.group.isMember boolValue] || [self.group.type isEqualToString:@"party"]) {
            barButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Leave", nil) style:UIBarButtonItemStylePlain target:self action:@selector(leaveGroup)];
            barButton.tintColor = [UIColor red50];
        } else {
            barButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Join", nil) style:UIBarButtonItemStylePlain target:self action:@selector(joinGroup)];
            barButton.tintColor = [UIColor green50];
        }
    }
    self.navigationItem.rightBarButtonItem = barButton;
}

- (void) openGroupForm {
    [self performSegueWithIdentifier:@"GroupFormSegue" sender:self];
}

- (void) leaveGroup {
    if ([UIAlertController class]) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Are you sure?", nil) message:nil preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Go Back", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        }];
        [alertController addAction:cancelAction];
        
        UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Leave Group", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self alertView:nil clickedButtonAtIndex:1];
        }];
        [alertController addAction:confirmAction];
        
        [self presentViewController:alertController animated:YES completion:^() {
        }];
    } else {
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Are you sure?", nil)
                                                          message:nil
                                                         delegate:self
                                                cancelButtonTitle:NSLocalizedString(@"Leave Group", nil)
                                                otherButtonTitles:nil];
        
        [message addButtonWithTitle:NSLocalizedString(@"Opt-Out", nil)];
        [message show];
    }
}

- (void)joinGroup {
    [self.sharedManager joinGroup:self.group.id withType:self.group.type onSuccess:^() {
        self.navigationItem.rightBarButtonItem = nil;
    } onError:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([self.group.type isEqualToString:@"guild"]) {
        return 3;
    } else {
        return 2;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.item == 0) {
        self.sizeTextView.attributedString = [self renderMarkdown:self.group.hdescription];
        CGSize suggestedSize = [self.sizeTextView.attributedTextContentView suggestedFrameSizeToFitEntireStringConstraintedToWidth:self.viewWidth-24];
        CGFloat rowHeight = suggestedSize.height+24;
        return rowHeight;
    } else {
        return [super tableView:tableView heightForRowAtIndexPath:indexPath];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    if (indexPath.item == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
        cell.textLabel.attributedText = [self renderMarkdown:self.group.hdescription];
    } else if (indexPath.item == 1) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"RightDetailCell" forIndexPath:indexPath];
        cell.textLabel.text = NSLocalizedString(@"Leader", nil);
        cell.detailTextLabel.text = self.group.leader.username;
    } else if (indexPath.item == 2) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"RightDetailCell" forIndexPath:indexPath];
        cell.textLabel.text = NSLocalizedString(@"Gems", nil);
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%.0f", [self.group.balance floatValue]*4];
    } else if (indexPath.item == 3) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"RightDetailCell" forIndexPath:indexPath];
        cell.textLabel.text = NSLocalizedString(@"Visibility", nil);
        cell.detailTextLabel.text = [self.group.privacy localizedCapitalizedString];
    }
    return cell;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"GroupFormSegue"]) {
            UINavigationController *navigationController = (UINavigationController*)segue.destinationViewController;
            HRPGGroupFormViewController *groupFormController = (HRPGGroupFormViewController *) navigationController.topViewController;
            groupFormController.editGroup = YES;
            groupFormController.group = self.group;
    }
}

- (IBAction)unwindToList:(UIStoryboardSegue *)segue {
}

- (IBAction)unwindToListSave:(UIStoryboardSegue *)segue {
    HRPGGroupFormViewController *formViewController = (HRPGGroupFormViewController *) segue.sourceViewController;
    [self.sharedManager updateGroup:formViewController.group onSuccess:^() {
        if ([self.presentingViewController.class isSubclassOfClass:HRPGGroupTableViewController.class]) {
            HRPGGroupTableViewController *vc = (HRPGGroupTableViewController *) self.presentingViewController;
            [vc fetchGroup];
            self.group = vc.group;
        }
    } onError:nil];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [self.sharedManager leaveGroup:self.group withType:self.group.type onSuccess:^() {
            for (UIViewController *aViewController in [NSMutableArray arrayWithArray:[self.navigationController viewControllers]]) {
                if ([aViewController isKindOfClass:[HRPGProfileViewController class]]) {
                    [self.navigationController popToViewController:aViewController animated:NO];
                }
            }
        }onError:nil];
    }
}

@end
