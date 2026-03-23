import Foundation
import Security

struct ShellHelper {

    // MARK: - 普通执行（无需 root）
    @discardableResult
    static func run(_ command: String) -> (output: String, exitCode: Int32) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-c", command]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            return (output, process.terminationStatus)
        } catch {
            return ("Error: \(error.localizedDescription)", -1)
        }
    }

    // MARK: - 需要 root 权限的执行（弹出密码框）
    static func runAsAdmin(_ command: String, completion: @escaping (Bool, String) -> Void) {
        let script = """
        do shell script "\(command.replacingOccurrences(of: "\"", with: "\\\""))" with administrator privileges
        """
        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            let result = appleScript.executeAndReturnError(&error)
            if let err = error {
                completion(false, err[NSAppleScript.errorMessage] as? String ?? "未知错误")
            } else {
                completion(true, result.stringValue ?? "")
            }
        } else {
            completion(false, "AppleScript 初始化失败")
        }
    }

    // MARK: - 修复应用隔离属性
    static func fixQuarantine(appPath: String, completion: @escaping (Bool) -> Void) {
        runAsAdmin("xattr -cr '\(appPath)'") { success, _ in
            DispatchQueue.main.async { completion(success) }
        }
    }

    // MARK: - 启用屏蔽（写入 hosts）
    static func enableBlockUpdate(domains: [String], completion: @escaping (Bool) -> Void) {
        var lines = "\\n# Block macOS Software Update"
        for domain in domains {
            lines += "\\n127.0.0.1 \(domain)"
        }
        let cmd = "printf '\(lines)' >> /etc/hosts && dscacheutil -flushcache && killall -HUP mDNSResponder"
        runAsAdmin(cmd) { success, _ in
            DispatchQueue.main.async { completion(success) }
        }
    }

    // MARK: - 关闭屏蔽（还原 hosts）
    static func disableBlockUpdate(completion: @escaping (Bool) -> Void) {
        let cmd = #"sed -i "" "/# Block macOS Software Update/,+\#(999)d" /etc/hosts && dscacheutil -flushcache && killall -HUP mDNSResponder"#
        // 动态行数删除：用固定标记行+后续行
        let realCmd = """
        sed -i "" "/# Block macOS Software Update/{N;N;N;N;N;N;N;d;}" /etc/hosts && dscacheutil -flushcache && killall -HUP mDNSResponder
        """
        runAsAdmin(realCmd) { success, _ in
            DispatchQueue.main.async { completion(success) }
        }
    }

    // MARK: - 检测 hosts 是否已有屏蔽规则
    static func isBlockEnabled() -> Bool {
        let result = run("grep -c '# Block macOS Software Update' /etc/hosts")
        return (Int(result.output.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0) > 0
    }
}
