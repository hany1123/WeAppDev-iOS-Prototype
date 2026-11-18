import Foundation
import Network

/// A minimal REST-only debug gateway on TCP port 9400.
/// It intentionally does NOT implement the CDP WebSocket endpoint: that requires
/// the private WMPF/V8 inspector, which is unavailable in this prototype.
final class GatewayServer: ObservableObject {
    @Published private(set) var isRunning = false
    @Published private(set) var requestLog: [String] = []

    private var listener: NWListener?
    private let queue = DispatchQueue(label: "com.example.wadproto.gateway", qos: .utility)

    static let targets: [(id: String, title: String, url: String)] = [
        ("appservice-1", "appservice · 逻辑层", "prototype://appservice"),
        ("webview-1", "render · 渲染层", "prototype://render"),
        ("panel-1", "panel · 插件面板", "prototype://panel")
    ]

    func start() {
        guard listener == nil else { return }
        do {
            let parameters = NWParameters.tcp
            parameters.allowLocalEndpointReuse = true
            guard let port = NWEndpoint.Port(rawValue: 9400) else { return }
            let newListener = try NWListener(using: parameters, on: port)

            newListener.stateUpdateHandler = { [weak self] state in
                switch state {
                case .ready:
                    DispatchQueue.main.async { self?.isRunning = true }
                case .failed, .cancelled:
                    DispatchQueue.main.async {
                        self?.isRunning = false
                        self?.listener = nil
                    }
                default:
                    break
                }
            }
            newListener.newConnectionHandler = { [weak self] connection in
                self?.handle(connection)
            }
            newListener.start(queue: queue)
            listener = newListener
        } catch {
            DispatchQueue.main.async { self.isRunning = false }
        }
    }

    func stop() {
        listener?.cancel()
        listener = nil
        isRunning = false
    }

    private func handle(_ connection: NWConnection) {
        connection.stateUpdateHandler = { state in
            if case .failed = state { connection.cancel() }
        }
        connection.start(queue: queue)
        connection.receive(minimumIncompleteLength: 1, maximumLength: 16384) { [weak self] data, _, _, _ in
            guard let self else {
                connection.cancel()
                return
            }
            let raw = String(data: data ?? Data(), encoding: .utf8) ?? ""
            let path = raw.split(separator: " ").dropFirst().first.map(String.init) ?? "/"
            let stamp = Date().formatted(date: .omitted, time: .standard)
            DispatchQueue.main.async {
                self.requestLog.insert("\(stamp)   \(path)", at: 0)
                if self.requestLog.count > 30 { self.requestLog.removeLast() }
            }
            let (status, body) = self.response(for: path)
            let reason = status == 200 ? "OK" : "Not Found"
            let header = "HTTP/1.1 \(status) \(reason)\r\nContent-Type: application/json; charset=utf-8\r\nContent-Length: \(body.utf8.count)\r\nConnection: close\r\n\r\n"
            connection.send(content: (header + body).data(using: .utf8), completion: .contentProcessed { _ in
                connection.cancel()
            })
        }
    }

    private func response(for path: String) -> (Int, String) {
        let clean = path.split(separator: "?").first.map(String.init) ?? path
        var payload: Any

        switch clean {
        case "/json", "/json/list":
            let targets: [[String: Any]] = Self.targets.map { item in
                [
                    "id": item.id,
                    "type": "other",
                    "title": item.title,
                    "url": item.url,
                    "webSocketDebuggerUrl": "ws://127.0.0.1:9400/devtools/\(item.id) (原型未提供)",
                    "prototype": true
                ]
            }
            payload = targets
        case "/json/version":
            payload = [
                "Browser": "WeAppDev-iOS-Prototype/0.1",
                "Protocol-Version": "1.3",
                "prototype": true
            ]
        case "/v1/status", "/demo/ping":
            payload = [
                "ok": true,
                "mode": "prototype",
                "note": "REST only; no CDP WebSocket, no WMPF runtime",
                "port": 9400
            ] as [String: Any]
        default:
            return (404, "{\"error\":\"not_found\",\"path\":\"\(clean)\",\"prototype\":true}")
        }

        if let data = try? JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted]),
           let text = String(data: data, encoding: .utf8) {
            return (200, text)
        }
        return (500, "{\"error\":\"serialize_failed\"}")
    }
}
