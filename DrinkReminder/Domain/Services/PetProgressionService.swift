import CoreData
import Foundation

enum PetProgressionError: LocalizedError {
    case missingPetProfile

    var errorDescription: String? {
        "The local pet profile is unavailable."
    }
}

@MainActor
final class PetProgressionService {
    private struct ExpectedAward {
        let amount: Int
        let reason: XPAwardReason
        let dayIdentifier: String
        let awardedAt: Date
    }

    private let context: NSManagedObjectContext
    private let clock: any Clock
    private var calendar: Calendar

    init(
        context: NSManagedObjectContext,
        clock: any Clock = SystemClock(),
        calendar: Calendar = .autoupdatingCurrent
    ) {
        self.context = context
        self.clock = clock
        self.calendar = calendar
    }

    func snapshot() throws -> ProgressionSnapshot {
        try synchronizeAwards()
        return try makeSnapshot()
    }

    func record(_ result: HydrationLogResult) throws -> ProgressionUpdate {
        var earnedXP = 0
        earnedXP += try ensureAward(
            key: waterKey(result.logID),
            amount: PetProgressionRules.waterLogXP,
            reason: .waterLog,
            dayIdentifier: result.summary.dayIdentifier,
            awardedAt: clock.now
        )

        if result.summary.totalML >= result.summary.goalML * 0.5 {
            earnedXP += try ensureAward(
                key: halfwayKey(result.summary.dayIdentifier),
                amount: PetProgressionRules.halfwayXP,
                reason: .halfway,
                dayIdentifier: result.summary.dayIdentifier,
                awardedAt: clock.now
            )
        }

        if result.summary.isGoalReached {
            earnedXP += try ensureAward(
                key: goalKey(result.summary.dayIdentifier),
                amount: PetProgressionRules.dailyGoalXP,
                reason: .dailyGoal,
                dayIdentifier: result.summary.dayIdentifier,
                awardedAt: result.summary.goalReachedAt ?? clock.now
            )

            let streak = try streakStatistics()
            if streak.current >= 2 {
                earnedXP += try ensureAward(
                    key: streakKey(result.summary.dayIdentifier),
                    amount: PetProgressionRules.streakDayXP,
                    reason: .streak,
                    dayIdentifier: result.summary.dayIdentifier,
                    awardedAt: result.summary.goalReachedAt ?? clock.now
                )
            }
        }

        try synchronizeAwards(lastInteractionAt: clock.now)
        return ProgressionUpdate(snapshot: try makeSnapshot(), earnedXP: earnedXP)
    }

    func reconcileAfterUndo() throws -> ProgressionSnapshot {
        try synchronizeAwards()
        return try makeSnapshot()
    }

    private func synchronizeAwards(lastInteractionAt: Date? = nil) throws {
        let days = try fetchDays()
        let existing = try fetchAwards()
        var existingByKey = Dictionary(uniqueKeysWithValues: existing.map { ($0.eventKey, $0) })
        var expected: [String: ExpectedAward] = [:]
        var previousCompletedDate: Date?
        var completedRun = 0

        for day in days {
            let logs = day.logs.filter { !$0.isDeleted }.sorted { $0.loggedAt < $1.loggedAt }
            for log in logs {
                expected[waterKey(log.id)] = ExpectedAward(
                    amount: PetProgressionRules.waterLogXP,
                    reason: .waterLog,
                    dayIdentifier: day.dayIdentifier,
                    awardedAt: log.loggedAt
                )
            }

            if day.totalML >= day.goalML * 0.5 {
                expected[halfwayKey(day.dayIdentifier)] = ExpectedAward(
                    amount: PetProgressionRules.halfwayXP,
                    reason: .halfway,
                    dayIdentifier: day.dayIdentifier,
                    awardedAt: thresholdDate(in: logs, threshold: day.goalML * 0.5) ?? day.dayStart
                )
            }

            if day.summary.isGoalReached {
                if let previousCompletedDate,
                   calendar.dateComponents([.day], from: previousCompletedDate, to: day.dayStart).day == 1 {
                    completedRun += 1
                } else {
                    completedRun = 1
                }
                previousCompletedDate = day.dayStart

                expected[goalKey(day.dayIdentifier)] = ExpectedAward(
                    amount: PetProgressionRules.dailyGoalXP,
                    reason: .dailyGoal,
                    dayIdentifier: day.dayIdentifier,
                    awardedAt: day.goalReachedAt ?? thresholdDate(in: logs, threshold: day.goalML) ?? day.dayStart
                )

                if completedRun >= 2 {
                    expected[streakKey(day.dayIdentifier)] = ExpectedAward(
                        amount: PetProgressionRules.streakDayXP,
                        reason: .streak,
                        dayIdentifier: day.dayIdentifier,
                        awardedAt: day.goalReachedAt ?? day.dayStart
                    )
                }
            } else {
                completedRun = 0
                previousCompletedDate = nil
            }
        }

        for (key, value) in expected {
            let award: XPAwardEntity
            if let existingAward = existingByKey.removeValue(forKey: key) {
                award = existingAward
            } else {
                award = XPAwardEntity(context: context)
                award.id = UUID()
            }
            award.eventKey = key
            award.amount = Int64(value.amount)
            award.reason = value.reason
            award.awardedAt = value.awardedAt
            award.dayIdentifier = value.dayIdentifier
        }

        for staleAward in existingByKey.values {
            context.delete(staleAward)
        }

        try updatePetTotalAndSave(lastInteractionAt: lastInteractionAt)
    }

