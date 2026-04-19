import SwiftUI
import Charts

struct InsightsView: View {
    @Environment(StatsViewModel.self) private var statsVM
    @Environment(AuthViewModel.self) private var authVM
    @State private var chartScope: ChartScope = .month
    @State private var showGoalEditor = false
    @State private var goalDraft = ""

    enum ChartScope: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"

        var calendarComponent: Calendar.Component {
            switch self {
            case .week: return .weekOfYear
            case .month: return .month
            case .year: return .year
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Annual goal ring
                    VStack(spacing: 12) {
                        Text("Annual Goal").font(.headline)
                        ZStack {
                            Circle()
                                .stroke(.quaternary, lineWidth: 16)
                            Circle()
                                .trim(from: 0, to: statsVM.annualProgress)
                                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                                .animation(.easeOut, value: statsVM.annualProgress)

                            VStack(spacing: 4) {
                                let thisYear = statsVM.readBooks.filter {
                                    Calendar.current.component(.year, from: $0.updatedAt) == Calendar.current.component(.year, from: Date())
                                }.count
                                Text("\(thisYear)").font(.largeTitle.bold())
                                Text("of \(statsVM.annualGoal) books").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        .frame(width: 160, height: 160)

                        Button("Set Goal") { showGoalEditor = true }
                            .font(.caption)
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))

                    // Summary stats
                    HStack(spacing: 16) {
                        StatCard(title: "Books Read", value: "\(statsVM.totalBooksRead)", icon: "book.closed.fill")
                        StatCard(title: "Words Read", value: statsVM.totalWordsRead.formatted(.number.notation(.compactName)), icon: "text.alignleft")
                    }

                    // Chart
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Reading Volume").font(.headline)
                            Spacer()
                            Picker("Scope", selection: $chartScope) {
                                ForEach(ChartScope.allCases, id: \.self) {
                                    Text($0.rawValue).tag($0)
                                }
                            }
                            .pickerStyle(.segmented)
                            .fixedSize()
                        }

                        let data = statsVM.booksRead(in: chartScope.calendarComponent)
                        Chart(data, id: \.key) { item in
                            BarMark(
                                x: .value("Period", item.key, unit: chartScope.calendarComponent),
                                y: .value("Books", item.value)
                            )
                            .foregroundStyle(Color.accentColor)
                        }
                        .chartXAxis {
                            AxisMarks(values: .stride(by: chartScope.calendarComponent))
                        }
                        .frame(height: 180)
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                }
                .padding()
            }
            .navigationTitle("Insights")
            .task {
                guard let userID = authVM.userID else { return }
                await statsVM.loadStats(userID: userID)
            }
            .alert("Annual Reading Goal", isPresented: $showGoalEditor) {
                TextField("Number of books", text: $goalDraft)
                    .keyboardType(.numberPad)
                Button("Save") {
                    if let goal = Int(goalDraft), goal > 0 {
                        statsVM.annualGoal = goal
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.title2).foregroundStyle(Color.accentColor)
            Text(value).font(.title.bold())
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}
