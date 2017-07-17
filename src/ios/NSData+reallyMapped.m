//
//  NSData+reallyMapped.m
//  MapTest
//
//  Created by Tom Harrington on 1/31/12.
//  Copyright (c) 2012 Atomic Bird, LLC. All rights reserved.
//

#import "NSData+reallyMapped.h"
#import <sys/fcntl.h>
#import <sys/mman.h>
#include <sys/stat.h>
#import "NSObject+deallocBlock.h"

@implementation NSData (reallyMapped)

+ (NSData *)dataWithContentsOfReallyMappedFile:(NSString *)path {
    return [self dataWithContentsOfReallyMappedFile:path offset:0 length:-1];
}

+ (NSData *)dataWithContentsOfReallyMappedFile:(NSString *)path offset:(long)offset length:(long)length
{
    // Get an fd
    int fd = open([path fileSystemRepresentation], O_RDONLY);
    if (fd < 0) {
        return nil;
    }
    
    // Get file size
    struct stat statbuf;
    if (fstat(fd, &statbuf) == -1) {
        close(fd);
        return nil;
    }
    
    // mmap
    void *mappedFile;
    
    // Length undefined. Map whole file.
    if (length < 0) {
        length = statbuf.st_size;
    }
    
    // Byte range would exceed the end of the file.
    if (length + offset > statbuf.st_size) {
        length = statbuf.st_size - offset;
    }
    
    mappedFile = mmap(0, length, PROT_READ, MAP_FILE|MAP_PRIVATE, fd, offset);
    close(fd);
    if (mappedFile == MAP_FAILED) {
        NSLog(@"Map failed, errno=%d, %s", errno, strerror(errno));
        return nil;
    }
    

    // Create the NSData
    NSData *mappedData = [NSData dataWithBytesNoCopy:mappedFile length:length freeWhenDone:NO];
    
    [mappedData addDeallocBlock:^{
        munmap(mappedFile, length);
    }];

    return mappedData;
}

@end
