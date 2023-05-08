//
//  SystemTimeFake.swift
//
//
//  Created by Mohamed Afifi on 2023-05-07.
//

import Foundation
@testable import QuranAudioKit

final class SystemTimeFake: SystemTime {
    var now = Date(timeIntervalSinceReferenceDate: 0)
}
