import Foundation

struct AccountStore: Codable {
    var version: Int = 1
    var accounts: [StoredAccount] = []
    var currentSelection: CurrentAccountSelection?
}

struct StoredAccount: Codable, Identifiable {
    var id: String
    var label: String
    var email: String?
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

    var effectivePlanType: String? {
        let trimmedPlanType = planType?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !trimmedPlanType.isEmpty {
            return trimmedPlanType
        }
        return usage?.planType
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
    var credits: UsageCredits?
    var fetchedAt: Int64?
    var fiveHour: UsageWindow?
    var oneWeek: UsageWindow?
    var planType: String?
}

struct UsageCredits: Codable {
    var hasCredits: Bool?
    var unlimited: Bool?
}

struct UsageWindow: Codable {
    var resetAt: Int64?
    var usedPercent: Double?
    var windowSeconds: Int64?

    var remainingPercent: Double? {
        guard let usedPercent else {
            return nil
        }
        return min(max(100 - usedPercent, 0), 100)
    }
}
