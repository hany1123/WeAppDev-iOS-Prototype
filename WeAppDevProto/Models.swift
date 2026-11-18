import Foundation
import UIKit

// MARK: - Data models

struct RecentApp: Identifiable, Hashable {
    let id: UUID
    let appId: String
    let name: String
    let symbol: String
    let lastOpened: String

    init(appId: String, name: String, symbol: String, lastOpened: String) {
        self.id = UUID()
        self.appId = appId
        self.name = name
        self.symbol = symbol
        self.lastOpened = lastOpened
    }
}

struct NetRecord: Identifiable, Hashable {
    let id: UUID
    let method: String
    let url: String
    let status: Int
    let duration: String
    let time: String
    let request: String
    let response: String

    init(method: String, url: String, status: Int, duration: String, time: String,
         request: String, response: String) {
        self.id = UUID()
        self.method = method
        self.url = url
        self.status = status
        self.duration = duration
        self.time = time
        self.request = request
        self.response = response
    }
}

struct NativeRecord: Identifiable, Hashable {
    let id: UUID
    let api: String
    let appName: String
    let seq: String
    let time: String
    let request: String
    let response: String

    init(api: String, appName: String, seq: String, time: String,
         request: String, response: String) {
        self.id = UUID()
        self.api = api
        self.appName = appName
        self.seq = seq
        self.time = time
        self.request = request
        self.response = response
    }
}

struct RewriteRule: Identifiable, Hashable {
    var id: UUID
    var name: String
    var pattern: String
    var replacement: String
    var enabled: Bool

    init(name: String, pattern: String, replacement: String, enabled: Bool) {
        self.id = UUID()
        self.name = name
        self.pattern = pattern
        self.replacement = replacement
        self.enabled = enabled
    }
}

struct PluginItem: Identifiable, Hashable {
    let id: UUID
    let name: String
    let version: String
    let kind: String
    var enabled: Bool
    let html: String?

    init(name: String, version: String, kind: String, enabled: Bool, html: String? = nil) {
        self.id = UUID()
        self.name = name
        self.version = version
        self.kind = kind
        self.enabled = enabled
        self.html = html
    }
}

// MARK: - Demo data

enum DemoData {
    static let recentApps = [
        RecentApp(appId: "wx1234567890abcdef", name: "示例小程序", symbol: "square.stack.3d.up.fill", lastOpened: "今天 09:12"),
        RecentApp(appId: "wxabcdef1234567890", name: "示例小游戏", symbol: "gamecontroller.fill", lastOpened: "昨天 21:45"),
        RecentApp(appId: "wxa1b2c3d4e5f6a7b8", name: "云开发示例", symbol: "cloud.fill", lastOpened: "11-15 14:03")
    ]

    static let netRecords = [
        NetRecord(method: "GET", url: "https://api.example.dev/v2/user", status: 200, duration: "86 ms", time: "09:12:03",
                  request: "GET /v2/user HTTP/1.1\nHost: api.example.dev\nAuthorization: Bearer ****",
                  response: "HTTP/1.1 200 OK\nContent-Type: application/json\n\n{\"code\":0,\"data\":{\"nickname\":\"demo\"}}"),
        NetRecord(method: "POST", url: "https://api.example.dev/v2/order", status: 200, duration: "142 ms", time: "09:12:04",
                  request: "POST /v2/order HTTP/1.1\nContent-Type: application/json\n\n{\"sku\":\"SKU-1\",\"qty\":1}",
                  response: "HTTP/1.1 200 OK\n\n{\"code\":0,\"orderId\":\"DEMO-1001\"}"),
        NetRecord(method: "GET", url: "https://api.example.dev/v2/coupon", status: 404, duration: "51 ms", time: "09:12:06",
                  request: "GET /v2/coupon HTTP/1.1\nHost: api.example.dev",
                  response: "HTTP/1.1 404 Not Found\n\n{\"code\":404,\"message\":\"not found\"}"),
        NetRecord(method: "WSS", url: "wss://push.example.dev/ws", status: 101, duration: "—", time: "09:12:07",
                  request: "GET /ws HTTP/1.1\nUpgrade: websocket",
                  response: "HTTP/1.1 101 Switching Protocols\n\n[WebSocket frame demo]")
    ]

    static let nativeRecords = [
        NativeRecord(api: "operateWXData", appName: "跳一跳 · v112", seq: "512", time: "15:04:22",
                     request: "{\"api\":\"getGameScore\",\"data\":{\"mode\":\"classic\"}}",
                     response: "{\"errCode\":0,\"result\":{\"score\":1280}}"),
        NativeRecord(api: "getLocation", appName: "示例小程序", seq: "511", time: "15:04:19",
                     request: "{\"type\":\"wgs84\"}",
                     response: "{\"latitude\":30.59,\"longitude\":114.30}")
    ]

    static let rules = [
        RewriteRule(name: "价格改写", pattern: "39.9", replacement: "0.01", enabled: false),
        RewriteRule(name: "Mock 优惠券", pattern: "/v2/coupon", replacement: "/mock/coupon", enabled: true)
    ]

    static let plugins = [
        PluginItem(name: "界面元素修改", version: "1.0.0", kind: "渲染层 · 演示", enabled: false),
        PluginItem(name: "定位调试", version: "1.0.0", kind: "逻辑层 · 演示", enabled: true),
        PluginItem(name: "缓存管理", version: "1.0.0", kind: "工具 · 演示", enabled: false)
    ]
}

// MARK: - Shared state

final class AppState: ObservableObject {
    @Published var debugEnabled = true
    @Published var landscapeMode = false
    @Published var bindLocalOnly = false
    @Published var account = "演示账号 A"
    @Published var rules = DemoData.rules
    @Published var plugins = DemoData.plugins
}

final class OrientationManager {
    static let shared = OrientationManager()
    private init() {}

    func apply(landscape: Bool) {
        AppDelegate.orientationLock = landscape ? [.landscapeLeft, .landscapeRight] : .all
        DispatchQueue.main.async {
            let scene = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first { $0.activationState == .foregroundActive }
            scene?.windows.first?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
        }
    }
}
