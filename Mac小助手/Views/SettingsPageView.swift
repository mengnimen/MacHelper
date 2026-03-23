import SwiftUI
import AppKit

struct SettingsPageView: View {
    @EnvironmentObject var vm: AppViewModel
    @State private var savedOK = false

    // 本机信息（实际运行时从系统读取）
    private let sysInfo: [(String, String)] = [
        ("芯片", getMachineModel()),
        ("内存", getMemoryInfo()),
        ("macOS 版本", getOSVersion()),
        ("序列号", getSerialNumber()),
    ]

    var body: some View {
        VStack(spacing: 14) {
            // 关于本机卡片
            CardContainer {
                // 顶部机型展示
                HStack(spacing: 16) {
                    Image(systemName: "laptopcomputer")
                        .font(.system(size: 36))
                        .foregroundColor(.accentColor)
                        .frame(width: 62, height: 62)
                        .background(Color.accentColor.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(getMachineModel())
                            .font(.system(size: 17, weight: .semibold))
                        Text("Mac小助手 · 版本 1.0.0")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(20)
                .background(Color.primary.opacity(0.04))

                Divider().opacity(0.5)

                // 系统信息行
                VStack(spacing: 0) {
                    ForEach(sysInfo, id: \.0) { key, val in
                        HStack {
                            Text(key)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .frame(width: 120, alignment: .leading)
                            Text(val)
                                .font(.system(size: 12, weight: .medium))
                            Spacer()
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        if key != sysInfo.last?.0 {
                            Divider().padding(.leading, 18).opacity(0.5)
                        }
                    }
                }
            }

            // 屏蔽域名配置
            CardContainer {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("屏蔽域名配置")
                            .font(.system(size: 14, weight: .semibold))
                        Text("自定义写入 hosts 的屏蔽地址")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 13)
                .padding(.bottom, 12)

                Divider().opacity(0.5)

                VStack(spacing: 12) {
                    // 说明
                    Text("启用拦截时，以下域名将被解析至 127.0.0.1。可自行新增或删除以适配将来的 Apple 更新服务器地址。如能正常屏蔽，使用默认即可。")
                        .font(.system(size: 11))
                        .foregroundColor(.accentColor)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.accentColor.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 7))

                    // 域名列表
                    VStack(spacing: 6) {
                        ForEach(vm.blockDomains.indices, id: \.self) { i in
                            HStack(spacing: 8) {
                                TextField("域名", text: $vm.blockDomains[i])
                                    .textFieldStyle(.plain)
                                    .font(.system(size: 12, design: .monospaced))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 7)
                                    .background(Color.primary.opacity(0.05))
                                    .clipShape(RoundedRectangle(cornerRadius: 7))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 7)
                                            .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                                    )
                                Button {
                                    vm.blockDomains.remove(at: i)
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(.red)
                                        .frame(width: 22, height: 22)
                                        .background(Color.red.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 5))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // 添加按钮
                    Button {
                        vm.blockDomains.append("")
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.system(size: 11, weight: .medium))
                            Text("添加域名")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 7)
                                .strokeBorder(Color.primary.opacity(0.15),
                                              style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                        )
                    }
                    .buttonStyle(.plain)

                    // 保存/重置
                    HStack {
                        Spacer()
                        Button("恢复默认") {
                            vm.blockDomains = [
                                "swdist.apple.com","swscan.apple.com","swcdn.apple.com",
                                "gdmf.apple.com","mesu.apple.com","xp.apple.com"
                            ]
                        }
                        .buttonStyle(GhostButtonStyle(size: .small))

                        Button(savedOK ? "已保存 ✓" : "保存配置") {
                            savedOK = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { savedOK = false }
                        }
                        .buttonStyle(PrimaryButtonStyle(size: .small))
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 14)
            }
        }
    }
}

// MARK: - 系统信息读取
func getMachineModel() -> String {
    var size = 0
    sysctlbyname("hw.model", nil, &size, nil, 0)
    var model = [CChar](repeating: 0, count: size)
    sysctlbyname("hw.model", &model, &size, nil, 0)
    return String(cString: model)
}

func getMemoryInfo() -> String {
    let bytes = ProcessInfo.processInfo.physicalMemory
    let gb = Double(bytes) / 1_073_741_824
    return "\(Int(gb.rounded())) GB"
}

func getOSVersion() -> String {
    let v = ProcessInfo.processInfo.operatingSystemVersion
    return "macOS \(v.majorVersion).\(v.minorVersion).\(v.patchVersion)"
}

func getSerialNumber() -> String {
    let service = IOServiceGetMatchingService(kIOMainPortDefault,
                                              IOServiceMatching("IOPlatformExpertDevice"))
    defer { IOObjectRelease(service) }
    let key = "IOPlatformSerialNumber" as CFString
    if let serial = IORegistryEntryCreateCFProperty(service, key, kCFAllocatorDefault, 0)?
        .takeRetainedValue() as? String {
        return serial
    }
    return "不可用"
}
