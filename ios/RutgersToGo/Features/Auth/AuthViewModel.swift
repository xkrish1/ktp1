import Foundation
import Combine

@MainActor
final class AuthViewModel: ObservableObject {
    enum State { case idle, sending, verifying, authenticated, error(String) }

    @Published var state: State = .idle
    @Published var email: String = ""
    @Published var code: String = ""

    private let client = SupabaseClient.shared

    func sendCode() async {
        state = .sending
        do {
            try await client.signInWithOtp(email: email)
            state = .idle
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func verify() async {
        state = .verifying
        do {
            try await client.verifyOtp(email: email, token: code)
            state = .authenticated
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}
