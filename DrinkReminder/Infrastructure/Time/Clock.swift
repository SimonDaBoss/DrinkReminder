import Foundation

protocol Clock {
    var now: Date { get }
}

struct SystemClock: Clock {
    var now: Date { Date() }
}

struct FixedClock: Clock {
    let now: Date
}
