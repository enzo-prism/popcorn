import Foundation

struct MoviePair {
    let left: Movie
    let right: Movie

    var key: String {
        let ids = [left.tmdbID, right.tmdbID].sorted()
        return "\(ids[0])-\(ids[1])"
    }
}
