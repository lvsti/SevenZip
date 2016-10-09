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
    
    let fileManager = FileManager.default
    
    func testCreateArchive() -> Int {
        if CommandLine.argc < 3 {
            return 1
        }
        
        let archiveName = CommandLine.arguments[1]
        var fileArgs: [String] = []
        for i in 2..<Int(CommandLine.argc) {
            fileArgs.append(CommandLine.arguments[i])
        }
        
        var entries: [SVZArchiveEntry] = []
        
        for fileArg in fileArgs {
            var isDir: ObjCBool = false
            fileManager.fileExists(atPath: fileArg, isDirectory: &isDir)
            let fileArgStr = fileArg as NSString
            
            if isDir.boolValue {
                entries.append(SVZArchiveEntry(directoryName: fileArgStr.lastPathComponent)!)
                
                let etor = fileManager.enumerator(atPath: fileArg)!

                for path in etor {
                    let fullPath = fileArgStr.appendingPathComponent(path as! String)
                    let fullName = (fileArgStr.lastPathComponent as NSString).appendingPathComponent(path as! String)
                    
                    fileManager.fileExists(atPath: fullPath, isDirectory: &isDir)
                    if isDir.boolValue {
                        entries.append(SVZArchiveEntry(directoryName: fullName)!)
                    }
                    else {
                        entries.append(SVZArchiveEntry(fileName: fullName, contentsOf: URL(fileURLWithPath: fullPath))!)
                    }
                }
            }
            else {
                entries.append(SVZArchiveEntry(fileName: fileArgStr.lastPathComponent, contentsOf: URL(fileURLWithPath: fileArg))!)
            }
        }
        
        guard let archive = try? SVZArchive(url: URL(fileURLWithPath: archiveName), createIfMissing: true) else {
            return 1
        }
        
        guard (try? archive.updateEntries(entries)) != nil else {
            return 1
        }
        
        return 0
    }

    func testReadArchive() -> Int {
        if CommandLine.argc < 2 {
            return 1
        }
        
        let archiveName = CommandLine.arguments[1]
        guard let archive = try? SVZArchive(url: URL(fileURLWithPath: archiveName), createIfMissing: false) else {
            return 1
        }
        NSLog("%@", archive.entries)
        
        return 0
    }

    func testExtractToMemory() -> Int {
        if CommandLine.argc < 2 {
            return 1
        }
        
        let archiveName = CommandLine.arguments[1]
        guard let archive = try? SVZArchive(url: URL(fileURLWithPath: archiveName), createIfMissing: false) else {
            return 1
        }
        
        guard
            let entry = archive.entries.first,
            let data = try? entry.extractedData()
        else {
            return 1
        }
        
        NSLog("data: %@", NSString(data: data, encoding: String.Encoding.utf8.rawValue)!)
        
        return 0
    }

    func testExtractToFile() -> Int {
        if CommandLine.argc < 2 {
            return 1
        }
        
        let archiveName = CommandLine.arguments[1]
        guard let archive = try? SVZArchive(url: URL(fileURLWithPath: archiveName), createIfMissing: false) else {
            return 1
        }
        
        guard let
            entry = archive.entries.first,
            (try? entry.extractToDirectory(at: URL(fileURLWithPath: archiveName))) != nil
        else {
            return 1
        }
        
        return 0
    }

    func testUpdateArchive() -> Int {
        if CommandLine.argc < 2 {
            return 1
        }

        let archiveName = CommandLine.arguments[1]
        guard let archive = try? SVZArchive(url: URL(fileURLWithPath: archiveName), createIfMissing: false) else {
            return 1
        }
        
        var entries = archive.entries
        entries.removeFirst()
        entries.append(SVZArchiveEntry(fileName: "stuff.txt", contentsOf: URL(fileURLWithPath: "/Users/lvsti/stuff.txt"))!)

        guard (try? archive.updateEntries(entries)) != nil else {
            return 1
        }
        
        return 0;
    }
}
