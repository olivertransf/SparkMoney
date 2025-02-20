//
//  ContentView.swift
//  Finance
//
//  Created by Oliver Tran on 2/16/25.
//

import SwiftUI

struct ContentView: View {
    @State private var showSignInView: Bool = false
    @State private var selectedView: SelectedView? = .transaction

    var body: some View {
        ZStack {
            if !showSignInView {
                NavigationSplitView {
                    List(selection: $selectedView) {
                        Section(header: Text("Main")) {
                            NavigationLink(value: SelectedView.transaction) {
                                Label("Transactions", systemImage: "list.bullet")
                            }
                            NavigationLink(value: SelectedView.profile) {
                                Label("Profile", systemImage: "person")
                            }
                        }
                    }
                    .navigationTitle("Menu")
                } detail: {
                    switch selectedView {
                    case .home:
                        ContentView()
                    case .transaction:
                        TransactionView()
                    case .profile:
                        ProfileView(showSignInView: $showSignInView)
                    case .none:
                        Text("Select a view")
                            .font(.title)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .onAppear {
            let authUser = try? AuthenticationManager.shared.getAuthenticatedUser()
            showSignInView = authUser == nil
        }
        .fullScreenCover(isPresented: $showSignInView) {
            NavigationStack {
                AuthenticationView(showSignInView: $showSignInView)
            }
        }
    }
}

// Enum to manage selected views
enum SelectedView: Hashable {
    case home
    case transaction
    case profile
}
