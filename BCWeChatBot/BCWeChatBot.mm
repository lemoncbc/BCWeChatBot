//
//  BCWeChatBot.mm
//  BCWeChatBot
//
//  Created by caobuchi on 17/5/22.
//  Copyright (c) 2017年 __MyCompanyName__. All rights reserved.
//

// CaptainHook by Ryan Petrich
// see https://github.com/rpetrich/CaptainHook/

#import <Foundation/Foundation.h>
#import "CaptainHook/CaptainHook.h"
#include <notify.h> // not required; for examples only

#define replyMsg(msg)                            Class wrapClass = NSClassFromString(@"CMessageWrap");\
CMessageWrap *wrap = [[wrapClass alloc] initWithMsgType:1];\
\
wrap.m_nsContent = msg;\
wrap.m_nsToUsr = m_nsFromUsr;\
wrap.m_nsFromUsr = m_nsUsrName;\
\
Class superClass = NSClassFromString(@"MMServiceCenter");\
SEL defaultSelecter = NSSelectorFromString(@"defaultCenter");\
id mgr = [superClass performSelector:defaultSelecter];\
\
Class mgrClass = NSClassFromString(@"CMessageMgr");\
id messageMgr = [mgr performSelector:@selector(getService:) withObject:mgrClass];\
[messageMgr performSelector:@selector(AddMsg:MsgWrap:) withObject:arg1 withObject:wrap];

// Objective-C runtime hooking using CaptainHook:
//   1. declare class using CHDeclareClass()
//   2. load class using CHLoadClass() or CHLoadLateClass() in CHConstructor
//   3. hook method using CHOptimizedMethod()
//   4. register hook using CHHook() in CHConstructor
//   5. (optionally) call old method using CHSuper()
@interface CMessageWrap : NSObject

-(id)initWithMsgType:(int)msgType;

@property(nonatomic, copy) NSString *m_nsContent;
@property(nonatomic, copy) NSString *m_nsFromUsr;
@property(nonatomic, copy) NSString *m_nsToUsr;

@end

static NSMutableDictionary *_dict;
static NSMutableDictionary *_subDict;
static NSString *_plistPath;
static BOOL canReply;


