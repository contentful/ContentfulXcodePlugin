//
//  main.swift
//  ContentfulModelGenerator
//
//  Created by Boris Bügling on 13/11/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

import Foundation

func generate(spaceKey: String, _ accessToken: String) {
    let configuration = CDAConfiguration.defaultConfiguration()
    configuration.userAgent = "ContentfulModelGenerator/0.3"

    let client = CMAClient(accessToken: accessToken, configuration:configuration)
    let generator = ContentfulModelGenerator(client: client, spaceKey: spaceKey)

    var waiting = true

    generator.generateModelForContentTypesWithCompletionHandler { (model, error) -> Void in
        if (error != nil) {
            print("Error: " + error.localizedDescription)
            waiting = false
            return
        }

        let cwdUrl = NSURL(fileURLWithPath: NSFileManager().currentDirectoryPath)
        do {
            try ModelSerializer(model: model).generateBundle("ContentfulModel", atPath: cwdUrl)
        } catch let error {
            print("Error: \(error)")
            waiting = false
            return
        }

        waiting = false
    }

    while(waiting) {
        NSRunLoop.currentRunLoop().runMode(NSDefaultRunLoopMode,
            beforeDate: NSDate(timeIntervalSinceNow: 0.1))
    }
}

// Manually copied from `Command.swift` of SwiftShell, because of a naming conflict with Commander
private func newtask (shellcommand: String) -> NSTask {
    let task = NSTask()
    task.arguments = ["-c", shellcommand]
    task.launchPath = "/bin/bash"

    return task
}

public func $ (shellcommand: String) -> String {
    let task = newtask(shellcommand)

    // avoids implicit reading of the main script's standardInput
    task.standardInput = NSPipe ()

    let output = NSPipe ()
    task.standardOutput = output
    task.launch()
    task.waitUntilExit()

    return output.fileHandleForReading.read().trim()
}

// Manually copied from `Commands.swift` of Commander because that file requires a separate module
public func command<A:ArgumentDescriptor, A1:ArgumentDescriptor>(descriptor:A, _ descriptor1:A1, closure:(A.ValueType, A1.ValueType) throws -> ()) -> CommandType {
    return AnonymousCommand { parser in
        let help = Help([
            BoxedArgumentDescriptor(value: descriptor),
            BoxedArgumentDescriptor(value: descriptor1),
            ])

        if parser.hasOption("help") {
            throw help
        }

        let value0 = try descriptor.parse(parser)
        let value1 = try descriptor1.parse(parser)

        if !parser.isEmpty {
            throw UsageError("Unknown Arguments: \(parser)", help)
        }
        
        try closure(value0, value1)
    }
}

command(Argument<String>("Space ID", description: "ID of the Space"),
        Argument<String>("Access Token", description: "Access token of the Space"))
{ (spaceKey, accessToken) in
    generate(spaceKey, accessToken)
}.run()
