import SwiftUI
import UIKit
import UniformTypeIdentifiers
import WebKit

// MARK: - Shell

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("首页", systemImage: "square.grid.2x2.fill") }
            DebugView()
                .tabItem { Label("调试", systemImage: "ladybug.fill") }
            NetworkView()
                .tabItem { Label("网络", systemImage: "network") }
            PluginsView()
                .tabItem { Label("插件", systemImage: "puzzlepiece.fill") }
            SettingsView()
                .tabItem { Label("设置", systemImage: "gearshape.fill") }
        }
    }
}

struct DemoBanner: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
            Text(text)
                .font(.footnote)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.14))
        .foregroundColor(.orange)
        .cornerRadius(10)
    }
}

struct StatusBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .cornerRadius(5)
    }
}

// MARK: - Home

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var appId = ""
    @State private var showAlert = false
    @State private var alertMessage = ""

    private let appIdPattern = #"^wx[A-Za-z0-9]{16}$"#

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    DemoBanner(text: "演示原型 · 不运行真实小程序或小游戏。本工程不含 WMPF 私有运行时，所有业务数据均为本地模拟。")

                    VStack(alignment: .leading, spacing: 10) {
                        Label("按 AppID 打开", systemImage: "app.badge")
                            .font(.headline)
                        HStack(spacing: 8) {
                            TextField("wx1234567890abcdef", text: $appId)
                                .textFieldStyle(.roundedBorder)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                            Button("打开") { openApp() }
                                .buttonStyle(.borderedProminent)
                        }
                        Text("输入格式：wx + 16 位字母或数字。仅做本地校验，不会发起网络请求。")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(12)

                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Label("扫码登录", systemImage: "qrcode")
                                .font(.headline)
                            Spacer()
                            Menu {
                                ForEach(["演示账号 A", "演示账号 B", "演示账号 C"], id: \.self) { name in
                                    Button(name) { appState.account = name }
                                }
                            } label: {
                                Text(appState.account)
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                        HStack(spacing: 14) {
                            Image(systemName: "qrcode")
                                .font(.system(size: 76))
                                .foregroundColor(.primary)
                            VStack(alignment: .leading, spacing: 6) {
                                Text("当前会话：本地演示")
                                    .font(.subheadline)
                                Text("真实扫码授权依赖微信客户端与 WMPF 会话体系，原型未实现。")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(12)

                    VStack(alignment: .leading, spacing: 8) {
                        Label("最近使用（演示数据）", systemImage: "clock.arrow.circlepath")
                            .font(.headline)
                        ForEach(DemoData.recentApps) { item in
                            HStack(spacing: 12) {
                                Image(systemName: item.symbol)
                                    .font(.title2)
                                    .foregroundColor(.blue)
                                    .frame(width: 34)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(item.name)
                                        .font(.subheadline.weight(.medium))
                                    Text(item.appId)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Text(item.lastOpened)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 6)
                        }
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                }
                .padding()
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("WeAppDev · iOS 原型")
            .alert("原型模式", isPresented: $showAlert) {
                Button("知道了", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
    }

    private func openApp() {
        let trimmed = appId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            alertMessage = "请先输入 AppID。"
            showAlert = true
            return
        }
        guard NSPredicate(format: "SELF MATCHES %@", appIdPattern).evaluate(with: trimmed) else {
            alertMessage = "AppID 格式不正确，应为 wx + 16 位字母或数字。"
            showAlert = true
            return
        }
        alertMessage = "已记录 \(trimmed)。真实启动需要不存在的 WMPF 运行时，原型无法打开小程序或小游戏。"
        showAlert = true
    }
}

// MARK: - Debug / gateway

struct DebugView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var gateway: GatewayServer

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    DemoBanner(text: "网关为真实的本地 REST 服务（TCP 9400），但不提供 CDP WebSocket，Chrome DevTools 无法连接调试。")
                    if !appState.debugEnabled {
                        DemoBanner(text: "调试开关当前关闭。原型的网关不受该开关影响；真实应用中关闭调试会同时停止注入。")
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Circle()
                                .fill(gateway.isRunning ? Color.green : Color.red)
                                .frame(width: 10, height: 10)
                            Text(gateway.isRunning ? "网关运行中" : "网关未运行")
                                .font(.headline)
                            Spacer()
                            Button(gateway.isRunning ? "停止" : "启动") {
                                gateway.isRunning ? gateway.stop() : gateway.start()
                            }
                            .buttonStyle(.bordered)
                        }
                        Text("监听端口：9400   ·   绑定：\(appState.bindLocalOnly ? "127.0.0.1" : "0.0.0.0")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(12)

                    VStack(alignment: .leading, spacing: 8) {
                        Label("可用 REST 端点", systemImage: "server.rack")
                            .font(.headline)
                        ForEach(["/json/list", "/json/version", "/v1/status", "/demo/ping"], id: \.self) { path in
                            Button {
                                UIPasteboard.general.string = "http://127.0.0.1:9400\(path)"
                            } label: {
                                HStack {
                                    Text(path)
                                        .font(.system(.caption, design: .monospaced))
                                    Spacer()
                                    Image(systemName: "doc.on.doc")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(12)

                    VStack(alignment: .leading, spacing: 8) {
                        Label("目标列表（模拟）", systemImage: "laptopcomputer.and.iphone")
                            .font(.headline)
                        ForEach(GatewayServer.targets, id: \.id) { target in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(target.title)
                                    .font(.subheadline)
                                Text(target.url)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(12)

                    VStack(alignment: .leading, spacing: 8) {
                        Label("最近的网关请求", systemImage: "waveform.path.ecg")
                            .font(.headline)
                        if gateway.requestLog.isEmpty {
                            Text("暂无请求。用同一 Wi-Fi 下的浏览器访问 http://<设备IP>:9400/json/list 即可产生记录。")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(gateway.requestLog.prefix(12), id: \.self) { line in
                                Text(line)
                                    .font(.system(.caption2, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                }
                .padding()
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("调试网关")
        }
    }
}

// MARK: - Network / native / rewrite

struct NetworkView: View {
    @EnvironmentObject var appState: AppState
    @State private var segment = 0
    @State private var selectedNet: NetRecord?
    @State private var selectedNative: NativeRecord?
    @State private var showRuleEditor = false
    @State private var newRuleName = ""
    @State private var newRulePattern = ""
    @State private var newRuleReplacement = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("类别", selection: $segment) {
                    Text("HTTP 抓包").tag(0)
                    Text("Native 捕获").tag(1)
                    Text("重写规则").tag(2)
                }
                .pickerStyle(.segmented)
                .padding()

                DemoBanner(text: segment == 2 ? "规则仅保存在内存，不会被真实请求执行。" : "以下为演示数据，非真实抓包结果；捕获点依赖 WMPF 运行时内部实现。")
                    .padding(.horizontal)

                switch segment {
                case 0:
                    List(DemoData.netRecords) { record in
                        Button { selectedNet = record } label: {
                            HStack(spacing: 10) {
                                Text(record.method)
                                    .font(.caption2.bold())
                                    .foregroundColor(.blue)
                                    .frame(width: 34, alignment: .leading)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(record.url)
                                        .font(.caption)
                                        .lineLimit(1)
                                    Text("\(record.time)  ·  \(record.duration)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Text("\(record.status)")
                                    .font(.caption2.bold())
                                    .foregroundColor(record.status == 200 || record.status == 101 ? .green : .red)
                            }
                        }
                    }
                    .listStyle(.plain)
                case 1:
                    List(DemoData.nativeRecords) { record in
                        Button { selectedNative = record } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(record.api)
                                        .font(.subheadline.weight(.medium))
                                    StatusBadge(text: "DEMO", color: .orange)
                                }
                                Text("\(record.appName)  ·  seq \(record.seq)  ·  \(record.time)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .listStyle(.plain)
                default:
                    List {
                        ForEach($appState.rules) { rule in
                            VStack(alignment: .leading, spacing: 6) {
                                Toggle(rule.name.wrappedValue, isOn: rule.enabled)
                                Text("\(rule.pattern.wrappedValue)  →  \(rule.replacement.wrappedValue)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Button("新增规则") { showRuleEditor = true }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("网络调试")
            .sheet(item: $selectedNet) { record in
                TransferSheet(title: "\(record.method) \(record.url)",
                              request: record.request, response: record.response)
            }
            .sheet(item: $selectedNative) { record in
                TransferSheet(title: "\(record.api) · seq \(record.seq)",
                              request: record.request, response: record.response)
            }
            .sheet(isPresented: $showRuleEditor) { ruleEditor }
        }
    }

    private var ruleEditor: some View {
        NavigationStack {
            Form {
                Section("规则") {
                    TextField("名称", text: $newRuleName)
                    TextField("匹配文本", text: $newRulePattern)
                    TextField("替换为", text: $newRuleReplacement)
                }
                Section {
                    Button("保存") {
                        let rule = RewriteRule(name: newRuleName.isEmpty ? "未命名规则" : newRuleName,
                                               pattern: newRulePattern,
                                               replacement: newRuleReplacement,
                                               enabled: true)
                        appState.rules.append(rule)
                        newRuleName = ""
                        newRulePattern = ""
                        newRuleReplacement = ""
                        showRuleEditor = false
                    }
                }
            }
            .navigationTitle("新增重写规则")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { showRuleEditor = false }
                }
            }
        }
    }
}

struct TransferSheet: View {
    let title: String
    let request: String
    let response: String

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text(title)
                        .font(.headline)
                    VStack(alignment: .leading, spacing: 6) {
                        Label("请求", systemImage: "arrow.up.right")
                            .font(.subheadline.weight(.semibold))
                        Text(request)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Label("响应", systemImage: "arrow.down.left")
                            .font(.subheadline.weight(.semibold))
                        Text(response)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                    }
                }
                .padding()
            }
            .navigationTitle("详情")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }

    @Environment(\.dismiss) private var dismiss
}

// MARK: - Plugins

struct PluginsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showPicker = false
    @State private var importedURL: URL?
    @State private var previewPlugin: PluginItem?
    @State private var importMessage = ""
    @State private var showImportAlert = false

    var body: some View {
        NavigationStack {
            List {
                DemoBanner(text: "原型只模拟插件「面板」上下文；逻辑层与渲染层注入依赖 CDP 调试通道，未实现。")
                    .listRowInsets(EdgeInsets())

                ForEach($appState.plugins) { plugin in
                    HStack(spacing: 10) {
                        Image(systemName: "puzzlepiece.fill")
                            .foregroundColor(.purple)
                        VStack(alignment: .leading, spacing: 3) {
                            HStack {
                                Text(plugin.name.wrappedValue)
                                    .font(.subheadline.weight(.medium))
                                StatusBadge(text: plugin.kind.wrappedValue, color: .purple)
                            }
                            Text("v\(plugin.version.wrappedValue)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: plugin.enabled)
                            .labelsHidden()
                    }
                    if let html = plugin.html.wrappedValue {
                        Button("预览面板") { previewPlugin = plugin.wrappedValue }
                            .font(.caption)
                    }
                }

                Button("导入 HTML 插件（本地预览）") { showPicker = true }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("插件")
            .sheet(isPresented: $showPicker) {
                PluginDocumentPicker(url: $importedURL)
            }
            .sheet(item: $previewPlugin) { plugin in
                PluginPanelView(html: plugin.html ?? "<h3>无内容</h3>")
                    .navigationTitle(plugin.name)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("完成") { previewPlugin = nil }
                        }
                    }
            }
            .alert("导入结果", isPresented: $showImportAlert) {
                Button("知道了", role: .cancel) {}
            } message: {
                Text(importMessage)
            }
            .onChange(of: importedURL) { url in
                guard let url else { return }
                importPlugin(from: url)
                importedURL = nil
            }
        }
    }

    private func importPlugin(from url: URL) {
        do {
            let html = try String(contentsOf: url, encoding: .utf8)
            let item = PluginItem(name: url.deletingPathExtension().lastPathComponent,
                                  version: "导入", kind: "面板预览", enabled: true, html: html)
            appState.plugins.append(item)
            importMessage = "已导入 \(item.name)。仅本地预览面板 HTML，不执行逻辑层/渲染层脚本。"
        } catch {
            importMessage = "读取失败：\(error.localizedDescription)"
        }
        showImportAlert = true
    }
}

struct PluginDocumentPicker: UIViewControllerRepresentable {
    @Binding var url: URL?

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.html], asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: PluginDocumentPicker
        init(parent: PluginDocumentPicker) { self.parent = parent }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            parent.url = urls.first
        }
    }
}

struct PluginPanelView: UIViewRepresentable {
    let html: String

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        let bridge = """
        <script>
        (function () {
          function reject() { return Promise.reject(new Error('原型模式：该上下文未实现')); }
          window.wadPanelLayer = {
            ready: Promise.resolve(),
            log: function () { console.log('[wad]', Array.from(arguments)); },
            toast: function (m) { console.log('[wad toast]', m); },
            ui: { toast: function (m) { console.log('[wad toast]', m); } },
            logicLayer: { call: reject },
            renderLayer: { call: reject }
          };
        })();
        </script>
        """
        webView.loadHTMLString(bridge + html, baseURL: nil)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

// MARK: - Settings

struct SettingsView: View {
    @EnvironmentObject var appState: AppState

    private let matrix: [(String, String, Color)] = [
        ("AppID 输入 / 最近使用界面", "演示界面", .orange),
        ("微信扫码登录 / 多账号会话", "未实现", .red),
        ("WMPF 运行时与小程序真机执行", "未实现", .red),
        ("本地 :9400 REST 网关", "已实现", .green),
        ("Chrome DevTools / CDP WebSocket", "未实现", .red),
        ("Network 明文抓包列表", "演示数据", .orange),
        ("Native mmtls / ilink 捕获", "演示数据", .orange),
        ("重写规则与 onRequest 脚本", "界面演示", .orange),
        ("HTML 插件面板预览", "部分实现", .blue),
        ("横屏 / 车机模式", "已实现", .green)
    ]

    var body: some View {
        NavigationStack {
            List {
                Section("行为") {
                    Toggle("调试模式", isOn: $appState.debugEnabled)
                    Toggle("绑定 127.0.0.1（否则 0.0.0.0）", isOn: $appState.bindLocalOnly)
                    Toggle("横屏模式（车机）", isOn: $appState.landscapeMode)
                        .onChange(of: appState.landscapeMode) { newValue in
                            OrientationManager.shared.apply(landscape: newValue)
                        }
                }

                Section("功能对照") {
                    ForEach(matrix, id: \.0) { item in
                        HStack(alignment: .top, spacing: 8) {
                            Text(item.0)
                                .font(.subheadline)
                            Spacer()
                            StatusBadge(text: item.1, color: item.2)
                        }
                    }
                }

                Section("关于") {
                    Text("WeAppDev iOS 演示原型 v0.1。目标系统 iOS 16.3 及以上。\n\n本工程为界面与网关原型，不包含原 Android 项目的源代码、WMPF 运行时或任何专有组件；无法运行真实小程序/小游戏，也不具备真实抓包、断点调试与逻辑层插件注入能力。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("设置")
        }
    }
}
