import SwiftUI
import UniformTypeIdentifiers

struct MainPageView: View {
    @EnvironmentObject var vm: AppViewModel
    @State private var isTargeted = false

    var body: some View {
        VStack(spacing: 14) {
            BlockUpdateCard()
                .environmentObject(vm)

            FixAppCard(isTargeted: $isTargeted)
                .environmentObject(vm)
                .onDrop(of: [UTType.applicationBundle, UTType.fileURL], isTargeted: $isTargeted) { providers in
                    for provider in providers {
                        _ = provider.loadObject(ofClass: URL.self) { url, _ in
                            if let url = url {
                                DispatchQueue.main.async { vm.addApp(from: url) }
                            }
                        }
                    }
                    return true
                }

            if vm.showToast {
                ToastView(message: vm.toastMessage)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: vm.showToast)
    }
}

// MARK: - 屏蔽更新卡片
struct BlockUpdateCard: View {
    @EnvironmentObject var vm: AppViewModel

    var body: some View {
        CardContainer {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("状态")
                        .font(.system(size: 14, weight: .semibold))
                    Text("检测是否已经开启屏蔽")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                Spacer()
                StatusBadge(enabled: vm.blockEnabled)
            }
            .padding(.horizontal, 16)
            .padding(.top, 13)
            .padding(.bottom, 12)

            Divider().opacity(0.5)

            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("拦截系统更新推送/去除小红点")
                        .font(.system(size: 14, weight: .medium))
                    (
                        Text("启用后开启拦截，关闭则自动还原。\n注意执行前将 系统设置-通用-软件更新 全部关闭")
                        + Text("\n还有红点？请看 [详细教程](https://mp.weixin.qq.com/s/ukx4F8GRMgjcoLItQ9OyxA)")
                            .font(.system(size: 11))
                    )
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .tint(.accentColor)
                }
                Spacer()
                if vm.isProcessing {
                    ProgressView().scaleEffect(0.7)
                } else {
                    Toggle("", isOn: Binding(
                        get: { vm.blockEnabled },
                        set: { vm.toggleBlock($0) }
                    ))
                    .toggleStyle(.switch)
                    .labelsHidden()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
        }
    }
}

// MARK: - 修复应用卡片
struct FixAppCard: View {
    @EnvironmentObject var vm: AppViewModel
    @Binding var isTargeted: Bool

    var body: some View {
        CardContainer {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("修复「已损坏/不受信任」应用")
                        .font(.system(size: 14, weight: .semibold))
                    Text("绕过签名可以解决大多数破解应用程序在运行的时候出现「已损坏/不受信任」的提示")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 13)
            .padding(.bottom, 12)

            Divider().opacity(0.5)

            VStack(spacing: 10) {
                DropZoneView(isTargeted: isTargeted) {
                    openFilePicker()
                }

                if !vm.apps.isEmpty {
                    VStack(spacing: 0) {
                        ForEach(vm.apps) { item in
                            AppRowView(item: item)
                                .environmentObject(vm)
                            if item.id != vm.apps.last?.id {
                                Divider().padding(.leading, 58).opacity(0.5)
                            }
                        }
                    }
                    .background(Color.cardSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 9)
                            .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                    )
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)

            HStack {
                HStack(spacing: 5) {
                    Circle().fill(Color.orange).frame(width: 5, height: 5)
                    Text("部分操作需要管理员权限")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button("全部修复") { vm.fixAll() }
                    .buttonStyle(PrimaryButtonStyle(size: .small))
                    .disabled(vm.apps.filter { $0.status == .quarantined }.isEmpty)
            }
            .padding(.horizontal, 14)
            .padding(.top, 8)
            .padding(.bottom, 14)
        }
    }

    private func openFilePicker() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.applicationBundle]
        panel.prompt = "选择"
        if panel.runModal() == .OK {
            panel.urls.forEach { vm.addApp(from: $0) }
        }
    }
}

// MARK: - 拖拽区域
struct DropZoneView: View {
    let isTargeted: Bool
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 7) {
                Image(systemName: "plus.rectangle.on.folder")
                    .font(.system(size: 22))
                    .foregroundColor(isTargeted || hovering ? .accentColor : .secondary)
                Text("拖入 .app 文件")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isTargeted || hovering ? .accentColor : .primary)
                Text("或点击选择 · 支持批量拖入")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 9)
                    .fill(isTargeted || hovering ? Color.accentColor.opacity(0.08) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 9)
                    .strokeBorder(
                        isTargeted || hovering ? Color.accentColor : Color.primary.opacity(0.15),
                        style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}

// MARK: - 应用行
struct AppRowView: View {
    let item: AppItem
    @EnvironmentObject var vm: AppViewModel
    @State private var hovering = false

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 7)
                    .fill(Color.primary.opacity(0.06))
                    .frame(width: 32, height: 32)
                Image(systemName: "app.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.system(size: 13, weight: .medium))
                Text(item.path)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            HStack(spacing: 6) {
                if item.status == .quarantined {
                    AppStatusPill(label: "被隔离", color: .red)
                    Button("修复") { vm.fixApp(item) }
                        .buttonStyle(PrimaryButtonStyle(size: .small))
                } else {
                    AppStatusPill(label: "已修复", color: .green)
                    Button("移除") { vm.removeApp(item) }
                        .buttonStyle(GhostButtonStyle(size: .small))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(hovering ? Color.primary.opacity(0.04) : Color.clear)
        .onHover { hovering = $0 }
    }
}

// MARK: - 状态 Badge
struct StatusBadge: View {
    let enabled: Bool
    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(enabled ? Color.green : Color.secondary.opacity(0.5))
                .frame(width: 5, height: 5)
            Text(enabled ? "已启用" : "未启用")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(enabled ? .green : .secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            Capsule().fill(enabled ? Color.green.opacity(0.1) : Color.primary.opacity(0.06))
        )
    }
}

struct AppStatusPill: View {
    let label: String
    let color: Color
    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 5, height: 5)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Capsule().fill(color.opacity(0.1)))
    }
}

// MARK: - Toast
struct ToastView: View {
    let message: String
    var body: some View {
        Text(message)
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Capsule().fill(Color.black.opacity(0.75)))
    }
}
