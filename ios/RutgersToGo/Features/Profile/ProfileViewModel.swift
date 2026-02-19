import Foundation
import Combine

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var selectedAllergens: Set<String> = []
    @Published var selectedRestrictions: Set<String> = []
    @Published var errorMessage: String?

    private let repo = ProfileRepo()

    let allergenKeys = ["peanut","tree_nut","dairy","egg","soy","wheat","fish","shellfish","sesame"]
    let restrictionKeys = ["halal","vegetarian","vegan","gluten_free","low_sodium"]

    func load() async {
        do {
            if let dict = try await repo.fetchProfile() {
                if let a = dict["allergens"] as? [String] { selectedAllergens = Set(a) }
                if let r = dict["restrictions"] as? [String] { selectedRestrictions = Set(r) }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func save(userId: String) async {
        do {
            try await repo.upsertProfile(userId: userId, allergens: Array(selectedAllergens), restrictions: Array(selectedRestrictions), severity: [:])
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
