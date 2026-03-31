import Foundation

struct AccountStore: Codable {
    var version: Int = 1
    var accounts: [StoredAccount] = []
    var currentSelection: CurrentAccountSelection?
}

struct StoredAccount: Codable {
    var id: String
    var label: String
    var email: String?
    var note: String?
    var accountID: String
    var planType: String?
    var teamName: String?
    var usage: AccountUsage?
    var authJSON: JSONValue
    var addedAt: Int64
    var updatedAt: Int64

    enum CodingKeys: String, CodingKey {
        case id
        case label
        case email
        case note
        case accountID = "accountId"
        case planType
        case teamName
        case usage
        case authJSON = "authJson"
        case addedAt
        case updatedAt
    }
}

struct CurrentAccountSelection: Codable {
    var accountID: String
    var selectedAt: Int64
    var sourceDeviceID: String
}

struct AccountSummary: Identifiable {
    var id: String
    var label: String
    var email: String?
    var note: String?
    var accountID: String
    var planType: String?
    var teamName: String?
    var usage: AccountUsage?
    var isCurrent: Bool

    var displayName: String {
        let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            return trimmed
        }
        if let email, !email.isEmpty {
            return email
        }
        return accountID
    }

    var maskedEmail: String? {
        guard let email else {
            return nil
        }
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }
        return trimmed.maskedEmailKeepingPrefixAndDomain()
    }

    var maskedDisplayName: String {
        let trimmedLabel = label.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedLabel.isEmpty {
            return trimmedLabel.maskedEmailKeepingPrefixAndDomain()
        }
        if let maskedEmail {
            return maskedEmail
        }
        return accountID
    }

    var effectivePlanType: String? {
        let trimmedPlanType = planType?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !trimmedPlanType.isEmpty {
            return trimmedPlanType
        }
        return usage?.planType
    }

    var fiveHourRemainingPercent: Double? {
        usage?.fiveHour?.remainingPercent
    }

    var oneWeekRemainingPercent: Double? {
        usage?.oneWeek?.remainingPercent
    }

    var oneWeekUsedPercent: Double? {
        usage?.oneWeek?.usedPercent
    }

    var visibleResetAt: Int64? {
        usage?.oneWeek?.resetAt
    }

    var trimmedNote: String? {
        let trimmed = note?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }
}

private extension String {
    func maskedEmailKeepingPrefixAndDomain() -> String {
        guard let atIndex = firstIndex(of: "@"), atIndex != startIndex else {
            return self
        }

        let localPart = self[..<atIndex]
        let domainPart = self[atIndex...]
        let visiblePrefix = localPart.prefix(3)
        return "\(visiblePrefix)***\(domainPart)"
    }
}

struct ExtractedAuth {
    var accountID: String
    var email: String?
}

struct ChatGPTOAuthTokens {
    var accessToken: String
    var refreshToken: String
    var idToken: String
    var apiKey: String?
}

struct AccountUsage: Codable {
    var fiveHour: UsageWindow?
    var oneWeek: UsageWindow?
    var planType: String?
}

struct UsageWindow: Codable {
    var resetAt: Int64?
    var usedPercent: Double?

    var remainingPercent: Double? {
        guard let usedPercent else {
            return nil
        }
        return min(max(100 - usedPercent, 0), 100)
    }

    var hidesResetCaptionForFiveHour: Bool {
        guard let usedPercent, usedPercent <= 0.01,
              let remainingPercent,
              remainingPercent >= 99.5 else {
            return false
        }
        return true
    }
}
