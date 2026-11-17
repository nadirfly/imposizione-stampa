// Imposizione Stampa - guscio nativo macOS.
// Mostra index.html in una WebView (librerie incluse, funziona offline) e collega la pagina a macOS:
// salvataggio PDF (pannello di sistema) e stampa tramite CUPS (lp) sulla stampante scelta.
import Cocoa
import WebKit

final class AppDelegate: NSObject, NSApplicationDelegate, WKScriptMessageHandler, WKUIDelegate, WKNavigationDelegate {
    var window: NSWindow!
    var web: WKWebView!

    func applicationDidFinishLaunching(_ n: Notification) {
        let cfg = WKWebViewConfiguration()
        cfg.userContentController.add(self, name: "native")
        web = WKWebView(frame: .zero, configuration: cfg)
        web.uiDelegate = self
        web.navigationDelegate = self

        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1400, height: 900),
                          styleMask: [.titled, .closable, .miniaturizable, .resizable],
                          backing: .buffered, defer: false)
        window.title = "Imposizione Stampa"
        window.contentView = web
        window.center()
        window.setFrameAutosaveName("main")
        window.makeKeyAndOrderFront(nil)

        buildMenu()
        if let dir = Bundle.main.resourceURL?.appendingPathComponent("web") {
            web.loadFileURL(dir.appendingPathComponent("index.html"), allowingReadAccessTo: dir)
        }
        NSApp.activate(ignoringOtherApps: true)
        checkForUpdates(manual: false)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ app: NSApplication) -> Bool { true }

    // --- Aggiornamenti: legge l'ultima Release del repo GitHub indicato in Info.plist (ImposizioneRepo) ---
    func checkForUpdates(manual: Bool) {
        let repo = (Bundle.main.object(forInfoDictionaryKey: "ImposizioneRepo") as? String) ?? ""
        let current = (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "0"
        func info(_ title: String, _ text: String) {
            let a = NSAlert(); a.messageText = title; a.informativeText = text; a.runModal()
        }
        guard !repo.isEmpty, let url = URL(string: "https://api.github.com/repos/\(repo)/releases/latest") else {
            if manual { info("Aggiornamenti non configurati", "Questa copia dell'app non ha un repository per gli aggiornamenti.") }
            return
        }
        var req = URLRequest(url: url, timeoutInterval: 10)
        req.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        URLSession.shared.dataTask(with: req) { data, resp, _ in
            DispatchQueue.main.async {
                guard let data = data, (resp as? HTTPURLResponse)?.statusCode == 200,
                      let j = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let tag = j["tag_name"] as? String else {
                    if manual { info("Impossibile controllare", "Nessuna risposta dal repository (connessione assente o nessuna versione pubblicata).") }
                    return
                }
                let latest = tag.hasPrefix("v") ? String(tag.dropFirst()) : tag
                if latest.compare(current, options: .numeric) == .orderedDescending {
                    let a = NSAlert()
                    a.messageText = "Disponibile la versione \(latest)"
                    a.informativeText = "Hai la \(current). Si apre la pagina da cui scaricare il nuovo .dmg."
                    a.addButton(withTitle: "Scarica"); a.addButton(withTitle: "Dopo")
                    if a.runModal() == .alertFirstButtonReturn,
                       let page = (j["html_url"] as? String).flatMap(URL.init(string:)) { NSWorkspace.shared.open(page) }
                } else if manual { info("Sei aggiornato", "Versione \(current): e' l'ultima disponibile.") }
            }
        }.resume()
    }
    @objc func manualUpdateCheck() { checkForUpdates(manual: true) }

    func buildMenu() {
        let main = NSMenu()
        func item(_ title: String, _ sel: Selector?, _ key: String, mods: NSEvent.ModifierFlags = .command) -> NSMenuItem {
            let i = NSMenuItem(title: title, action: sel, keyEquivalent: key)
            i.keyEquivalentModifierMask = mods
            return i
        }
        let app = NSMenuItem(); main.addItem(app)
        let appMenu = NSMenu(); app.submenu = appMenu
        appMenu.addItem(item("Nascondi Imposizione Stampa", #selector(NSApplication.hide(_:)), "h"))
        let upd = item("Cerca aggiornamenti...", #selector(manualUpdateCheck), "")
        upd.target = self
        appMenu.addItem(upd)
        appMenu.addItem(.separator())
        appMenu.addItem(item("Esci da Imposizione Stampa", #selector(NSApplication.terminate(_:)), "q"))
        // Modifica: serve per copia/incolla e annulla nei campi della pagina
        let edit = NSMenuItem(); main.addItem(edit)
        let editMenu = NSMenu(title: "Modifica"); edit.submenu = editMenu
        editMenu.addItem(item("Annulla", Selector(("undo:")), "z"))
        editMenu.addItem(item("Ripeti", Selector(("redo:")), "z", mods: [.command, .shift]))
        editMenu.addItem(.separator())
        editMenu.addItem(item("Taglia", #selector(NSText.cut(_:)), "x"))
        editMenu.addItem(item("Copia", #selector(NSText.copy(_:)), "c"))
        editMenu.addItem(item("Incolla", #selector(NSText.paste(_:)), "v"))
        editMenu.addItem(item("Seleziona tutto", #selector(NSText.selectAll(_:)), "a"))
        let win = NSMenuItem(); main.addItem(win)
        let winMenu = NSMenu(title: "Finestra"); win.submenu = winMenu
        winMenu.addItem(item("Riduci", #selector(NSWindow.performMiniaturize(_:)), "m"))
        NSApp.windowsMenu = winMenu
        NSApp.mainMenu = main
    }

    // input type=file della pagina
    func webView(_ webView: WKWebView, runOpenPanelWith parameters: WKOpenPanelParameters,
                 initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping ([URL]?) -> Void) {
        let p = NSOpenPanel()
        p.allowsMultipleSelection = parameters.allowsMultipleSelection
        p.canChooseDirectories = false
        p.beginSheetModal(for: window) { r in completionHandler(r == .OK ? p.urls : nil) }
    }

    // Link esterni nel browser, mai dentro l'app
    func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = action.request.url, action.navigationType == .linkActivated, !url.isFileURL {
            NSWorkspace.shared.open(url); decisionHandler(.cancel); return
        }
        decisionHandler(.allow)
    }

    func reply(_ ok: Bool, _ message: String, id: Int = 0) {
        let payload: [String: Any] = ["ok": ok, "message": message, "id": id]
        if let d = try? JSONSerialization.data(withJSONObject: payload), let s = String(data: d, encoding: .utf8) {
            DispatchQueue.main.async { self.web.evaluateJavaScript("window.nativeResult(\(s))") }
        }
    }

    var batchFiles: [URL] = []

    func send(_ fn: String, _ obj: Any) {
        if let d = try? JSONSerialization.data(withJSONObject: obj), let s = String(data: d, encoding: .utf8) {
            DispatchQueue.main.async { self.web.evaluateJavaScript("\(fn)(\(s))") }
        }
    }

    func userContentController(_ c: WKUserContentController, didReceive m: WKScriptMessage) {
        guard let body = m.body as? [String: Any], let action = body["action"] as? String else { return }
        let id = (body["id"] as? Int) ?? 0
        switch action {
        case "listPrinters":
            let names = shell("/usr/bin/lpstat", ["-e"]).out.split(separator: "\n").map(String.init)
            send("window.nativePrinters", names)
        case "pickFolder": pickFolder()
        case "readBatchFile":
            let i = (body["index"] as? Int) ?? -1
            guard i >= 0, i < batchFiles.count, let d = try? Data(contentsOf: batchFiles[i]) else {
                send("window.nativeBatchFile", ["id": id, "error": "File non leggibile"]); return
            }
            let ext = batchFiles[i].pathExtension.lowercased()
            let mime = ["jpg": "image/jpeg", "jpeg": "image/jpeg", "png": "image/png", "tif": "image/tiff",
                        "tiff": "image/tiff", "pdf": "application/pdf"][ext] ?? "application/octet-stream"
            send("window.nativeBatchFile", ["id": id, "name": batchFiles[i].lastPathComponent, "mime": mime,
                                            "b64": d.base64EncodedString()])
        case "save", "print":
            guard let b64 = body["pdf"] as? String, let data = Data(base64Encoded: b64) else { return }
            let filename = (body["filename"] as? String) ?? "imposizione.pdf"
            if action == "save" { save(data, filename, id) } else { printPDF(data, filename, body, id) }
        default: break
        }
    }

    func pickFolder() {
        let p = NSOpenPanel()
        p.canChooseFiles = false; p.canChooseDirectories = true; p.allowsMultipleSelection = false
        p.message = "Scegli la cartella con le foto da stampare"
        p.beginSheetModal(for: window) { r in
            guard r == .OK, let dir = p.url else { self.send("window.nativeFolder", ["cancelled": true]); return }
            let ok = ["jpg", "jpeg", "png", "tif", "tiff"]
            let all = (try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil,
                                                                    options: [.skipsHiddenFiles])) ?? []
            self.batchFiles = all.filter { ok.contains($0.pathExtension.lowercased()) }
                .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
            self.send("window.nativeFolder", ["name": dir.lastPathComponent, "files": self.batchFiles.map { $0.lastPathComponent }])
        }
    }

    func save(_ data: Data, _ filename: String, _ id: Int) {
        let p = NSSavePanel()
        p.nameFieldStringValue = filename
        p.allowedContentTypes = [.pdf]
        p.beginSheetModal(for: window) { r in
            guard r == .OK, let url = p.url else { self.reply(false, "", id: id); return }
            do { try data.write(to: url); self.reply(true, "PDF salvato: " + url.lastPathComponent, id: id) }
            catch { self.reply(false, "Salvataggio non riuscito: \(error.localizedDescription)", id: id) }
        }
    }

    // Stampa con CUPS: pagina esattamente grande come il foglio, nessun adattamento del pilota.
    func printPDF(_ data: Data, _ filename: String, _ b: [String: Any], _ id: Int) {
        let printer = (b["printer"] as? String) ?? ""
        let known = shell("/usr/bin/lpstat", ["-e"]).out.split(separator: "\n").map(String.init)
        guard known.contains(printer) else {
            reply(false, "La stampante \"\(printer)\" non e' installata su questo Mac. Scegline una installata (Impostazioni di Sistema > Stampanti) oppure salva il PDF.", id: id)
            return
        }
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".pdf")
        do { try data.write(to: tmp) } catch { reply(false, "Impossibile preparare il file: \(error.localizedDescription)", id: id); return }
        let w = (b["widthPt"] as? Double) ?? 0, h = (b["heightPt"] as? Double) ?? 0
        let cups = (b["cupsSize"] as? String) ?? ""
        var args = ["-d", printer, "-t", filename, "-o", "fit-to-page=false", "-o", "scaling=100"]
        args += ["-o", "PageSize=" + (cups.isEmpty ? String(format: "Custom.%.1fx%.1f", w, h) : cups)]
        args.append(tmp.path)
        DispatchQueue.global().async {
            let r = self.shell("/usr/bin/lp", args)
            try? FileManager.default.removeItem(at: tmp)
            if r.status == 0 { self.reply(true, "Inviato a \(printer). \(r.out.trimmingCharacters(in: .whitespacesAndNewlines))", id: id) }
            else { self.reply(false, "Stampa non riuscita: \(r.err.trimmingCharacters(in: .whitespacesAndNewlines))", id: id) }
        }
    }

    func shell(_ path: String, _ args: [String]) -> (status: Int32, out: String, err: String) {
        let p = Process(); p.executableURL = URL(fileURLWithPath: path); p.arguments = args
        let o = Pipe(), e = Pipe(); p.standardOutput = o; p.standardError = e
        do { try p.run() } catch { return (-1, "", error.localizedDescription) }
        let od = o.fileHandleForReading.readDataToEndOfFile(), ed = e.fileHandleForReading.readDataToEndOfFile()
        p.waitUntilExit()
        return (p.terminationStatus, String(data: od, encoding: .utf8) ?? "", String(data: ed, encoding: .utf8) ?? "")
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
