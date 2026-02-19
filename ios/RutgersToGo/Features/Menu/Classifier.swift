import Foundation

enum ClassificationStatus: String {
    case safe, avoid, uncertain
}

struct ClassificationResult {
    let status: ClassificationStatus
    let matchedAllergens: [String]
    let reasons: [String]
}

struct Classifier {
    static let keywordMap: [String: [String]] = [
        "dairy": ["milk","cheese","butter","whey","casein","yogurt","cream"],
        "peanut": ["peanut","peanuts"],
        "tree_nut": ["almond","walnut","pecan","cashew","hazelnut","pistachio"],
        "egg": ["egg","egg yolk","egg white"],
        "soy": ["soy","soybean","tofu","soy lecithin"],
        "wheat": ["wheat","bran","semolina","bulgur","durum","gluten"],
        "fish": ["salmon","tuna","anchovy","cod","fish"],
        "shellfish": ["shrimp","crab","lobster","crabmeat","clam","oyster"],
        "sesame": ["sesame","tahini","sesame seed"]
    ]

    static func classify(name: String, ingredients: String?) -> ClassificationResult {
        guard let ing = ingredients?.lowercased(), !ing.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return ClassificationResult(status: .uncertain, matchedAllergens: [], reasons: ["Ingredients missing or unavailable"]) }

        var matched: [String] = []
        var reasons: [String] = []

        for (allergen, keywords) in keywordMap {
            for kw in keywords {
                if ing.contains(kw) {
                    matched.append(allergen)
                    reasons.append("Found keyword '\(kw)' for allergen \(allergen)")
                    break
                }
            }
        }

        if !matched.isEmpty {
            return ClassificationResult(status: .avoid, matchedAllergens: matched, reasons: reasons)
        }

        return ClassificationResult(status: .safe, matchedAllergens: [], reasons: ["No matching allergens found in ingredients"]) 
    }

    // Helper for passing row dicts
    static func classifyRow(item: [String: Any]) -> ClassificationResult {
        let name = item["name"] as? String ?? ""
        let ingredients = item["ingredients"] as? String
        return classify(name: name, ingredients: ingredients)
    }
}
