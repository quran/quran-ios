//
//  BackendServices.swift
//  Quran
//
//  Created by Mohamed Afifi on 2/25/17.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2017  Quran.com
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//

import Foundation
import Moya

enum BackendServices {
    case translations
}

extension BackendServices: TargetType {

    var baseURL: URL {
        return QuranURLs.Host
    }

    var path: String {
        switch self {
        case .translations: return "/data/translations.php"
        }
    }

    var method: Moya.Method {
        switch self {
        case .translations: return .get
        }
    }

    var parameters: [String : Any]? {
        switch self {
        case .translations: return ["v": "4"]
        }
    }

    var parameterEncoding: ParameterEncoding {
        switch self {
        case .translations: return URLEncoding.default
        }
    }

    var sampleData: Data {
        switch self {
        case .translations: return "{ \"data\": [ { \"id\": 54, \"displayName\": \"Albanian Translation\", \"translator\": \"Sherif Ahmeti\", \"translator_foreign\": \"test\", \"fileUrl\": \"http://android.quran.com/data/getTranslation.php?id=54\", \"fileName\": \"quran.al.ahmeti.db\", \"saveTo\": \"databases\", \"downloadType\": \"translation\", \"minimum_version\": 1, \"current_version\": 2 }}".utf8Encoded // swiftlint:disable:this line_length
        }
    }

    var task: Task {
        switch self {
        case .translations: return .request
        }
    }

    var validate: Bool {
        switch self {
        case .translations: return true
        }
    }
}

// MARK: - Helpers
private extension String {
    var urlEscaped: String {
        return cast(self.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed))
    }

    var utf8Encoded: Data {
        return cast(self.data(using: .utf8))
    }
}