    private func makeSnapshot() throws -> ProgressionSnapshot {
        let pet = try fetchPet()
        return ProgressionSnapshot(
            streak: try streakStatistics(),
            pet: PetProgressionRules.progress(totalXP: Int(pet.totalXP))
        )
    }

    private func streakStatistics() throws -> StreakStatistics {
        StreakCalculator.statistics(
            from: try fetchDays().map(\.summary),
            today: clock.now,
            calendar: calendar
        )
    }

    @discardableResult
    private func ensureAward(
        key: String,
        amount: Int,
        reason: XPAwardReason,
        dayIdentifier: String,
        awardedAt: Date
    ) throws -> Int {
        let request = NSFetchRequest<XPAwardEntity>(entityName: "XPAwardEntity")
        request.predicate = NSPredicate(format: "eventKey == %@", key)
        request.fetchLimit = 1
        if try context.fetch(request).first != nil { return 0 }

        let award = XPAwardEntity(context: context)
        award.id = UUID()
        award.eventKey = key
        award.amount = Int64(amount)
        award.reason = reason
        award.awardedAt = awardedAt
        award.dayIdentifier = dayIdentifier
        return amount
    }

    private func updatePetTotalAndSave(lastInteractionAt: Date?) throws {
        let pet = try fetchPet()
        let awards = try fetchAwards()
        pet.totalXP = awards.filter { !$0.isDeleted }.reduce(0) { $0 + $1.amount }
        if let lastInteractionAt {
            pet.lastInteractionAt = lastInteractionAt
        }
        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }

    private func fetchPet() throws -> PetProfileEntity {
        let request = NSFetchRequest<PetProfileEntity>(entityName: "PetProfileEntity")
        request.fetchLimit = 1
        guard let pet = try context.fetch(request).first else {
            throw PetProgressionError.missingPetProfile
        }
        return pet
    }

    private func fetchDays() throws -> [HydrationDayEntity] {
        let request = NSFetchRequest<HydrationDayEntity>(entityName: "HydrationDayEntity")
        request.sortDescriptors = [NSSortDescriptor(key: "dayStart", ascending: true)]
        return try context.fetch(request)
    }

    private func fetchAwards() throws -> [XPAwardEntity] {
        try context.fetch(NSFetchRequest<XPAwardEntity>(entityName: "XPAwardEntity"))
    }

    private func thresholdDate(in logs: [WaterLogEntity], threshold: Double) -> Date? {
        var total = 0.0
        for log in logs {
            total += log.volumeML
            if total >= threshold { return log.loggedAt }
        }
        return nil
    }

    private func waterKey(_ logID: UUID) -> String { "water:\(logID.uuidString)" }
    private func halfwayKey(_ dayIdentifier: String) -> String { "halfway:\(dayIdentifier)" }
    private func goalKey(_ dayIdentifier: String) -> String { "goal:\(dayIdentifier)" }
    private func streakKey(_ dayIdentifier: String) -> String { "streak:\(dayIdentifier)" }
}
