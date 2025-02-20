//
//  RootView.swift
//  SparkMoney
//
//  Created by Oliver Tran on 2/18/25.
//

import SwiftUI

struct TransactionView: View {
    @StateObject private var viewModel = TransactionViewModel()
    
    @State private var transactionName: String = ""
    @State private var transactionAmount: Double = 0
    @State private var transactionDate: Date = .now
    
    var body: some View {
        VStack() {
            Text("Total: $\(viewModel.totalAmount, specifier: "%.2f")")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding([.top, .leading, .trailing])
                .frame(maxWidth: .infinity)
                .cornerRadius(10)

            // Input Section
            VStack(spacing: 15) {
                TextField("Enter transaction name", text: $transactionName)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 22))

                HStack {
                    TextField("Amount", text: Binding(
                        get: { String(format: "%.2f", transactionAmount) },
                        set: { transactionAmount = Double($0) ?? 0 }
                    ))
                    .keyboardType(.decimalPad)
                    
                    DatePicker("", selection: $transactionDate, displayedComponents: [.date])
                        .labelsHidden()
                }

                Button(action: {
                    guard !transactionName.isEmpty, transactionAmount != 0 else { return }
                    
                    Task {
                        do {
                            try await viewModel.addItem(amount: transactionAmount, name: transactionName, date: transactionDate)
                            transactionAmount = 0
                            transactionName = ""
                        } catch {
                            print("Error adding transaction: \(error.localizedDescription)")
                        }
                    }
                }) {
                    Text("Enter")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(transactionName.isEmpty || transactionAmount == 0 ? Color.gray : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(transactionName.isEmpty || transactionAmount == 0)
            }
            .padding()
            .background(Color(.systemGray6))
            
            
            List {
                ForEach(viewModel.transactions) { transaction in
                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text(transaction.name)
                                    .font(.headline)
                                    .fontWeight(.bold)
                                
                                Text("\(transaction.amount, specifier: "%.2f") USD")
                                    .font(.headline)
                                    .foregroundColor(.green)
                                
                                Spacer()
                                
                                Text("\(transaction.date.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
        .onAppear {
            Task {
                do {
                    try await viewModel.loadCurrentUser()
                    try await viewModel.fetchTransactions()
                } catch {
                    print("Error loading data: \(error.localizedDescription)")
                }
            }
        }
        .padding()
    }
    
}

#Preview {
    TransactionView()
}
