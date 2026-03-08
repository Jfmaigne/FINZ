import SwiftUI

struct QuestionnaireView: View {
    @EnvironmentObject private var vm: QuestionnaireViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(spacing: 14) {
                    NavigationLink(destination: LivesWithParentsView()) {
                        AnswerRow(emoji: "🏠", title: "Chez tes parents")
                    }
                    .simultaneousGesture(TapGesture().onEnded {
                        vm.livingSituation = .withParents
                    })
                    NavigationLink(destination: LivesAloneView()) {
                        AnswerRow(emoji: "🧍", title: "Seul(e)")
                    }
                    .simultaneousGesture(TapGesture().onEnded {
                        vm.livingSituation = .alone
                    })
                    NavigationLink(destination: LivesColocationView()) {
                        AnswerRow(emoji: "👥", title: "En colocation")
                    }
                    .simultaneousGesture(TapGesture().onEnded {
                        vm.livingSituation = .colocation
                    })
                    NavigationLink(destination: LivesCoupleView()) {
                        AnswerRow(emoji: "💑", title: "En couple")
                    }
                    .simultaneousGesture(TapGesture().onEnded {
                        vm.livingSituation = .couple
                    })
                }
                .padding(.top, 4)

                Spacer(minLength: 0)
            }
            .padding()
        }
        .background(Color(.systemBackground))
        .finzHeader(title: "Tu vis...?")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AnswerRow: View {
    let emoji: String
    let title: String

    var body: some View {
        HStack(spacing: 12) {
            Text(emoji)
                .font(.system(size: 28))

            Text(title)
                .font(.headline)

            Spacer()

            Image(systemName: "chevron.right.circle")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

struct DestinationTemplate: View {
    let title: String

    var body: some View {
        VStack(spacing: 24) {
            Text(title)
                .font(.system(size: 28, weight: .bold, design: .rounded))

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

struct LivesWithParentsView: View {
    @EnvironmentObject private var vm: QuestionnaireViewModel
    @State private var goToTransport = false
    
    private var currencyCode: String { Locale.current.currency?.identifier ?? "EUR" }

    var body: some View {
        Form {
            Section(header: Text("Frais de logement").font(.headline)) {
                Text("Participes-tu aux frais de logement (loyer, électricité, gaz) ?")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                TextField("Montant", value: $vm.housingContribution, format: .currency(code: currencyCode))
                    .keyboardType(.decimalPad)
            }

            Section(header: Text("Frais de vie courante").font(.headline)) {
                Text("Participes-tu aux frais de vie courante ?")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                TextField("Montant", value: $vm.livingContribution, format: .currency(code: currencyCode))
                    .keyboardType(.decimalPad)
            }
        }
        .finzHeader(title: "Chez tes parents")
        .stickyNextButton(enabled: true) { goToTransport = true }
        .background(
            NavigationLink(destination: TransportModeView().environmentObject(vm), isActive: $goToTransport) { EmptyView() }
        )
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct LivesAloneView: View {
    var body: some View {
        DestinationTemplate(title: "Seul(e)")
            .finzHeader(title: "Habitation")
            .stickyNextButton(enabled: true) { }
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct LivesColocationView: View {
    var body: some View {
        DestinationTemplate(title: "En colocation")
            .finzHeader(title: "Habitation")
            .stickyNextButton(enabled: true) { }
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct LivesCoupleView: View {
    var body: some View {
        DestinationTemplate(title: "En couple")
            .finzHeader(title: "Habitation")
            .stickyNextButton(enabled: true) { }
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        QuestionnaireView()
            .environmentObject(QuestionnaireViewModel())
    }
}

