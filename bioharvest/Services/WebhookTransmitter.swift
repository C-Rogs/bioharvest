import Foundation

enum WebhookError: LocalizedError {
    case invalidURL
    case nonHTTPS
    case httpStatus(Int)
    case network(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Webhook URL is invalid."
        case .nonHTTPS:
            return "Webhook URL must use HTTPS."
        case .httpStatus(let code):
            return "Webhook returned HTTP \(code)."
        case .network(let error):
            return error.localizedDescription
        }
    }
}

enum WebhookTransmitter {
    private static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        return URLSession(configuration: config)
    }()

    static func post(json: Data, to urlString: String) async -> Result<Void, WebhookError> {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed), let scheme = url.scheme?.lowercased() else {
            return .failure(.invalidURL)
        }
        guard scheme == "https" else {
            return .failure(.nonHTTPS)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = json
        request.timeoutInterval = 30

        do {
            let (_, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.invalidURL)
            }
            guard (200 ... 299).contains(httpResponse.statusCode) else {
                return .failure(.httpStatus(httpResponse.statusCode))
            }
            return .success(())
        } catch {
            return .failure(.network(error))
        }
    }
}
