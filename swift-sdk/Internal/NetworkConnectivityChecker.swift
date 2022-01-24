//
//  Copyright © 2020 Iterable. All rights reserved.
//

import Foundation

struct NetworkConnectivityChecker {
    /// first argument is successfulChecks,
    /// second argument is totalChecks
    /// Should return true if threshold is met
    typealias IsThresholdMet = (Int, Int) -> Bool

    init(networkSession: NetworkSessionProtocol? = nil,
         isThresholdMet: IsThresholdMet? = nil) {
        self.networkSession = networkSession ?? URLSession(configuration: Self.urlSessionConfiguration)
        self.isThresholdMet = isThresholdMet ?? Self.defaultIsThresholdMet
    }

    @discardableResult
    func checkConnectivity() -> Pending<Bool, Never> {
        let result = Fulfill<Bool, Never>()
        let dispatchGroup = DispatchGroup()
        var tasks: [DataTaskProtocol] = []
        var successfulChecks: Int = 0, failedChecks: Int = 0
        let totalChecks = Self.urlsToCheck.count

        let completionHandlerForUrl: (URL) -> NetworkSessionProtocol.CompletionHandler = { url in
            return { data, response, error in
                let success = self.checkSucceeded(for: url, data: data, response: response, error: error)
                success ? (successfulChecks += 1) : (failedChecks += 1)
                dispatchGroup.leave()
                
                // If enough tasks have finished successfully abort early
                self.cancelCheck(
                    pendingTasks: tasks,
                    successfulChecks: successfulChecks,
                    totalChecks: totalChecks
                )
            }
        }

        tasks = Self.urlsToCheck.map {
            return networkSession.createDataTask(with: $0, completionHandler: completionHandlerForUrl($0))
        }

        tasks.forEach { task in
            dispatchGroup.enter()
            tasksQueue.async {
                task.resume()
            }
        }

        dispatchGroup.notify(queue: updateQueue) { [self] in
            let online = self.isThresholdMet(successfulChecks, totalChecks)
            result.resolve(with: online)
        }
        
        return result
    }
    
    private func checkSucceeded(for url: URL, data: Data?, response: URLResponse?, error: Error?) -> Bool {
        if let error = error {
            ITBError("error checking status, error: \(error.localizedDescription)")
            return false
        }
        guard let response = response as? HTTPURLResponse else {
            ITBError("No response")
            return false
        }

        return (200..<300).contains(response.statusCode)
    }

    private func cancelCheck(
        pendingTasks: [DataTaskProtocol],
        successfulChecks: Int,
        totalChecks: Int) {
        let connected = isThresholdMet(successfulChecks, totalChecks)
        guard connected else { return }
        
        cancelPendingTasks(pendingTasks)
    }

    private func cancelPendingTasks(_ tasks: [DataTaskProtocol]) {
        for task in tasks where [.running, .suspended].contains(task.state) {
            task.cancel()
        }
    }

    private static let urlSessionConfiguration: URLSessionConfiguration = {
        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.requestCachePolicy = .reloadIgnoringCacheData
        sessionConfiguration.timeoutIntervalForRequest = 5.0
        sessionConfiguration.timeoutIntervalForResource = 5.0
        return sessionConfiguration
    }()

    private static let urlsToCheck: [URL] = [
        "https://www.apple.com/library/test/success.html",
        "https://www.google.com"
        ].compactMap { URL(string: $0) }
    
    private static let defaultIsThresholdMet: (Int, Int) -> Bool = { value, outOf in
        (Double(value) / Double(outOf)) * 100.0 >= 50.0
    }
    
    private var networkSession: NetworkSessionProtocol
    private var isThresholdMet: IsThresholdMet
    
    private let tasksQueue = DispatchQueue(label: "tasksQueue")
    private var updateQueue = DispatchQueue(label: "updateQueue")
}
