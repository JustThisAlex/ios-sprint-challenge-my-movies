//
//  Movie+Convenience.swift
//  MyMovies
//
//  Created by Alexander Supe on 31.01.20.
//  Copyright © 2020 Lambda School. All rights reserved.
//

import Foundation
import CoreData

extension Movie {
    var movieRepresentation: MovieRepresentation? {
        guard let title = title, let identifier = identifier else { return nil }
        return MovieRepresentation(title: title, identifier: identifier.uuidString, hasWatched: hasWatched, overview: overview)
    }
    
    @discardableResult
    convenience init(title: String, identifier: UUID = UUID(), hasWatched: Bool = false, overview: String, context: NSManagedObjectContext = CoreDataStack.shared.mainContext) {
        self.init(context: context); self.title = title; self.identifier = identifier; self.hasWatched = hasWatched; self.overview = overview
    }
    
    @discardableResult
    convenience init?(movieRepresentation: MovieRepresentation, context: NSManagedObjectContext = CoreDataStack.shared.mainContext) {
        guard let identifier = UUID(uuidString: movieRepresentation.identifier ?? "") else { return nil }
        self.init(title: movieRepresentation.title, identifier: identifier, hasWatched: movieRepresentation.hasWatched ?? false, overview: movieRepresentation.overview ?? "", context: context)
    }
    
    @discardableResult
    convenience init?(movieRepresentation: MovieRepresentation, context: NSManagedObjectContext = CoreDataStack.shared.mainContext, creationFromList: Bool) {
        if creationFromList == false { return nil }
        self.init(title: movieRepresentation.title, identifier: UUID(), hasWatched: false, overview: movieRepresentation.overview ?? "", context: context)
       }
    
}
