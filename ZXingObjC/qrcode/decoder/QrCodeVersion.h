/**
 * <p>Encapsulates a set of error-correction blocks in one symbol version. Most versions will
 * use blocks of differing sizes within one version, so, this encapsulates the parameters for
 * each set of blocks. It also holds the number of error-correction codewords per block since it
 * will be the same across all blocks within one version.</p>
 */

@class ECB;

@interface ECBlocks : NSObject {
  int ecCodewordsPerBlock;
  NSArray * ecBlocks;
}

@property(nonatomic, readonly) int eCCodewordsPerBlock;
@property(nonatomic, readonly) int numBlocks;
@property(nonatomic, readonly) int totalECCodewords;
@property(nonatomic, retain, readonly) NSArray * ecBlocks;

- (id) initWithEcCodewordsPerBlock:(int)ecCodewordsPerBlock ecBlocks:(ECB *)ecBlocks;
- (id) initWithEcCodewordsPerBlock:(int)ecCodewordsPerBlock ecBlocks1:(ECB *)ecBlocks1 ecBlocks2:(ECB *)ecBlocks2;
+ (ECBlocks*)ecBlocksWithEcCodewordsPerBlock:(int)ecCodewordsPerBlock ecBlocks:(ECB *)ecBlocks;
+ (ECBlocks*)ecBlocksWithEcCodewordsPerBlock:(int)ecCodewordsPerBlock ecBlocks1:(ECB *)ecBlocks1 ecBlocks2:(ECB *)ecBlocks2;

@end

/**
 * <p>Encapsualtes the parameters for one error-correction block in one symbol version.
 * This includes the number of data codewords, and the number of times a block with these
 * parameters is used consecutively in the QR code version's format.</p>
 */

@interface ECB : NSObject {
  int count;
  int dataCodewords;
}

@property(nonatomic, readonly) int count;
@property(nonatomic, readonly) int dataCodewords;

- (id) initWithCount:(int)count dataCodewords:(int)dataCodewords;
+ (ECB*) ecbWithCount:(int)count dataCodewords:(int)dataCodewords;

@end

/**
 * See ISO 18004:2006 Annex D
 * 
 * @author Sean Owen
 */

@class ErrorCorrectionLevel, BitMatrix;

@interface QrCodeVersion : NSObject {
  int versionNumber;
  NSArray * alignmentPatternCenters;
  NSArray * ecBlocks;
  int totalCodewords;
}

@property(nonatomic, readonly) int versionNumber;
@property(nonatomic, retain, readonly) NSArray * alignmentPatternCenters;
@property(nonatomic, readonly) int totalCodewords;
@property(nonatomic, readonly) int dimensionForVersion;

- (ECBlocks *) getECBlocksForLevel:(ErrorCorrectionLevel *)ecLevel;
+ (QrCodeVersion *) getProvisionalVersionForDimension:(int)dimension;
+ (QrCodeVersion *) getVersionForNumber:(int)versionNumber;
+ (QrCodeVersion *) decodeVersionInformation:(int)versionBits;
- (BitMatrix *) buildFunctionPattern;

@end
