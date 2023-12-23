//
//  Error+Extension.swift
//
//
//  Created by Mohamed Afifi on 2023-12-19.
//

import Foundation

extension Error {
    public var isCancelled: Bool {
        if self is CancellationError {
            return true
        }

        do {
            throw self
        } catch URLError.cancelled {
            return true
        } catch CocoaError.userCancelled {
            return true
        } catch {
            return false
        }
    }
}