CHDeclareClass(WCDeviceStepObject);
CHMethod(0, unsigned int, WCDeviceStepObject,hkStepCount){
    
    return 99999;
}
CHDeclareClass(CMessageMgr);
CHMethod(2,void, CMessageMgr, AsyncOnAddMsg, id, arg1, MsgWrap, id, arg2){
    
    CHSuper(2,CMessageMgr,AsyncOnAddMsg, arg1, MsgWrap, arg2);
    
    Ivar uiMessageTypeIvar = class_getInstanceVariable(objc_getClass("CMessageWrap"), "m_uiMessageType");
//    ptrdiff_t offset = ivar_getOffset(uiMessageTypeIvar);
//    unsigned char *stuffBytes = (unsigned char *)(__bridge void *)arg2;
//    NSUInteger m_uiMessageType = * ((NSUInteger *)(stuffBytes + offset));
    id m_uiMessageType = object_getIvar(arg2, uiMessageTypeIvar);
    
    Ivar nsFromUsrIvar = class_getInstanceVariable(objc_getClass("CMessageWrap"), "m_nsFromUsr");
    id m_nsFromUsr = object_getIvar(arg2, nsFromUsrIvar);
    
    Ivar nsContentIvar = class_getInstanceVariable(objc_getClass("CMessageWrap"), "m_nsContent");
    id m_nsContent = object_getIvar(arg2, nsContentIvar);
    
    Method methodMMServiceCenter = class_getClassMethod(objc_getClass("MMServiceCenter"), @selector(defaultCenter));
    IMP impMMSC = method_getImplementation(methodMMServiceCenter);
    id MMServiceCenter = impMMSC(objc_getClass("MMServiceCenter"), @selector(defaultCenter));
    //通讯录管理器
    id contactManager = ((id (*)(id, SEL, Class))objc_msgSend)(MMServiceCenter, @selector(getService:),objc_getClass("CContactMgr"));
    id selfContact = objc_msgSend(contactManager, @selector(getSelfContact));
    
    Ivar nsUsrNameIvar = class_getInstanceVariable([selfContact class], "m_nsUsrName");
    id m_nsUsrName = object_getIvar(selfContact, nsUsrNameIvar);
    BOOL isMesasgeFromMe = NO;
    if ([m_nsFromUsr isEqualToString:m_nsUsrName]) {
        //发给自己的消息
        isMesasgeFromMe = YES;
    }
    
    switch ((NSInteger)m_uiMessageType) {
        case 1:
        {
            
            if (!isMesasgeFromMe) {
                
                
                NSRange range = [m_nsContent rangeOfString:@"set"];
                
                if (range.length == 0) {
                    if (canReply) {
                    
                        if ([m_nsContent isEqualToString:@"@Bot"]) {
                            replyMsg(@"不要艾特我,不存在的");
                            return;
                        }
//                        if ([m_nsContent rangeOfString:@"@"].length > 0) {
//                            replyMsg(m_nsContent);
//                            return;
//                        }
                        if (_dict[m_nsFromUsr][m_nsContent]) {
                            
                            replyMsg(_dict[m_nsFromUsr][m_nsContent]);
                            
                        } else {
                            
                            for (NSString *key in _dict.allKeys) {
                                
                                
                                if ([m_nsContent rangeOfString:key].length >0) {
                                    
                                    NSString *keyStr = [m_nsContent substringWithRange:[m_nsContent rangeOfString:key]];
                                    
                                    replyMsg(_dict[m_nsFromUsr][keyStr]);
                                    return;
                                }
                                
                            }
                        }
                    }

                    
                }else
                {
                    NSArray *botLanguageConfig = [m_nsContent componentsSeparatedByString:@" "];
                    if (botLanguageConfig.count == 3) {
                        if ([botLanguageConfig[2] isEqualToString:@"nil"]) {
                            
                            [_dict[m_nsFromUsr] removeObjectForKey:botLanguageConfig[1]];
                            
                        }else
                        {
                            NSMutableDictionary *sDict;
                            if (_dict[m_nsFromUsr]) {
                                
                                sDict = _dict[m_nsFromUsr];
                            }else
                            {
                                sDict = [[NSMutableDictionary alloc] init];
                            }
                            
                            sDict[botLanguageConfig[1]] = botLanguageConfig[2];
                            _dict[m_nsFromUsr] = sDict;
                            
                        }
                        
                        if ([_dict writeToFile:_plistPath atomically:YES]) {
                            
                            NSString *str = [NSString stringWithFormat:@"【%@】\n设置成功",m_nsContent];
                            replyMsg(str);
                        } else
                        {
                            replyMsg(@"设置失败");
                        }

                    } else
                    {
                        replyMsg(@"设置失败");
                    }
                }
                
                
            }else
            {
                if ([m_nsContent isEqualToString:@"startReply"]) {
                    
                    canReply = YES;
                    
                }else if ([m_nsContent isEqualToString:@"stopReply"])
                {
                    canReply = NO;
                }
                
            }
            
        }
            break;
            case 47:
        {
//            replyMsg(@"本宝宝看不懂表情");
        }
            
        default:
            break;
    }

    
}
CHMethod(2, void, CMessageMgr, AddMsg, id, arg1, MsgWrap, id, arg2)
{
    CHSuper(2,CMessageMgr,AddMsg, arg1, MsgWrap, arg2);
    NSLog(@"发送的消息为：%@------%@",arg1,arg2);
}


__attribute__((constructor)) static void entry(){
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDir = [paths objectAtIndex:0];
    _plistPath = [docDir stringByAppendingPathComponent:@"botContent.plist"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:_plistPath]) {
        
        _dict = [[NSMutableDictionary alloc] init];
        _subDict = [[NSMutableDictionary alloc] init];
    }else
    {
        _dict = [NSMutableDictionary dictionaryWithContentsOfFile:_plistPath];
        _subDict = [[NSMutableDictionary alloc] init];
        if (!_dict) {
        _dict = [[NSMutableDictionary alloc] init];
        _subDict = [[NSMutableDictionary alloc] init];
        }
    }
    
    CHLoadLateClass(WCDeviceStepObject);
    CHClassHook(0, WCDeviceStepObject,hkStepCount);
    CHLoadLateClass(CMessageMgr);
    CHClassHook(2,CMessageMgr, AsyncOnAddMsg, MsgWrap);
    CHClassHook(2,CMessageMgr, AddMsg, MsgWrap);
}


