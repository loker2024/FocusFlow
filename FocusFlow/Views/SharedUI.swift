import SwiftUI

extension Color {
    static var appSurface: Color {
        Color(NSColor.controlBackgroundColor)
    }

    static var appElevatedSurface: Color {
        Color(NSColor.textBackgroundColor)
    }

    static var appStroke: Color {
        Color(NSColor.separatorColor).opacity(0.35)
    }

    static var appMutedAccent: Color {
        Color.accentColor.opacity(0.12)
    }

    static func appNamed(_ name: String) -> Color {
        switch name {
        case "red": return .red
        case "green": return .green
        case "purple": return .purple
        case "orange": return .orange
        case "pink": return .pink
        default: return .blue
        }
    }
}

struct AppPage<Content: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    let actionTitle: String?
    let actionIcon: String?
    let action: (() -> Void)?
    @ViewBuilder let content: Content

    init(
        title: String,
        subtitle: String,
        icon: String,
        actionTitle: String? = nil,
        actionIcon: String? = nil,
        action: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.actionTitle = actionTitle
        self.actionIcon = actionIcon
        self.action = action
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            AppHeader(
                title: title,
                subtitle: subtitle,
                icon: icon,
                actionTitle: actionTitle,
                actionIcon: actionIcon,
                action: action
            )

            content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .frame(maxWidth: 1180, alignment: .topLeading)
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct MetricStrip<Content: View>: View {
    @ViewBuilder let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        HStack(spacing: 12) {
            content
        }
    }
}

struct AppHeader: View {
    let title: String
    let subtitle: String
    let icon: String
    let actionTitle: String?
    let actionIcon: String?
    let action: (() -> Void)?

    init(
        title: String,
        subtitle: String,
        icon: String,
        actionTitle: String? = nil,
        actionIcon: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.actionTitle = actionTitle
        self.actionIcon = actionIcon
        self.action = action
    }

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            Image(systemName: icon)
                .font(.title2.weight(.semibold))
                .foregroundColor(.accentColor)
                .frame(width: 44, height: 44)
                .background(Color.appMutedAccent)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.largeTitle.weight(.bold))

                Text(subtitle)
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 20)

            if let actionTitle, let actionIcon, let action {
                Button(action: action) {
                    Label(actionTitle, systemImage: actionIcon)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let caption: String?
    let icon: String
    let color: Color

    init(title: String, value: String, caption: String? = nil, icon: String, color: Color) {
        self.title = title
        self.value = value
        self.caption = caption
        self.icon = icon
        self.color = color
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3.weight(.semibold))
                .foregroundColor(color)
                .frame(width: 34, height: 34)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(value)
                    .font(.title3.weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                if let caption {
                    Text(caption)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(minWidth: 150, maxWidth: .infinity, minHeight: 78, alignment: .leading)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.appStroke)
        )
    }
}

struct SectionPanel<Content: View>: View {
    let title: String?
    let subtitle: String?
    @ViewBuilder let content: Content

    init(title: String? = nil, subtitle: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if title != nil || subtitle != nil {
                VStack(alignment: .leading, spacing: 4) {
                    if let title {
                        Text(title)
                            .font(.headline)
                    }

                    if let subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            content
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.appStroke)
        )
    }
}

private struct AppListContainerModifier: ViewModifier {
    let minHeight: CGFloat

    func body(content: Content) -> some View {
        content
            .listStyle(.inset)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.appStroke)
            )
            .frame(minHeight: minHeight)
    }
}

extension View {
    func appListContainer(minHeight: CGFloat = 360) -> some View {
        modifier(AppListContainerModifier(minHeight: minHeight))
    }
}

struct FormSheet<Content: View>: View {
    let title: String
    var width: CGFloat = 400
    @ViewBuilder let content: Content

    init(title: String, width: CGFloat = 400, @ViewBuilder content: () -> Content) {
        self.title = title
        self.width = width
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 20) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)

            content
        }
        .padding(30)
        .frame(width: width)
    }
}

struct SheetActions: View {
    var saveTitle = "保存"
    var cancelTitle = "取消"
    let isSaveDisabled: Bool
    let onCancel: () -> Void
    let onSave: () -> Void

    var body: some View {
        HStack {
            Button(cancelTitle, action: onCancel)
                .keyboardShortcut(.cancelAction)

            Spacer()

            Button(saveTitle, action: onSave)
                .keyboardShortcut(.defaultAction)
                .disabled(isSaveDisabled)
        }
    }
}

struct FilledActionButton: View {
    let title: String
    let systemImage: String
    let color: Color
    var width: CGFloat?
    var minHeight: CGFloat = 46
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .frame(maxWidth: width == nil ? .infinity : nil, minHeight: minHeight)
                .frame(width: width)
                .background(color)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct IconChoiceGrid: View {
    let icons: [String]
    @Binding var selection: String
    var columns = 5
    var iconSize: CGFloat = 32

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: columns), spacing: 10) {
            ForEach(icons, id: \.self) { icon in
                Button(action: { selection = icon }) {
                    Text(icon)
                        .font(.system(size: iconSize))
                        .frame(width: 44, height: 44)
                        .background(selection == icon ? Color.appMutedAccent : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(selection == icon ? Color.accentColor.opacity(0.45) : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct ColorSwatchPicker: View {
    let colors: [String]
    @Binding var selection: String

    var body: some View {
        HStack(spacing: 10) {
            ForEach(colors, id: \.self) { color in
                Button(action: { selection = color }) {
                    Circle()
                        .fill(Color.appNamed(color))
                        .frame(width: 30, height: 30)
                        .overlay(
                            Circle()
                                .stroke(selection == color ? Color.primary : Color.clear, lineWidth: 2)
                        )
                        .padding(3)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct PromptTextEditor: View {
    @Binding var text: String
    let prompt: String
    var minHeight: CGFloat = 120

    var body: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $text)
                .font(.body)
                .scrollContentBackground(.hidden)
                .padding(8)
                .frame(minHeight: minHeight)

            if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(prompt)
                    .font(.body)
                    .foregroundColor(.secondary.opacity(0.8))
                    .padding(.horizontal, 13)
                    .padding(.vertical, 16)
                    .allowsHitTesting(false)
            }
        }
        .background(Color.appElevatedSurface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.appStroke)
        )
    }
}

struct PillBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundColor(color)
            .background(color.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 38, weight: .semibold))
                .foregroundColor(.secondary)

            Text(title)
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(28)
        .frame(maxWidth: 320)
    }
}
