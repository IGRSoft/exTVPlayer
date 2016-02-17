//
//  IGRCountryParser.m
//  exTVPlayer
//
//  Created by Vitalii Parovishnyk on 2/17/16.
//  Copyright © 2016 IGR Software. All rights reserved.
//

#import "IGRCountryParser.h"

@implementation IGRCountryParser

+ (IGRVideoCategory)currentCountry
{
	NSLocale *currentLocale = [NSLocale currentLocale];  // get the current locale.
	NSString *countryCode = [currentLocale objectForKey:NSLocaleCountryCode];
	
	IGRVideoCategory currentCountry = IGRVideoCategory_Eng;
	if ([countryCode isEqualToString:@"UA"])
	{
		currentCountry = IGRVideoCategory_Ukr;
	}
	else if ([countryCode isEqualToString:@"RU"])
	{
		currentCountry = IGRVideoCategory_Rus;
	}
	else if ([countryCode isEqualToString:@"PL"])
	{
		currentCountry = IGRVideoCategory_Pl;
	}
	else if ([countryCode isEqualToString:@"ES"])
	{
		currentCountry = IGRVideoCategory_Esp;
	}
	else if ([countryCode isEqualToString:@"DE"])
	{
		currentCountry = IGRVideoCategory_De;
	}
	
	return currentCountry;
}

@end
