//
//  TranscationModel.swift
//  Finance
//
//  Created by Oliver Tran on 2/16/25.
//

import Foundation
import FirebaseFirestore

final class Transaction: Identifiable, Codable {
    var id: String
    var date: Date
    var name: String
    var amount: Double

    init(id: String, date: Date, name: String, amount: Double) {
        self.id = id
        self.date = date
        self.name = name
        self.amount = amount
    }
    
    init?(document: [String: Any]) {
        guard let id = document["id"] as? String,
              let timestamp = document["date"] as? Timestamp,
              let name = document["name"] as? String,
              let amount = document["amount"] as? Double else {
            return nil
        }
        
        self.id = id
        self.date = timestamp.dateValue()
        self.name = name
        self.amount = amount
    }
}

@MainActor
final class TransactionViewModel: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var totalAmount: Double = 0
    @Published private(set) var user: DBUser? = nil
    private var collection: CollectionReference? = nil
    
    // MARK: - Load User
    func loadCurrentUser() async throws {
        let authDataResult = try AuthenticationManager.shared.getAuthenticatedUser()
        self.user = try await UserManager.shared.getUser(userId: authDataResult.uid)
        collection = Firestore.firestore().collection("users").document(authDataResult.uid).collection("transactions")
    }
    
    func addItem(amount: Double, name: String, date: Date) async throws {
        guard let collection = collection else { return }
        
        let id: String = UUID().uuidString
        let newItem = Transaction(id: id, date: date, name: name, amount: amount)
        
        do {
            let transactionData: [String: Any] = [
                "id": newItem.id,
                "date": Timestamp(date: newItem.date), 
                "name": newItem.name,
                "amount": newItem.amount
            ]
            
            try await collection.document(newItem.id).setData(transactionData)
            
            transactions.append(newItem)
            totalAmount += amount
            
        } catch {
            print("Error adding transaction: \(error.localizedDescription)")
            throw error
        }
    }
    
    func fetchTransactions() async throws {
        guard let collection = collection else { return }

        do {
            let snapshot = try await collection.getDocuments()
            let fetchedTransactions = snapshot.documents.compactMap { Transaction(document: $0.data()) }
            
            DispatchQueue.main.async {
                self.transactions = fetchedTransactions
                self.totalAmount = fetchedTransactions.reduce(0) { $0 + $1.amount }
            }
        } catch {
            print("Error fetching transactions: \(error.localizedDescription)")
            throw error
        }
    }
}
