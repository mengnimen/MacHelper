import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // 头部
            HStack(spacing: 14) {
                Image(systemName: "laptopcomputer")
                    .font(.system(size: 28))
                    .foregroundColor(.accentColor)
                    .frame(width: 54, height: 54)
                    .background(Color.accentColor.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 13))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Mac小助手")
                        .font(.system(size: 16, weight: .semibold))
                    Text("版本 1.0.0 · macOS 13.0+")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(18)
            .background(Color.primary.opacity(0.04))

            Divider().opacity(0.5)

            // 信息行
            VStack(spacing: 0) {
                infoRow("开发者", "mengnimen", color: .accentColor)
                Divider().padding(.leading, 18).opacity(0.5)
                infoRow("微信公众号", "萌叔小m", color: .accentColor)
                Divider().padding(.leading, 18).opacity(0.5)
                infoRow("开源协议", "MIT License")
                Divider().opacity(0.5)

                // 简介
                Text("Mac小助手是一款轻量的 macOS 实用工具，专为需要安装未签名应用、或希望保持当前系统版本的用户设计。\n\n通过修改 hosts 文件屏蔽 Apple 更新服务器；一键移除应用的 Gatekeeper 隔离属性，彻底解决「应用已损坏，无法打开」的问题。")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineSpacing(4)
                    .padding(18)
            }

            Divider().opacity(0.5)

            // 关闭按钮
            Button("关闭") { dismiss() }
                .buttonStyle(GhostButtonStyle(size: .normal))
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 80)
                .padding(.vertical, 14)
        }
        .frame(width: 340)
    }

    private func infoRow(_ key: String, _ value: String, color: Color = .primary) -> some View {
        HStack {
            Text(key)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .frame(width: 70, alignment: .leading)
            Text(value)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(color)
            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
    }
}
