import Foundation

enum DateFormatting {
    static var dayFormatter: DateFormatter {
        makeFormatter(pattern: "yyyy-MM-dd")
    }

    static func dayID(from date: Date) -> String {
        dayFormatter.string(from: date)
    }

    static func normalizedDayID(fromSheetValue value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }

        for format in supportedDateFormats {
            let formatter = makeFormatter(pattern: format)
            if let date = formatter.date(from: trimmed) {
                return dayFormatter.string(from: date)
            }
        }

        return nil
    }

    private static let supportedDateFormats = [
        "yyyy-MM-dd",
        "M/d/yyyy",
        "M/d/yy",
        "MM/dd/yyyy",
        "MM/dd/yy"
    ]

    private static func makeFormatter(pattern: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = pattern
        return formatter
    }
}
