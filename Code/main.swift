//
//  main.swift
//  ContentfulModelGenerator
//
//  Created by Boris Bügling on 13/11/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

import Foundation

func generate(spaceKey: String, accessToken: String) {
    let configuration = CDAConfiguration.defaultConfiguration()
    configuration.userAgent = "ContentfulModelGenerator/0.3"

    let client = CMAClient(accessToken: accessToken, configuration:configuration)
    let generator = ContentfulModelGenerator(client: client, spaceKey: spaceKey)

    var waiting = true

    generator.generateModelForContentTypesWithCompletionHandler { (model, error) -> Void in
        if (error != nil) {
            println("Error: " + error.localizedDescription)
            waiting = false
            return
        }

        let cwdUrl = NSURL(fileURLWithPath: NSFileManager().currentDirectoryPath)
        ModelSerializer(model: model).generateBundle("ContentfulModel", atPath: cwdUrl!)

        waiting = false
    }

    while(waiting) {
        NSRunLoop.currentRunLoop().runMode(NSDefaultRunLoopMode,
            beforeDate: NSDate(timeIntervalSinceNow: 0.1))
    }
}

let manager = Manager()

manager.register("generate", "Generate a CoreData model") { argv in
    let spaceKey = argv.option("spaceKey")
    let accessToken = argv.option("accessToken")

    if (spaceKey != nil && accessToken != nil) {
        generate(spaceKey!, accessToken!)
    } else {
        println("Please specify a space key and access token.")
    }
}

manager.run()
