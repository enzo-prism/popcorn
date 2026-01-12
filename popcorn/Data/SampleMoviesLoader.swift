import Foundation

struct SampleMovieDTO: Decodable {
    let id: Int
    let title: String
    let overview: String
    let releaseDate: String?
    let posterPath: String?
    let backdropPath: String?
    let voteAverage: Double
    let voteCount: Int
    let genres: [String]

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case overview
        case releaseDate = "release_date"
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
        case genres
    }
}

enum SampleMoviesLoader {
    static func loadMovies() -> [Movie] {
        let dtos = loadDTOs()
        guard !dtos.isEmpty else {
            return []
        }

        return dtos.map { dto in
            let releaseDate = dateFormatter.date(from: dto.releaseDate ?? "")
            let year = releaseDate.map { Calendar.current.component(.year, from: $0) } ?? 0
            return Movie(
                tmdbID: dto.id,
                title: dto.title,
                overview: dto.overview,
                releaseDate: releaseDate,
                year: year,
                posterPath: dto.posterPath,
                backdropPath: dto.backdropPath,
                voteAverage: dto.voteAverage,
                voteCount: dto.voteCount,
                genreNames: dto.genres
            )
        }
    }

    static func loadDTOs() -> [SampleMovieDTO] {
        guard let url = Bundle.main.url(forResource: "SampleMovies", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let dtos = try? JSONDecoder().decode([SampleMovieDTO].self, from: data) else {
            return []
        }
        return dtos
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
