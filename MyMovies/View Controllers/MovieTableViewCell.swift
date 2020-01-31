//
//  MovieTableViewCell.swift
//  MyMovies
//
//  Created by Alexander Supe on 31.01.20.
//  Copyright © 2020 Lambda School. All rights reserved.
//

import UIKit

class MovieTableViewCell: UITableViewCell {

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var button: UIButton!
    var movie: Movie!
    
    @IBAction func watched(_ sender: Any) {
        if button.title(for: .normal) == "Unwatched" {
            MovieController.shared.update(movie, hasWatched: true)
            button.setTitle("Watched", for: .normal)
        } else {
            MovieController.shared.update(movie, hasWatched: false)
            button.setTitle("Unwatched", for: .normal)
        }
    }
    
}
