#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <UIKit/UITextInput.h>
#import <UIKit/UILongPressGestureRecognizer.h>
#import <UIKit/UITableView.h>
#import <UIKit/UIAlertView.h>
#import <UIKit/UIGestureRecognizer.h>
#import <UIKit/UIViewController.h>
#import <UIKit/UIActionSheet.h>


NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
NSString *documentsDirectory = [paths objectAtIndex:0];

NSString *mutePath = [documentsDirectory stringByAppendingPathComponent:@"muted.plist"];
NSString *namePath = [documentsDirectory stringByAppendingPathComponent:@"names.plist"];

NSMutableDictionary *muted = [[NSFileManager defaultManager] fileExistsAtPath:mutePath] ? 
                            [NSMutableDictionary dictionaryWithContentsOfFile:mutePath] :
                            [[NSMutableDictionary alloc] init];

// NSMutableDictionary *names = [[NSFileManager defaultManager] fileExistsAtPath:namePath] ? 
//                             [NSMutableDictionary dictionaryWithContentsOfFile:namePath] :
//                             [[NSMutableDictionary alloc] init];





@interface CKConversationListCell : UITableViewCell <UIActionSheetDelegate, UIAlertViewDelegate>
{
    UILabel *_fromLabel;
}
- (void)showActionSheet:(UILongPressGestureRecognizer *)gesture;
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex;
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;
@end

UILabel *fromLabel;

%hook CKConversationListCell
- (id)initWithStyle:(long long)arg1 reuseIdentifier:(id)arg2 {
    id orig = %orig;
    if(orig) {
        fromLabel = MSHookIvar<UILabel *>(self, "_fromLabel");
        // if([names objectForKey:fromLabel.text]) {
        //     fromLabel.text = [names objectForKey:fromLabel.text];
        // }
        UILongPressGestureRecognizer *longPressGesture =
                                [[[UILongPressGestureRecognizer alloc]
                                initWithTarget:self action:@selector(showActionSheet:)] autorelease];
        [self addGestureRecognizer:longPressGesture];
    }
    return orig;

}

%new
-(void)showActionSheet:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {

        fromLabel = MSHookIvar<UILabel *>(self, "_fromLabel");

        NSString *actionSheetTitle = fromLabel.text; //Action Sheet Title
        //NSString *destructiveTitle = @"Destructive Button"; //Action Sheet Button Titles
        NSString *mute = [muted objectForKey:fromLabel.text] ? @"Unmute" : @"Mute";
        //NSString *name = [names objectForKey:fromLabel.text] ? @"Revert Name" : @"Rename";
        //NSString *other3 = @"Other Button 3";
        NSString *cancelTitle = @"Cancel";

        UIActionSheet *actionSheet = [[UIActionSheet alloc]
                                       initWithTitle:actionSheetTitle
                                       delegate:self
                                       cancelButtonTitle:cancelTitle
                                       destructiveButtonTitle:mute
                                       otherButtonTitles:nil, nil, nil, nil];

       [actionSheet showInView:gesture.view];
    }
}

%new
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    if ([buttonTitle isEqualToString:@"Mute"]) {
        NSLog(@"mute pressed");

        fromLabel = MSHookIvar<UILabel *>(self, "_fromLabel");
        [muted setObject:@"true" forKey:fromLabel.text];
        [muted writeToFile:mutePath atomically:YES];

    }
    if ([buttonTitle isEqualToString:@"Rename"]) {
        NSLog(@"rename pressed");
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Set Name To" 
                                                         message:nil 
                                                        delegate:self 
                                               cancelButtonTitle:@"Cancel" 
                                               otherButtonTitles:@"Save", @"Restore", nil];
        alert.alertViewStyle = UIAlertViewStylePlainTextInput;
        [alert show];
    }
    if ([buttonTitle isEqualToString:@"Unmute"]) {
        NSLog(@"Unmute pressed");
        fromLabel = MSHookIvar<UILabel *>(self, "_fromLabel");
        [muted removeObjectForKey:fromLabel.text];
        [muted writeToFile:mutePath atomically:YES];
    }
    if ([buttonTitle isEqualToString:@"Cancel Button"]) {
        NSLog(@"Cancel pressed --> Cancel ActionSheet");
    }
}

%new
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
    if([title isEqualToString:@"Save"])
    {
        UITextField *textfield = [alertView textFieldAtIndex: 0];

        fromLabel = MSHookIvar<UILabel *>(self, "_fromLabel");

        // [names setObject:textfield.text forKey:fromLabel.text];
        // [names writeToFile:namePath atomically:YES];

        fromLabel.text = textfield.text;
        
    }
    else if([title isEqualToString:@"Button 2"])
    {
        NSLog(@"Button 2 was selected.");
    }
    else if([title isEqualToString:@"Button 3"])
    {
        NSLog(@"Button 3 was selected.");
    }
}

%end


@interface CKConversation : NSObject
{
    NSArray *_recipients;
    NSString *_name;
}
@property(retain, nonatomic) NSArray *recipients; // @synthesize recipients=_recipients;
@property(readonly, nonatomic) NSString *name; // @dynamic name;
@end

@interface CKIMMessage : NSObject 
{
    CKConversation *_conversation;
    struct {
        unsigned int hasPostedComplete:1;
        unsigned int shouldPlayReceivedTone:1;
        unsigned int isPlaceHolderDate:1;
    } _messageFlags;
}
//@property(nonatomic) CKConversation *conversation; // @synthesize conversation=_conversation;
@property(readonly, nonatomic) _Bool shouldPlayReceivedTone;
@end

CKConversation *convo;

%hook CKIMMessage
-(_Bool) shouldPlayReceivedTone {
    convo = MSHookIvar<CKConversation *>(self, "_conversation");
    if([muted objectForKey:convo.name]) {
        return FALSE;
    }

    return %orig;
}
%end
