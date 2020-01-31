//
//  MovieController.swift
//  MyMovies
//
//  Created by Spencer Curtis on 8/17/18.
//  Copyright © 2018 Lambda School. All rights reserved.
//

import Foundation
import CoreData

class MovieController {
    
    static let shared = MovieController()
    
    private let apiKey = "4cc920dab8b729a619647ccc4d191d5e"
    private let baseURL = URL(string: "https://api.themoviedb.org/3/search/movie")!
    
    func searchForMovie(with searchTerm: String, completion: @escaping (Error?) -> Void) {
        
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: true)
        
        let queryParameters = ["query": searchTerm,
                               "api_key": apiKey]
        
        components?.queryItems = queryParameters.map({URLQueryItem(name: $0.key, value: $0.value)})
        
        guard let requestURL = components?.url else {
            completion(NSError())
            return
        }
        
        URLSession.shared.dataTask(with: requestURL) { (data, _, error) in
            
            if let error = error {
                NSLog("Error searching for movie with search term \(searchTerm): \(error)")
                completion(error)
                return
            }
            
            guard let data = data else {
                NSLog("No data returned from data task")
                completion(NSError())
                return
            }
            
            do {
                let movieRepresentations = try JSONDecoder().decode(MovieRepresentations.self, from: data).results
                self.searchedMovies = movieRepresentations
                completion(nil)
            } catch {
                NSLog("Error decoding JSON data: \(error)")
                completion(error)
            }
        }.resume()
    }
    
    func createFromSearch(indexPath: IndexPath){
        guard let movie = Movie(movieRepresentation: searchedMovies[indexPath.row], creationFromList: true) else { return }
        create(movie: movie)
    }
    
    // MARK: - Properties
    
    var searchedMovies: [MovieRepresentation] = []
    
    //MARK: - CoreData & Firebase
    let firebaseURL = URL(string: "https://movies-84b85.firebaseio.com/")!
    typealias CompletionHandler = (Error?) -> Void
    
    init() { read() }
    
   func create(movie: Movie, completion: @escaping CompletionHandler = { _ in }) {
        let uuid = movie.identifier ?? UUID()
        var request = URLRequest(url: firebaseURL.appendingPathComponent(uuid.uuidString).appendingPathExtension("json"))
        request.httpMethod = "PUT"
        
        do {
            guard var representation = movie.movieRepresentation else { completion(NSError()); return }
            representation.identifier = uuid.uuidString
            movie.identifier = uuid
            try CoreDataStack.shared.save()
            request.httpBody = try JSONEncoder().encode(representation)
        } catch {
            print("Error encoding movie \(movie): \(error)")
            DispatchQueue.main.async { completion(error) }
            return
        }
        
        URLSession.shared.dataTask(with: request) { _, _, error in
            if let error = error {
                print("Error PUTting movie to server: \(error)")
                DispatchQueue.main.async { completion(error) }
                return
            }
            DispatchQueue.main.async { completion(nil) }
        }.resume()
    }
    
   func read(completion: @escaping CompletionHandler = { _ in }) {
            let requestURL = firebaseURL.appendingPathExtension("json")
            
            URLSession.shared.dataTask(with: requestURL) { data, _, error in
                if let error = error {
                    print("Error fetching movies: \(error)")
                    DispatchQueue.main.async { completion(error) }
                    return
                }
                
                guard let data = data else {
                    print("No data return by data entry")
                    DispatchQueue.main.async { completion(NSError()) }
                    return
                }
                
                do {
                    let movieRepresentations = Array(try JSONDecoder().decode([String : MovieRepresentation].self, from: data).values)
                    try self.update(with: movieRepresentations)
                    DispatchQueue.main.async { completion(nil) }
                } catch {
                    print("Error decoding or storing movie representations: \(error)")
                    DispatchQueue.main.async { completion(error) }
                }
            }.resume()
        }
    
    func update(_ movie: Movie, hasWatched: Bool) {
        guard let title = movie.title, let identifier = movie.identifier else { return }
        let overview = movie.overview ?? ""
        delete(movie)
        CoreDataStack.shared.mainContext.delete(movie)
        do {
            try CoreDataStack.shared.mainContext.save()
        }
        catch {
            CoreDataStack.shared.mainContext.reset()
            NSLog("Error saving managed object context: \(error)")
        }
        create(movie: Movie(title: title, identifier: identifier, hasWatched: hasWatched, overview: overview))
    }
        
        func delete(_ movie: Movie, completion: @escaping CompletionHandler = { _ in }) {
            guard let uuid = movie.identifier else { completion(NSError()); return }
            
            let requestURL = firebaseURL.appendingPathComponent(uuid.uuidString).appendingPathExtension("json")
            var request = URLRequest(url: requestURL)
            request.httpMethod = "DELETE"
            
            URLSession.shared.dataTask(with: request) { _, response, error in
                print(response!)
                DispatchQueue.main.async { completion(error) }
            }.resume()
        }
        
        // MARK: - Internal methods
        private func update(with representations: [MovieRepresentation]) throws {
            guard representations.isEmpty == false else { return }
            let moviesWithID = representations.filter { $0.identifier != nil }
            let identifiersToFetch = moviesWithID.compactMap { UUID(uuidString: $0.identifier!) }
            let representationsByID = Dictionary(uniqueKeysWithValues: zip(identifiersToFetch, moviesWithID))
            var moviesToCreate = representationsByID
            let fetchRequest: NSFetchRequest<Movie> = Movie.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "identifier IN %@", identifiersToFetch)
            let context = CoreDataStack.shared.container.newBackgroundContext()
            context.perform {
                do { let existingMovies = try context.fetch(fetchRequest)
                    for movie in existingMovies {
                        guard let id = movie.identifier,
                            let representation = representationsByID[id] else { continue }
                        self.updateData(movie: movie, with: representation)
                        moviesToCreate.removeValue(forKey: id)
                    }
                    for representation in moviesToCreate.values { Movie(movieRepresentation: representation, context: context) }
                }
                catch { print("Error fetching movies for UUIDs: \(error)") }
            }
            try CoreDataStack.shared.save(context: context)
        }
        
        private func updateData(movie: Movie, with representation: MovieRepresentation) {
            movie.title = representation.title
            movie.hasWatched = representation.hasWatched ?? false
            movie.overview = representation.overview ?? ""
        }
    }
