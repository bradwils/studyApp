import SwiftUI

struct StudyMemberDetailView: View {
    var memberName: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Space.l) {
                profileCard

                SectionHeader(title: "Recent Activity", tint: DS.Color.active)

                // Mock values until member stats have a data source.
                HStack(spacing: 0) {
                    StatCell(
                        systemImage: "flame.fill",
                        tint: DS.Color.streak,
                        label: "Streak",
                        value: "5 days"
                    )
                    Divider().padding(.vertical, DS.Space.s)
                    StatCell(
                        systemImage: "timer",
                        tint: DS.Color.active,
                        label: "Today",
                        value: "2h 15m",
                        alignment: .center
                    )
                    Divider().padding(.vertical, DS.Space.s)
                    StatCell(
                        systemImage: "book.fill",
                        tint: .indigo,
                        label: "Subject",
                        value: "Mathematics",
                        alignment: .trailing
                    )
                }
                .surfaceCard()
            }
            .padding(DS.Space.l)
        }
        .navigationTitle(memberName)
        .toolbarTitleDisplayMode(.inline)
    }

    private var profileCard: some View {
        VStack(spacing: DS.Space.m) {
            AvatarBadge(name: memberName, tint: DS.Color.active, size: 64)
            Text(memberName)
                .font(.title2.weight(.semibold))
        }
        .frame(maxWidth: .infinity)
        .surfaceCard()
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack {
        StudyMemberDetailView(memberName: "Preview User")
    }
}
