//
//  demo.swift
//  SevenZip
//
//  Created by Tamas Lustyik on 2016. 07. 17..
//  Copyright © 2016. Tamas Lustyik. All rights reserved.
//

import Foundation
import SevenZip

class SwiftDemo: NSObject {
    
    let fileManager = NSFileManager.defaultManager()
    
    func testCreateArchive() -> Int {
        if Process.argc < 3 {
            return 1
        }
        
        let archiveName = Process.arguments[1]
        var fileArgs: [String] = []
        for i in 2..<Int(Process.argc) {
            fileArgs.append(Process.arguments[i])
        }
        
        var entries: [SVZArchiveEntry] = []
        
        for fileArg in fileArgs {
            var isDir: ObjCBool = false
            fileManager.fileExistsAtPath(fileArg, isDirectory: &isDir)
            let fileArgStr = fileArg as NSString
            
            if isDir {
                entries.append(SVZArchiveEntry(directoryName: fileArgStr.lastPathComponent)!)
                
                let etor = fileManager.enumeratorAtPath(fileArg)!

                for path in etor {
                    let fullPath = fileArgStr.stringByAppendingPathComponent(path as! String)
                    let fullName = (fileArgStr.lastPathComponent as NSString).stringByAppendingPathComponent(path as! String)
                    
                    fileManager.fileExistsAtPath(fullPath, isDirectory: &isDir)
                    if isDir {
                        entries.append(SVZArchiveEntry(directoryName: fullName)!)
                    }
                    else {
                        entries.append(SVZArchiveEntry(fileName: fullName, contentsOfURL: NSURL(fileURLWithPath: fullPath))!)
                    }
                }
            }
            else {
                entries.append(SVZArchiveEntry(fileName: fileArgStr.lastPathComponent, contentsOfURL: NSURL(fileURLWithPath: fileArg))!)
            }
        }
        
        guard let archive = try? SVZArchive(URL: NSURL(fileURLWithPath: archiveName), createIfMissing: true) else {
            return 1
        }
        
        guard (try? archive.updateEntries(entries)) != nil else {
            return 1
        }
        
        return 0
    }

    func testReadArchive() -> Int {
        if Process.argc < 2 {
            return 1
        }
        
        let archiveName = Process.arguments[1]
        guard let archive = try? SVZArchive(URL: NSURL(fileURLWithPath: archiveName), createIfMissing: false) else {
            return 1
        }
        NSLog("%@", archive.entries)
        
        return 0
    }

    func testExtractToMemory() -> Int {
        if Process.argc < 2 {
            return 1
        }
        
        let archiveName = Process.arguments[1]
        guard let archive = try? SVZArchive(URL: NSURL(fileURLWithPath: archiveName), createIfMissing: false) else {
            return 1
        }
        
        guard let
            entry = archive.entries.first,
            data = try? entry.extractedData()
        else {
            return 1
        }
        
        NSLog("data: %@", NSString(data: data, encoding: NSUTF8StringEncoding)!)
        
        return 0
    }

    func testExtractToFile() -> Int {
        if Process.argc < 2 {
            return 1
        }
        
        let archiveName = Process.arguments[1]
        guard let archive = try? SVZArchive(URL: NSURL(fileURLWithPath: archiveName), createIfMissing: false) else {
            return 1
        }
        
        guard let
            entry = archive.entries.first where
            (try? entry.extractToDirectoryAtURL(NSURL(fileURLWithPath: archiveName))) != nil
        else {
            return 1
        }
        
        return 0
    }

    func testUpdateArchive() -> Int {
        if Process.argc < 2 {
            return 1
        }

        let archiveName = Process.arguments[1]
        guard let archive = try? SVZArchive(URL: NSURL(fileURLWithPath: archiveName), createIfMissing: false) else {
            return 1
        }
        
        var entries = archive.entries
        entries.removeFirst()
        entries.append(SVZArchiveEntry(fileName: "stuff.txt", contentsOfURL: NSURL(fileURLWithPath: "/Users/lvsti/stuff.txt"))!)

        guard (try? archive.updateEntries(entries)) != nil else {
            return 1
        }
        
        return 0;
    }
}
