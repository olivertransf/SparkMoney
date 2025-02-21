import SwiftUI

struct TransactionView: View {
    @StateObject private var viewModel = TransactionViewModel()

    @State private var transactionName: String = ""
    @State private var transactionAmount: Double = 0
    @State private var transactionDate: Date = .now
    @State private var saveAmount: Double = 0
    @State private var spendAmount: Double = 0
    @State private var giveAmount: Double = 0

    var body: some View {
        VStack {
            Text("Total: $\(viewModel.totalAmount, specifier: "%.2f")")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()

            // Input Section
            VStack(spacing: 15) {
                TextField("Enter transaction name", text: $transactionName)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 22))
                
                HStack {
                    TextField("Amount", text: Binding(
                        get: { transactionAmount == 0 ? "" : String(transactionAmount) },
                        set: { transactionAmount = Double($0) ?? 0 }
                    ))
                    .keyboardType(.decimalPad)

                    DatePicker("", selection: $transactionDate, displayedComponents: [.date])
                        .labelsHidden()
                }

                VStack {
                    Text("Allocate the transaction amount")

                    Slider(value: $saveAmount, in: 0...(transactionAmount - spendAmount - giveAmount))
                    Text("Save: \(saveAmount, specifier: "%.2f")")

                    Slider(value: $spendAmount, in: 0...(transactionAmount - saveAmount - giveAmount))
                    Text("Spend: \(spendAmount, specifier: "%.2f")")

                    Slider(value: $giveAmount, in: 0...(transactionAmount - saveAmount - spendAmount))
                    Text("Give: \(giveAmount, specifier: "%.2f")")
                }
                .padding()

                Button(action: {
                    guard !transactionName.isEmpty, transactionAmount != 0, saveAmount + spendAmount + giveAmount == transactionAmount else { return }

                    Task {
                        do {
                            try await viewModel.addItem(
                                name: transactionName,
                                date: transactionDate,
                                totalAmount: transactionAmount,
                                saveAmount: saveAmount,
                                spendAmount: spendAmount,
                                giveAmount: giveAmount
                            )
                            
                            // Reset fields
                            transactionAmount = 0
                            transactionName = ""
                            saveAmount = 0
                            spendAmount = 0
                            giveAmount = 0
                            
                        } catch {
                            print("Error adding transaction: \(error.localizedDescription)")
                        }
                    }
                }) {
                    Text("Enter")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(transactionName.isEmpty || saveAmount + spendAmount + giveAmount != transactionAmount || transactionAmount == 0 ? Color.gray :
                                    (transactionAmount < 0 ? .red : .green))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(transactionName.isEmpty || transactionAmount == 0)
            }
            .padding()
            .background(Color(.systemGray6))
            
            // Display Transactions
            List {
                ForEach(viewModel.transactions) { transaction in
                    VStack(alignment: .leading) {
                        HStack {
                            Text(transaction.name)
                                .font(.headline)
                            
                            Spacer()
                            
                            Text("\(transaction.date.formatted(date: .abbreviated, time: .omitted))")
                               .font(.caption)
                               .foregroundColor(.gray)
                            
                            Button(action: {
                                Task {
                                    do {
                                        try await viewModel.deleteItem(transaction: transaction)
                                    } catch {
                                        print("Error deleting transaction: \(error.localizedDescription)")
                                    }
                                }
                            }) {
                                Image(systemName: "trash")
                                    .foregroundStyle(.red)
                            }
                        }

                        Text("Total: \(transaction.totalAmount, specifier: "%.2f") USD")
                            .foregroundColor(.primary)

                        HStack {
                            Text("💰 Save: \(transaction.saveAmount, specifier: "%.2f")").foregroundColor(.blue)
                            Text("🛒 Spend: \(transaction.spendAmount, specifier: "%.2f")").foregroundColor(.green)
                            Text("🎁 Give: \(transaction.giveAmount, specifier: "%.2f")").foregroundColor(.orange)
                        }
                        .font(.caption)
                    }
                }
            }
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
