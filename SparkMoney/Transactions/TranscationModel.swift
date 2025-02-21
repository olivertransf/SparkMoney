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
    var totalAmount: Double
    var saveAmount: Double
    var spendAmount: Double
    var giveAmount: Double

    init(id: String, date: Date, name: String, totalAmount: Double, saveAmount: Double, spendAmount: Double, giveAmount: Double) {
        self.id = id
        self.date = date
        self.name = name
        self.totalAmount = totalAmount
        self.saveAmount = saveAmount
        self.spendAmount = spendAmount
        self.giveAmount = giveAmount
    }
    
    init?(document: [String: Any]) {
        guard let id = document["id"] as? String,
              let timestamp = document["date"] as? Timestamp,
              let name = document["name"] as? String,
              let totalAmount = document["totalAmount"] as? Double,
              let saveAmount = document["saveAmount"] as? Double,
              let spendAmount = document["spendAmount"] as? Double,
              let giveAmount = document["giveAmount"] as? Double else {
            return nil
        }
        
        self.id = id
        self.date = timestamp.dateValue()
        self.name = name
        self.totalAmount = totalAmount
        self.saveAmount = saveAmount
        self.spendAmount = spendAmount
        self.giveAmount = giveAmount
    }
}

import Foundation
import FirebaseFirestore

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

    // MARK: - Add Transaction
    func addItem(name: String, date: Date, totalAmount: Double, saveAmount: Double, spendAmount: Double, giveAmount: Double) async throws {
        guard let collection = collection else { return }

        let id: String = UUID().uuidString
        let newItem = Transaction(id: id, date: date, name: name, totalAmount: totalAmount, saveAmount: saveAmount, spendAmount: spendAmount, giveAmount: giveAmount)

        do {
            let transactionData: [String: Any] = [
                "id": newItem.id,
                "date": Timestamp(date: newItem.date),
                "name": newItem.name,
                "totalAmount": newItem.totalAmount,
                "saveAmount": newItem.saveAmount,
                "spendAmount": newItem.spendAmount,
                "giveAmount": newItem.giveAmount
            ]

            try await collection.document(newItem.id).setData(transactionData)

            DispatchQueue.main.async {
                self.transactions.append(newItem)
                self.totalAmount += totalAmount
            }
        } catch {
            print("Error adding transaction: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Delete Transaction
    func deleteItem(transaction: Transaction) async throws {
        guard let collection = collection else { return }

        do {
            try await collection.document(transaction.id).delete()
            
            DispatchQueue.main.async {
                self.transactions.removeAll { $0.id == transaction.id }
                self.totalAmount -= transaction.totalAmount
            }
        } catch {
            print("Error deleting transaction: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Fetch Transactions
    func fetchTransactions() async throws {
        guard let collection = collection else { return }

        do {
            let snapshot = try await collection.getDocuments()
            let fetchedTransactions = snapshot.documents.compactMap {
                Transaction(document: $0.data())
            }.sorted { $0.date > $1.date }

            DispatchQueue.main.async {
                self.transactions = fetchedTransactions
                self.totalAmount = fetchedTransactions.reduce(0) { $0 + $1.totalAmount }
            }
        } catch {
            print("Error fetching transactions: \(error.localizedDescription)")
            throw error
        }
    }
}
