import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var theme: ThemeManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                BabymonTheme.backgroundGradient
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 16) {
                    Text("Appearance")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)

                    VStack(spacing: 10) {
                        ForEach(AppearanceOption.allCases) { option in
                            AppearanceRow(
                                option: option,
                                selected: theme.appearance == option
                            ) {
                                withAnimation(.easeOut(duration: 0.18)) {
                                    theme.appearance = option
                                }
                            }
                        }
                    }

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }
}

private struct AppearanceRow: View {
    let option: AppearanceOption
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 11)
                        .fill(BabymonTheme.accent.opacity(selected ? 0.18 : 0.10))
                        .frame(width: 40, height: 40)
                    Image(systemName: option.icon)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(selected ? BabymonTheme.accentLight : .secondary)
                }

                Text(option.label)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(.primary)

                Spacer()

                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(BabymonTheme.accentLight)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(BabymonTheme.cardBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(selected ? BabymonTheme.accent.opacity(0.4) : BabymonTheme.hairline, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
