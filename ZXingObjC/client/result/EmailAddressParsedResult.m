#import "EmailAddressParsedResult.h"
#import "ParsedResultType.h"

@interface EmailAddressParsedResult ()

@property(nonatomic, retain) NSString * emailAddress;
@property(nonatomic, retain) NSString * subject;
@property(nonatomic, retain) NSString * body;
@property(nonatomic, retain) NSString * mailtoURI;
@property(nonatomic, retain) NSString * displayResult;

@end

@implementation EmailAddressParsedResult

@synthesize emailAddress;
@synthesize subject;
@synthesize body;
@synthesize mailtoURI;
@synthesize displayResult;

- (id) init:(NSString *)anEmailAddress subject:(NSString *)aSubject body:(NSString *)aBody mailtoURI:(NSString *)aMailtoURI {
  if (self = [super initWithType:kParsedResultTypeEmailAddress]) {
    self.emailAddress = anEmailAddress;
    self.subject = aSubject;
    self.body = aBody;
    self.mailtoURI = aMailtoURI;
  }
  return self;
}

- (NSString *) displayResult {
  NSMutableString * result = [[[NSMutableString alloc] init:30] autorelease];
  [ParsedResult maybeAppend:emailAddress param1:result];
  [ParsedResult maybeAppend:subject param1:result];
  [ParsedResult maybeAppend:body param1:result];
  return result;
}

- (void) dealloc {
  [emailAddress release];
  [subject release];
  [body release];
  [mailtoURI release];
  [super dealloc];
}

@end
