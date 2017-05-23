//
//  WeChatPlugin.mm
//  WeChatPlugin
//
//  Created by caobuchi on 17/5/23.
//  Copyright (c) 2017年 __MyCompanyName__. All rights reserved.
//

// CaptainHook by Ryan Petrich
// see https://github.com/rpetrich/CaptainHook/

#import <Foundation/Foundation.h>
#import "CaptainHook/CaptainHook.h"
#include <notify.h> // not required; for examples only

// Objective-C runtime hooking using CaptainHook:
//   1. declare class using CHDeclareClass()
//   2. load class using CHLoadClass() or CHLoadLateClass() in CHConstructor
//   3. hook method using CHOptimizedMethod()
//   4. register hook using CHHook() in CHConstructor
//   5. (optionally) call old method using CHSuper()


@interface WeChatPlugin : NSObject

@end

@implementation WeChatPlugin

-(id)init
{
	if ((self = [super init]))
	{
	}

    return self;
}

@end

CHConstructor // code block that runs immediately upon load
{
    
}
