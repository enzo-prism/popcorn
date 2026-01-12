import Foundation

struct TMDbDiscoverResponse: Decodable {
    let page: Int
    let totalPages: Int
    let results: [TMDbMovieDTO]

    enum CodingKeys: String, CodingKey {
        case page
        case totalPages = "total_pages"
        case results
    }
}

struct TMDbMovieDTO: Decodable {
    let id: Int
    let title: String
    let originalTitle: String?
    let overview: String?
    let releaseDate: String?
    let posterPath: String?
    let backdropPath: String?
    let voteAverage: Double?
    let voteCount: Int?
    let genreIDs: [Int]

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case originalTitle = "original_title"
        case overview
        case releaseDate = "release_date"
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
        case genreIDs = "genre_ids"
    }
}

struct TMDbCreditsResponse: Decodable {
    let cast: [TMDbCastMember]
    let crew: [TMDbCrewMember]
}

struct TMDbCastMember: Decodable {
    let id: Int
    let name: String
    let character: String?
    let order: Int
}

struct TMDbCrewMember: Decodable {
    let id: Int
    let name: String
    let job: String
}

struct TMDbKeywordsResponse: Decodable {
    let keywords: [TMDbKeyword]
}

struct TMDbKeyword: Decodable {
    let id: Int
    let name: String
}

struct TMDbConfigurationResponse: Decodable {
    let images: TMDbImageConfigurationPayload
}

struct TMDbImageConfigurationPayload: Decodable {
    let secureBaseURL: String?
    let baseURL: String?
    let posterSizes: [String]

    enum CodingKeys: String, CodingKey {
        case secureBaseURL = "secure_base_url"
        case baseURL = "base_url"
        case posterSizes = "poster_sizes"
    }
}

enum TMDbGenres {
    static let namesByID: [Int: String] = [
        28: "Action",
        12: "Adventure",
        16: "Animation",
        35: "Comedy",
        80: "Crime",
        99: "Documentary",
        18: "Drama",
        10751: "Family",
        14: "Fantasy",
        36: "History",
        27: "Horror",
        10402: "Music",
        9648: "Mystery",
        10749: "Romance",
        878: "Sci-Fi",
        10770: "TV Movie",
        53: "Thriller",
        10752: "War",
        37: "Western"
    ]
}

enum TMDbDateFormatter {
    static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static func parse(_ value: String?) -> Date? {
        guard let value else { return nil }
        return formatter.date(from: value)
    }

    static func format(_ value: Date) -> String {
        formatter.string(from: value)
    }
}

struct TMDbClient {
    private let apiKey: String
    private let session: URLSession

    init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    func fetchTopMovies(limit: Int, minVoteCount: Int, from startDate: Date, to endDate: Date) async throws -> [TMDbMovieDTO] {
        var collected: [TMDbMovieDTO] = []
        var seenIDs = Set<Int>()
        var page = 1

        while collected.count < limit {
            let response = try await discoverMovies(page: page, minVoteCount: minVoteCount, from: startDate, to: endDate)
            for movie in response.results {
                guard let date = TMDbDateFormatter.parse(movie.releaseDate) else { continue }
                guard date >= startDate && date <= endDate else { continue }
                guard let voteCount = movie.voteCount, voteCount >= minVoteCount else { continue }
                guard seenIDs.insert(movie.id).inserted else { continue }
                collected.append(movie)
                if collected.count == limit { break }
            }

            if page >= response.totalPages { break }
            page += 1
        }

        return collected
    }

    func fetchMovieDetails(movieID: Int) async throws -> MovieDetails {
        async let creditsTask = fetchCredits(movieID: movieID)
        async let keywordsTask = fetchKeywords(movieID: movieID)
        let (creditsResponse, keywordsResponse) = try await (creditsTask, keywordsTask)

        let cast = creditsResponse.cast
            .sorted { $0.order < $1.order }
            .prefix(10)
            .map { CastMember(id: $0.id, name: $0.name, role: $0.character ?? "", order: $0.order) }
        let crew = creditsResponse.crew
            .filter { $0.job == "Director" }
            .map { CrewMember(id: $0.id, name: $0.name, job: $0.job) }
        let keywords = keywordsResponse.keywords.map { $0.name }

        return MovieDetails(cast: cast, crew: crew, keywords: keywords, lastUpdatedAt: Date())
    }

    func fetchImageConfiguration() async throws -> TMDbImageConfigurationPayload {
        let url = makeURL(
            path: "/configuration",
            queryItems: [
                URLQueryItem(name: "api_key", value: apiKey)
            ]
        )

        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        let decoded = try JSONDecoder().decode(TMDbConfigurationResponse.self, from: data)
        return decoded.images
    }

    private func discoverMovies(page: Int, minVoteCount: Int, from startDate: Date, to endDate: Date) async throws -> TMDbDiscoverResponse {
        let url = makeURL(
            path: "/discover/movie",
            queryItems: [
                URLQueryItem(name: "api_key", value: apiKey),
                URLQueryItem(name: "language", value: "en-US"),
                URLQueryItem(name: "sort_by", value: "vote_average.desc"),
                URLQueryItem(name: "vote_count.gte", value: String(minVoteCount)),
                URLQueryItem(name: "include_adult", value: "false"),
                URLQueryItem(name: "include_video", value: "false"),
                URLQueryItem(name: "primary_release_date.gte", value: TMDbDateFormatter.format(startDate)),
                URLQueryItem(name: "primary_release_date.lte", value: TMDbDateFormatter.format(endDate)),
                URLQueryItem(name: "page", value: String(page))
            ]
        )

        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(TMDbDiscoverResponse.self, from: data)
    }

    private func fetchCredits(movieID: Int) async throws -> TMDbCreditsResponse {
        let url = makeURL(
            path: "/movie/\(movieID)/credits",
            queryItems: [
                URLQueryItem(name: "api_key", value: apiKey),
                URLQueryItem(name: "language", value: "en-US")
            ]
        )

        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(TMDbCreditsResponse.self, from: data)
    }

    private func fetchKeywords(movieID: Int) async throws -> TMDbKeywordsResponse {
        let url = makeURL(
            path: "/movie/\(movieID)/keywords",
            queryItems: [
                URLQueryItem(name: "api_key", value: apiKey)
            ]
        )

        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(TMDbKeywordsResponse.self, from: data)
    }

    private func makeURL(path: String, queryItems: [URLQueryItem]) -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.themoviedb.org"
        components.path = "/3" + path
        components.queryItems = queryItems
        guard let url = components.url else {
            return URL(string: "https://api.themoviedb.org/3")!
        }
        return url
    }
}
