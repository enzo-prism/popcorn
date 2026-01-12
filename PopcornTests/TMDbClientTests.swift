import XCTest
@testable import Popcorn

final class TMDbClientTests: XCTestCase {
    override func tearDown() {
        MockURLProtocol.reset()
        super.tearDown()
    }

    func testFetchTopMoviesPaginatesAndFilters() async throws {
        let session = makeSession()
        let client = TMDbClient(apiKey: "test-key", session: session)
        let startDate = makeDate(year: 2010, month: 1, day: 1)
        let endDate = makeDate(year: 2020, month: 1, day: 1)

        let page1 = discoverResponse(
            page: 1,
            totalPages: 2,
            results: [
                movieDTO(id: 1, title: "Valid One", voteCount: 3000, releaseDate: "2015-05-01", genreIDs: [878]),
                movieDTO(id: 2, title: "Low Votes", voteCount: 100, releaseDate: "2015-06-01", genreIDs: [18]),
                movieDTO(id: 3, title: "Outside Window", voteCount: 4000, releaseDate: "1999-01-01", genreIDs: [35])
            ]
        )
        let page2 = discoverResponse(
            page: 2,
            totalPages: 2,
            results: [
                movieDTO(id: 1, title: "Duplicate One", voteCount: 3000, releaseDate: "2015-05-01", genreIDs: [878]),
                movieDTO(id: 4, title: "Valid Two", voteCount: 2500, releaseDate: "2016-01-01", genreIDs: [28])
            ]
        )

        MockURLProtocol.requestHandler = { [self] request in
            let components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)
            let pageValue = components?.queryItems?.first(where: { $0.name == "page" })?.value
            let page = Int(pageValue ?? "1") ?? 1
            let response = page == 1 ? page1 : page2
            return try makeHTTPResponse(url: request.url!, json: response)
        }

        let movies = try await client.fetchTopMovies(limit: 2, minVoteCount: 2000, from: startDate, to: endDate)

        XCTAssertEqual(movies.map(\.id), [1, 4])
        XCTAssertEqual(MockURLProtocol.receivedRequests.count, 2)

        guard let firstRequest = MockURLProtocol.receivedRequests.first else {
            XCTFail("Expected at least one request")
            return
        }
        let components = URLComponents(url: firstRequest.url!, resolvingAgainstBaseURL: false)
        let params = Set(components?.queryItems?.map { "\($0.name)=\($0.value ?? "")" } ?? [])
        XCTAssertTrue(params.contains("vote_count.gte=2000"))
        XCTAssertTrue(params.contains("primary_release_date.gte=\(TMDbDateFormatter.format(startDate))"))
        XCTAssertTrue(params.contains("primary_release_date.lte=\(TMDbDateFormatter.format(endDate))"))
    }

    func testFetchTopMoviesStopsAtLimitWithoutExtraPages() async throws {
        let session = makeSession()
        let client = TMDbClient(apiKey: "test-key", session: session)
        let startDate = makeDate(year: 2010, month: 1, day: 1)
        let endDate = makeDate(year: 2020, month: 1, day: 1)

        let page1 = discoverResponse(
            page: 1,
            totalPages: 4,
            results: [
                movieDTO(id: 10, title: "A", voteCount: 3000, releaseDate: "2015-01-01", genreIDs: [18]),
                movieDTO(id: 11, title: "B", voteCount: 3000, releaseDate: "2016-01-01", genreIDs: [18]),
                movieDTO(id: 12, title: "C", voteCount: 3000, releaseDate: "2017-01-01", genreIDs: [18]),
                movieDTO(id: 13, title: "D", voteCount: 3000, releaseDate: "2018-01-01", genreIDs: [18])
            ]
        )

        MockURLProtocol.requestHandler = { [self] request in
            return try makeHTTPResponse(url: request.url!, json: page1)
        }

        let movies = try await client.fetchTopMovies(limit: 3, minVoteCount: 2000, from: startDate, to: endDate)

        XCTAssertEqual(movies.count, 3)
        XCTAssertEqual(MockURLProtocol.receivedRequests.count, 1)
    }

    func testFetchMovieDetailsSortsCastAndFiltersDirectors() async throws {
        let session = makeSession()
        let client = TMDbClient(apiKey: "test-key", session: session)
        let movieID = 42

        let credits = creditsResponse(
            cast: (0..<12).map { index in
                ["id": index, "name": "Actor \(index)", "character": "Role \(index)", "order": 11 - index]
            },
            crew: [
                ["id": 1, "name": "Director A", "job": "Director"],
                ["id": 2, "name": "Writer B", "job": "Writer"],
                ["id": 3, "name": "Director C", "job": "Director"]
            ]
        )
        let keywords = keywordsResponse(keywords: [
            ["id": 1, "name": "time travel"],
            ["id": 2, "name": "space exploration"]
        ])

        MockURLProtocol.requestHandler = { [self] request in
            let path = request.url?.path ?? ""
            if path.contains("/movie/\(movieID)/credits") {
                return try makeHTTPResponse(url: request.url!, json: credits)
            }
            if path.contains("/movie/\(movieID)/keywords") {
                return try makeHTTPResponse(url: request.url!, json: keywords)
            }
            throw URLError(.badURL)
        }

        let details = try await client.fetchMovieDetails(movieID: movieID)

        XCTAssertEqual(details.cast.count, 10)
        XCTAssertEqual(details.cast.first?.order, 0)
        XCTAssertEqual(details.crew.map(\.name).sorted(), ["Director A", "Director C"])
        XCTAssertEqual(details.keywords, ["time travel", "space exploration"])
    }

    private func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }

    private func makeDate(year: Int, month: Int, day: Int) -> Date {
        let calendar = Calendar(identifier: .gregorian)
        return calendar.date(from: DateComponents(year: year, month: month, day: day)) ?? Date()
    }

    private func movieDTO(
        id: Int,
        title: String,
        voteCount: Int,
        releaseDate: String,
        genreIDs: [Int]
    ) -> [String: Any] {
        [
            "id": id,
            "title": title,
            "original_title": title,
            "overview": "overview",
            "release_date": releaseDate,
            "poster_path": "/poster.jpg",
            "backdrop_path": "/backdrop.jpg",
            "vote_average": 7.5,
            "vote_count": voteCount,
            "genre_ids": genreIDs
        ]
    }

    private func discoverResponse(page: Int, totalPages: Int, results: [[String: Any]]) -> [String: Any] {
        [
            "page": page,
            "total_pages": totalPages,
            "results": results
        ]
    }

    private func creditsResponse(cast: [[String: Any]], crew: [[String: Any]]) -> [String: Any] {
        [
            "cast": cast,
            "crew": crew
        ]
    }

    private func keywordsResponse(keywords: [[String: Any]]) -> [String: Any] {
        [
            "keywords": keywords
        ]
    }

    private func makeHTTPResponse(url: URL, json: [String: Any]) throws -> (HTTPURLResponse, Data) {
        let data = try JSONSerialization.data(withJSONObject: json, options: [])
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
        return (response, data)
    }
}

private final class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    static var receivedRequests: [URLRequest] = []
    private static let lock = NSLock()

    static func reset() {
        lock.lock()
        requestHandler = nil
        receivedRequests = []
        lock.unlock()
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        MockURLProtocol.lock.lock()
        MockURLProtocol.receivedRequests.append(request)
        let handler = MockURLProtocol.requestHandler
        MockURLProtocol.lock.unlock()

        guard let handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
