//
//  Tools.swift
//  MyMovies
//
//  Created by Alexander Supe on 31.01.20.
//  Copyright © 2020 Lambda School. All rights reserved.
//

import Foundation

struct ErrorHandler {
    static func check(_ data: Data) {
        guard let data = data else {
            print("Error: No data.")
            DispatchQueue.main.async { completion(NSError()) }
            return
        }
    }
    
    func handle() {
        
    }
}
