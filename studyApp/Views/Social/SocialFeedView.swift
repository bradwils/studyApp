import SwiftUI

struct SocialView: View {
    /// Dedicated ViewModel keeps the feed data and summary in one place.
    @StateObject private var viewModel = SocialFeedViewModel()
    @Environment(\.colorScheme) var colorScheme
    
    private var backgroundGradient: some View {
        ZStack {
            RadialGradient(
                colors: colorScheme == .dark
                ? [Color.yellow.opacity(0.8), Color.black.opacity(0.8)]
                : [Color.yellow.opacity(0.8), Color.white.opacity(0.8)],
                center: .center,
                startRadius: 100,
                endRadius: 400
            )
            .ignoresSafeArea()
            .frame(height: 300)
            
            // Linear gradient overlaid on top
            LinearGradient(
                colors: [Color.white.opacity(0.5), Color.pink.opacity(0.5), Color.blue.opacity(0.5)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .frame(height: 300)
            
            LinearGradient(
                colors: [Color.blue.opacity(0.5), Color.purple.opacity(0.5)],
                startPoint: .leading,
                endPoint: .trailing
            )
            .ignoresSafeArea()
            .frame(height: 300)
            
            LinearGradient(
                colors: colorScheme == .dark
                ? [Color.black.opacity(0), Color.black.opacity(1)]
                : [Color.white.opacity(0), Color.white.opacity(1)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .frame(height: 300)
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            backgroundGradient
                .allowsHitTesting(false)
                .ignoresSafeArea(edges: .top)

            ScrollView {
                VStack(spacing: 16) {
                    DashboardHeader(
                        currentSessionTime: viewModel.currentSessionTime,
                        currentSubject: viewModel.currentSubject,
                        streakCount: viewModel.streakCount,
                        totalDailyTime: viewModel.totalDailyTime
                    )
                    .padding(.horizontal, 10)

                    LazyVStack(spacing: 5) {
                        ForEach(viewModel.items) { item in
                            NavigationLink {
                                StudyMemberDetailView(memberName: item.name)
                            } label: {
                                StudyItemCard(item: item)
                                    .padding(.horizontal, 15)
                            }
                            .buttonStyle(.plain)
                            .padding(.bottom, 5)
                        }
                    }
                    .padding(.top, 16)
                    .scrollIndicators(.hidden)
                    .scrollEdgeEffectStyle(.automatic, for: .top)
                }
            }
        }
        .navigationBarTitle("Social", displayMode: .inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .background(colorScheme == .dark ? Color.black : Color.white)
    }
    
}

#Preview {
    SocialView()
}
