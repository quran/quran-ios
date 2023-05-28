//
//  Result+Extension.swift
//
//
//  Created by Mohamed Afifi on 2023-05-27.
//

extension Swift.Result where Failure == Error {
    public init(_ body: () async throws -> Success) async {
        do {
            self = .success(try await body())
        } catch {
            self = .failure(error)
        }
    }
}
