import SwiftUI
import Combine

struct AppItem: Identifiable {
    let id = UUID()
    var name: String
    var path: String
    var icon: String
    var status: AppStatus

    enum AppStatus { case quarantined, fixed }
}

class AppViewModel: ObservableObject {
    @Published var blockEnabled: Bool = false
    @Published var isProcessing: Bool = false
    @Published var apps: [AppItem] = []
    @Published var blockDomains: [String] = [
        "swdist.apple.com",
        "swscan.apple.com",
        "swcdn.apple.com",
        "gdmf.apple.com",
        "mesu.apple.com",
        "xp.apple.com"
    ]
    @Published var toastMessage: String = ""
    @Published var showToast: Bool = false

    init() {
        // 异步检测，避免阻塞主线程
        DispatchQueue.global(qos: .utility).async { [weak self] in
            let enabled = ShellHelper.isBlockEnabled()
            DispatchQueue.main.async {
                self?.blockEnabled = enabled
            }
        }
    }

    // MARK: - 切换更新屏蔽
    func toggleBlock(_ on: Bool) {
        isProcessing = true
        if on {
            ShellHelper.enableBlockUpdate(domains: blockDomains) { [weak self] success in
                self?.isProcessing = false
                self?.blockEnabled = success
                self?.showToastMessage(success ? "已启用更新屏蔽" : "操作失败，请检查权限")
            }
        } else {
            ShellHelper.disableBlockUpdate { [weak self] success in
                self?.isProcessing = false
                self?.blockEnabled = !success
                self?.showToastMessage(success ? "已恢复系统更新" : "操作失败，请检查权限")
            }
        }
    }

    // MARK: - 修复单个应用
    func fixApp(_ item: AppItem) {
        ShellHelper.fixQuarantine(appPath: item.path) { [weak self] success in
            if success, let idx = self?.apps.firstIndex(where: { $0.id == item.id }) {
                self?.apps[idx].status = .fixed
                self?.showToastMessage("已修复 \(item.name)")
            } else {
                self?.showToastMessage("修复失败，请检查权限")
            }
        }
    }

    // MARK: - 全部修复
    func fixAll() {
        apps.filter { $0.status == .quarantined }.forEach { fixApp($0) }
    }

    // MARK: - 移除列表项
    func removeApp(_ item: AppItem) {
        apps.removeAll { $0.id == item.id }
    }

    // MARK: - 添加应用（拖入或选择）
    func addApp(from url: URL) {
        guard url.pathExtension == "app" else { return }
        let name = url.lastPathComponent
        guard !apps.contains(where: { $0.path == url.path }) else { return }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let result = ShellHelper.run("xattr '\(url.path)' 2>/dev/null | grep -c 'com.apple.quarantine'")
            let isQuarantined = (Int(result.output.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0) > 0
            let item = AppItem(
                name: name,
                path: url.path,
                icon: "app.fill",
                status: isQuarantined ? .quarantined : .fixed
            )
            DispatchQueue.main.async {
                self?.apps.append(item)
            }
        }
    }

    // MARK: - Toast
    func showToastMessage(_ msg: String) {
        toastMessage = msg
        showToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            self?.showToast = false
        }
    }
}
