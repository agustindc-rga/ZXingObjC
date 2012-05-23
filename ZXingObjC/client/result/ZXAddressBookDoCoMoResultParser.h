#import "ZXAbstractDoCoMoResultParser.h"
#import "ZXResult.h"

/**
 * Implements the "MECARD" address book entry format.
 * 
 * Supported keys: N, SOUND, TEL, EMAIL, NOTE, ADR, BDAY, URL, plus ORG
 * Unsupported keys: TEL-AV, NICKNAME
 * 
 * Except for TEL, multiple values for keys are also not supported;
 * the first one found takes precedence.
 * 
 * Our understanding of the MECARD format is based on this document:
 * 
 * http://www.mobicode.org.tw/files/OMIA%20Mobile%20Bar%20Code%20Standard%20v3.2.1.doc 
 */

@class ZXAddressBookParsedResult, ZXResult;

@interface ZXAddressBookDoCoMoResultParser : ZXAbstractDoCoMoResultParser

+ (ZXAddressBookParsedResult *)parse:(ZXResult *)result;

@end
