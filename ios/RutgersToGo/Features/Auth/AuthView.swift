import SwiftUI

struct AuthView: View {
    @StateObject private var vm = AuthViewModel()
    @State private var showOtp = false

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                TextField("Email", text: $vm.email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(8)

                Button(action: {
                    Task { await vm.sendCode(); showOtp = true }
                }) {
                    HStack { Spacer(); Text("Send code"); Spacer() }
                }
                .buttonStyle(.borderedProminent)

                if case .error(let msg) = vm.state {
                    Text(msg).foregroundColor(.red)
                }

                NavigationLink(destination: OtpVerifyView(email: vm.email, vm: vm), isActive: $showOtp) { EmptyView() }
            }
            .padding()
            .navigationTitle("Sign in")
        }
    }
}

struct OtpVerifyView: View {
    let email: String
    @ObservedObject var vm: AuthViewModel
    @State private var code: String = ""

    var body: some View {
        VStack(spacing: 16) {
            Text("Enter code sent to \(email)")
            TextField("6-digit code", text: $vm.code)
                .keyboardType(.numberPad)
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(8)

            Button("Verify") {
                Task { await vm.verify() }
            }
            .buttonStyle(.borderedProminent)

            if case .error(let msg) = vm.state {
                Text(msg).foregroundColor(.red)
            }
        }
        .padding()
        .navigationTitle("Verify")
    }
}
