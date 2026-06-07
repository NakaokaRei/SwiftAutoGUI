import Foundation

enum NonMaximumSuppression {
    static func apply(to sortedMatches: [ImageMatch]) -> [ImageMatch] {
        var selected: [ImageMatch] = []

        for candidate in sortedMatches {
            if selected.allSatisfy({ overlapRatio(candidate, $0) < 0.5 }) {
                selected.append(candidate)
            }
        }

        return selected
    }

    private static func overlapRatio(_ lhs: ImageMatch, _ rhs: ImageMatch) -> Double {
        let intersectionWidth = max(
            0,
            min(lhs.x + lhs.width, rhs.x + rhs.width) - max(lhs.x, rhs.x)
        )
        let intersectionHeight = max(
            0,
            min(lhs.y + lhs.height, rhs.y + rhs.height) - max(lhs.y, rhs.y)
        )
        let intersectionArea = intersectionWidth * intersectionHeight
        let minimumArea = min(lhs.width * lhs.height, rhs.width * rhs.height)

        guard minimumArea > 0 else { return 0 }
        return Double(intersectionArea) / Double(minimumArea)
    }
}
