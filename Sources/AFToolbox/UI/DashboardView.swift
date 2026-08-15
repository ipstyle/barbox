import AppKit
import CoreAudio
import SwiftUI
import UniformTypeIdentifiers

struct DashboardView: View {
    @Binding var path: [Route]
    @EnvironmentObject private var lang: LanguageStore
    @EnvironmentObject private var status: SystemStatusModel
    @EnvironmentObject private var wake: WakeManager
    @EnvironmentObject private var favorites: FavoritesStore
    @EnvironmentObject private var spaces: SpaceObserver
    @EnvironmentObject private var timerManager: TimerManager
    @EnvironmentObject private var stats: StatsModel
    @EnvironmentObject private var weather: WeatherModel

    @AppStorage("desktopCount") private var desktopCount = 6
    @AppStorage("dndShortcutName") private var dndShortcutName = "Nicht stören"
    @AppStorage("windowHeight") private var windowHeight = 560.0

    @State private var hotkeysReady = true
    @State private var dropHover = false

    // Regler
    @State private var brightness = 0.5
    @State private var hasBrightness = false
    @State private var volume = 50.0
    @State private var volumeLoaded = false
    @State private var volumeTask: Task<Void, Never>?
    @State private var audioDevices: [AudioDevice] = []
    @State private var currentAudioDevice: AudioObjectID?

    // Sortierung & Favoriten (IDs aus ToolCatalog)
    @AppStorage("toolOrder") private var toolOrderRaw = ""
    @AppStorage("quickOrder") private var quickOrderRaw = ""
    @AppStorage("toolFavorites") private var toolFavoritesRaw = ""
    @State private var toolOrder: [String] = []
    @State private var quickOrder: [String] = []
    @State private var toolFavorites: [String] = []
    @State private var draggingItem: String?
    @State private var draggingFavorite: String?
    @State private var dragBaseHeight: Double?

    private static let defaultSectionOrder = ["favorites", "sliders", "quick", "tools", "apps", "weather"]
    @AppStorage("sectionOrder") private var sectionOrderRaw = ""
    @State private var sectionOrder: [String] = []
    @State private var draggingSection: String?

    private var effectiveCount: Int { min(max(spaces.spaceCount ?? desktopCount, 1), 9) }

    @ViewBuilder
    private func sectionView(_ id: String) -> some View {
        switch id {
        case "favorites": favoritesToolsSection
        case "sliders": slidersSection
        case "quick": quickActionsSection
        case "tools": toolsSection
        case "apps": favoriteAppsSection
        case "weather": weatherSection
        default: EmptyView()
        }
    }

    // MARK: - Wetter

    private var weatherSection: some View {
        CollapsibleSection(lang.t("Wetter"), storageID: "weather") {
            VStack(spacing: 10) {
                if let current = weather.state {
                    HStack(spacing: 12) {
                        Image(systemName: WeatherModel.symbol(for: current.code))
                            .font(.system(size: 30))
                            .foregroundStyle(Theme.blue)
                            .frame(width: 40)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(Int(current.temperature.rounded())) °C")
                                .font(.system(size: 24, weight: .light))
                            Text("\(current.place) · \(lang.t(WeatherModel.text(for: current.code)))")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                            Text(lang.t("Wind ") + "\(Int(current.wind.rounded())) km/h" + lang.t(" · Feuchte ") + "\(current.humidity) %")
                                .font(.system(size: 9))
                                .foregroundStyle(.tertiary)
                        }
                        Spacer()
                    }
                    Divider()
                    HStack(spacing: 4) {
                        ForEach(current.days) { day in
                            VStack(spacing: 3) {
                                Text(Self.weekday(day.date))
                                    .font(.system(size: 9))
                                    .foregroundStyle(.secondary)
                                Image(systemName: WeatherModel.symbol(for: day.code))
                                    .font(.system(size: 13))
                                    .frame(height: 16)
                                Text("\(Int(day.tMax.rounded()))°")
                                    .font(.system(size: 10, weight: .medium))
                                Text("\(Int(day.tMin.rounded()))°")
                                    .font(.system(size: 9))
                                    .foregroundStyle(.secondary)
                                Text(day.rainProb >= 20 ? "\(day.rainProb) %" : " ")
                                    .font(.system(size: 8))
                                    .foregroundStyle(Theme.blue)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    HStack(spacing: 8) {
                        Text(lang.t("Stand ") + current.fetched.formatted(date: .omitted, time: .shortened) + (weather.usingFallback ? lang.t(" · Fallback-Ort") : "") + lang.t(" · MeteoSchweiz-Modell via Open-Meteo"))
                            .font(.system(size: 8))
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Spacer()
                        Button(lang.t("Wetter-App")) {
                            NSWorkspace.shared.openApplication(
                                at: URL(fileURLWithPath: "/System/Applications/Weather.app"),
                                configuration: NSWorkspace.OpenConfiguration())
                            closePopoverWindow()
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 10))
                        .foregroundStyle(Color.accentColor)
                        Button(lang.t("MeteoSchweiz")) {
                            openSystemURL("https://www.meteoschweiz.admin.ch")
                            closePopoverWindow()
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 10))
                        .foregroundStyle(Color.accentColor)
                    }
                } else if weather.loading {
                    HStack(spacing: 8) {
                        ProgressView().controlSize(.small)
                        Text(lang.t("Wetter wird geladen…"))
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                } else {
                    VStack(spacing: 6) {
                        Text(weather.errorText ?? lang.t("Noch keine Wetterdaten"))
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                        Button(lang.t("Wetter laden")) { weather.refresh() }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }
            .padding(10)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private static func weekday(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_CH")
        formatter.dateFormat = "EE"
        return formatter.string(from: date)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    #if !MAS_BUILD
                    desktopSection
                    #endif
                    statusChips
                    ForEach(sectionOrder, id: \.self) { id in
                        sectionView(id)
                            .overlay(alignment: .topTrailing) {
                                Image(systemName: "line.3.horizontal")
                                    .font(.system(size: 9))
                                    .foregroundStyle(.tertiary)
                                    .padding(.horizontal, 4)
                                    .contentShape(Rectangle())
                                    .help(lang.t("Sektion verschieben"))
                                    .onDrag {
                                        draggingSection = id
                                        return NSItemProvider(object: id as NSString)
                                    }
                            }
                            .onDrop(of: [.utf8PlainText], delegate: ReorderDropDelegate(
                                itemID: id, dragging: $draggingSection,
                                indexOf: { sectionOrder.firstIndex(of: $0) },
                                move: { from, to in sectionOrder.move(fromOffsets: IndexSet(integer: from), toOffset: to) },
                                finish: { sectionOrderRaw = sectionOrder.joined(separator: ",") }
                            ))
                    }
                }
                .padding(12)
            }
            Divider()
            footer
        }
        .onAppear {
            status.startPolling()
            spaces.refresh()
            hotkeysReady = DesktopSwitcher.hotkeysEnabled(count: effectiveCount)
            loadControls()
            loadOrders()
            weather.refreshIfNeeded()
        }
        .onDisappear { status.stopPolling() }
        .onChange(of: desktopCount) { _, _ in
            hotkeysReady = DesktopSwitcher.hotkeysEnabled(count: effectiveCount)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "wrench.adjustable")
                .font(.system(size: 12, weight: .semibold))
            Text("Toolbox")
                .font(.system(size: 11, weight: .semibold))
            Spacer()
            statsInline
            Spacer()
            Button { path.append(Route.appList) } label: {
                Image(systemName: "magnifyingglass").font(.system(size: 13))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help(lang.t("App-Liste durchsuchen"))
            Button { path.append(Route.settings) } label: {
                Image(systemName: "gearshape").font(.system(size: 13))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help(lang.t("Einstellungen"))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var statsInline: some View {
        HStack(spacing: 14) {
            statItem(icon: "cpu", value: stats.cpu, help: lang.t("CPU-Auslastung"))
            statItem(icon: "memorychip", value: stats.mem, help: lang.t("RAM belegt"))
            if let gpu = stats.gpu {
                statItem(icon: "display", value: gpu, help: lang.t("GPU-Auslastung"))
            }
        }
    }

    private func statItem(icon: String, value: Int, help: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
            Text("\(value) %")
                .font(.system(size: 10, weight: .medium).monospacedDigit())
                .foregroundStyle(value >= 85 ? Theme.orange : Color.primary.opacity(0.85))
        }
        .help(help)
    }

    // MARK: - Desktops

    private var desktopSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                SectionTitle(lang.t("Desktops"))
                if let current = spaces.currentIndex {
                    Text(lang.t("· aktiv: ") + "\(current)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.accentColor)
                }
                Spacer()
                if !DesktopSwitcher.isTrusted {
                    Button {
                        DesktopSwitcher.requestPermission()
                        DesktopSwitcher.openAccessibilitySettings()
                    } label: {
                        Label(lang.t("Freigabe nötig"), systemImage: "exclamationmark.triangle")
                            .font(.system(size: 10))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Theme.orange)
                    .help(lang.t("Zum Wechseln braucht AF-Toolbox die Bedienungshilfen-Freigabe — Klick öffnet die Einstellung"))
                } else if !hotkeysReady {
                    Button {
                        DesktopSwitcher.enableHotkeys(count: 9)
                        hotkeysReady = DesktopSwitcher.hotkeysEnabled(count: effectiveCount)
                    } label: {
                        Label(lang.t("Klick-Wechsel einrichten"), systemImage: "wand.and.stars")
                            .font(.system(size: 10))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Theme.orange)
                    .help(lang.t("Aktiviert einmalig die macOS-Kurzbefehle Ctrl+1…9, über die der Klick-Wechsel läuft — du musst sie nie selbst drücken"))
                }
            }
            HStack(spacing: 6) {
                desktopButton(icon: "chevron.left", help: lang.t("Vorheriger Desktop")) {
                    DesktopSwitcher.previous()
                }
                ForEach(1...effectiveCount, id: \.self) { number in
                    let isCurrent = number == spaces.currentIndex
                    Button {
                        DesktopSwitcher.switchTo(number)
                    } label: {
                        Text("\(number)")
                            .font(.system(size: 12, weight: isCurrent ? .bold : .medium))
                            .frame(width: 28, height: 26)
                            .background(isCurrent ? Theme.cardActive : Theme.card,
                                        in: RoundedRectangle(cornerRadius: 7))
                            .foregroundStyle(isCurrent ? Color.accentColor : Color.primary)
                            .contentShape(RoundedRectangle(cornerRadius: 7))
                    }
                    .buttonStyle(.plain)
                    .help(isCurrent ? lang.t("Aktueller Desktop") : lang.t("Zu Desktop ") + "\(number)" + lang.t(" wechseln"))
                }
                desktopButton(icon: "chevron.right", help: lang.t("Nächster Desktop")) {
                    DesktopSwitcher.next()
                }
                Spacer()
            }
        }
    }

    private func desktopButton(icon: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .medium))
                .frame(width: 24, height: 26)
                .background(Theme.card, in: RoundedRectangle(cornerRadius: 7))
                .contentShape(RoundedRectangle(cornerRadius: 7))
        }
        .buttonStyle(.plain)
        .help(help)
    }

    // MARK: - Status-Chips

    private var statusChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            chipRow.padding(.vertical, 1)
        }
    }

    private var chipRow: some View {
        HStack(spacing: 8) {
            if let percent = status.batteryPercent {
                StatusChip(icon: status.batteryCharging ? "battery.100.bolt" : batteryIcon(percent),
                           text: "\(percent) %",
                           active: true,
                           tint: percent <= 20 ? Theme.red : Theme.green,
                           help: lang.t("Batterie — Klick öffnet die Batterie-Einstellungen")) {
                    openSystemURL("x-apple.systempreferences:com.apple.Battery-Settings.extension")
                }
            }
            if let wifiOn = status.wifiOn {
                Menu {
                    #if !MAS_BUILD
                    Button(lang.t("Einschalten")) { status.setWifi(on: true) }
                        .disabled(wifiOn)
                    Button(lang.t("Ausschalten")) { status.setWifi(on: false) }
                        .disabled(!wifiOn)
                    Divider()
                    #endif
                    Button(lang.t("WLAN-Einstellungen…")) {
                        openSystemURL("x-apple.systempreferences:com.apple.wifi-settings-extension")
                    }
                } label: {
                    StatusChipLabel(icon: wifiOn ? "wifi" : "wifi.slash",
                                    text: lang.t("WLAN"), active: wifiOn, tint: Theme.blue, showsChevron: true)
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .fixedSize()
            }
            if let btOn = status.bluetoothOn {
                Menu {
                    #if !MAS_BUILD
                    if status.blueutilPath != nil {
                        Button(lang.t("Einschalten")) { status.setBluetooth(on: true) }
                            .disabled(btOn)
                        Button(lang.t("Ausschalten")) { status.setBluetooth(on: false) }
                            .disabled(!btOn)
                        Divider()
                    } else {
                        Text(lang.t("Schalten braucht blueutil (siehe Einstellungen)"))
                    }
                    #endif
                    Button(lang.t("Bluetooth-Einstellungen…")) {
                        openSystemURL("x-apple.systempreferences:com.apple.BluetoothSettings")
                    }
                } label: {
                    StatusChipLabel(icon: "dot.radiowaves.left.and.right",
                                    text: lang.t("Bluetooth"), active: btOn, tint: Theme.indigo, showsChevron: true)
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .fixedSize()
            }
            #if !MAS_BUILD
            airDropChip
            #endif
            if status.busy {
                ProgressView().controlSize(.small)
            }
        }
    }

    #if !MAS_BUILD
    private var airDropChip: some View {
        let mode = status.airDropMode
        let active = mode == "Everyone" || mode == "Contacts Only"
        let modeKey: String? = switch mode {
        case "Everyone": "AirDrop · Alle"
        case "Contacts Only": "AirDrop · Kontakte"
        case "Off": "AirDrop · Aus"
        default: nil
        }
        return Menu {
            Button(lang.t("Fenster öffnen")) {
                QuickActions.openAirDrop()
                closePopoverWindow()
            }
            Divider()
            Button(lang.t("Empfang: Alle")) { status.setAirDropMode("Everyone") }
            Button(lang.t("Empfang: Nur Kontakte")) { status.setAirDropMode("Contacts Only") }
            Button(lang.t("Empfang: Aus")) { status.setAirDropMode("Off") }
        } label: {
            StatusChipLabel(icon: "paperplane",
                            text: modeKey.map { lang.t($0) } ?? lang.t("AirDrop"),
                            active: active, tint: Theme.blue, showsChevron: true)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
    }
    #endif

    private func batteryIcon(_ percent: Int) -> String {
        switch percent {
        case ..<13: return "battery.0percent"
        case ..<38: return "battery.25percent"
        case ..<63: return "battery.50percent"
        case ..<88: return "battery.75percent"
        default: return "battery.100percent"
        }
    }

    // MARK: - Werkzeug-Favoriten

    private var favoritesToolsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionTitle(lang.t("Favoriten"))
            Group {
                if toolFavorites.isEmpty {
                    Text(lang.t("Noch leer — zieh dir Werkzeuge und Schnellaktionen hierher"))
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                } else {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                        ForEach(toolFavorites, id: \.self) { id in
                            if let item = ToolCatalog.item(id) {
                                tile(for: item)
                                    .contextMenu {
                                        Button(lang.t("Aus Favoriten entfernen"), role: .destructive) {
                                            toolFavorites.removeAll { $0 == id }
                                            saveFavorites()
                                        }
                                    }
                                    .onDrag {
                                        draggingItem = id
                                        return NSItemProvider(object: id as NSString)
                                    }
                                    .onDrop(of: [.utf8PlainText], delegate: FavoritesDropDelegate(
                                        itemID: id, dragging: $draggingItem,
                                        favorites: $toolFavorites, save: saveFavorites))
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .frame(maxWidth: .infinity)
            .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [5]))
                    .foregroundStyle(Color.secondary.opacity(0.25))
            )
            .onDrop(of: [.utf8PlainText], delegate: FavoritesDropDelegate(
                itemID: nil, dragging: $draggingItem,
                favorites: $toolFavorites, save: saveFavorites))
        }
    }

    // MARK: - Regler

    private var slidersSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionTitle(lang.t("Regler"))
            VStack(spacing: 10) {
                if hasBrightness {
                    HStack(spacing: 8) {
                        Image(systemName: "sun.min").font(.system(size: 11)).foregroundStyle(.secondary)
                        Slider(value: $brightness, in: 0...1)
                            .controlSize(.small)
                            .onChange(of: brightness) { _, value in
                                Brightness.set(value)
                            }
                        Image(systemName: "sun.max").font(.system(size: 12)).foregroundStyle(.secondary)
                    }
                }
                if volumeLoaded {
                    HStack(spacing: 8) {
                        Image(systemName: "speaker").font(.system(size: 11)).foregroundStyle(.secondary)
                        Slider(value: $volume, in: 0...100)
                            .controlSize(.small)
                            .onChange(of: volume) { _, value in
                                volumeTask?.cancel()
                                volumeTask = Task {
                                    try? await Task.sleep(nanoseconds: 120_000_000)
                                    guard !Task.isCancelled else { return }
                                    await VolumeControl.set(Int(value))
                                }
                            }
                        Image(systemName: "speaker.wave.3").font(.system(size: 12)).foregroundStyle(.secondary)
                    }
                }
                if !audioDevices.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "hifispeaker").font(.system(size: 11)).foregroundStyle(.secondary)
                        Menu {
                            ForEach(audioDevices) { device in
                                Button {
                                    AudioDevices.setDefaultOutput(device.id)
                                    currentAudioDevice = device.id
                                } label: {
                                    if device.id == currentAudioDevice {
                                        Label(device.name, systemImage: "checkmark")
                                    } else {
                                        Text(device.name)
                                    }
                                }
                            }
                        } label: {
                            Text(audioDevices.first(where: { $0.id == currentAudioDevice })?.name ?? lang.t("Ausgabegerät"))
                                .font(.system(size: 11))
                                .lineLimit(1)
                        }
                        .menuStyle(.borderlessButton)
                    }
                }
            }
            .padding(10)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private func loadControls() {
        if let value = Brightness.current() {
            brightness = value
            hasBrightness = true
        }
        Task {
            if let value = await VolumeControl.current() {
                volume = Double(value)
                volumeLoaded = true
            }
        }
        audioDevices = AudioDevices.outputDevices()
        currentAudioDevice = AudioDevices.defaultOutput()
    }

    // MARK: - Schnellaktionen & Werkzeuge (einklappbar, sortierbar)

    private var quickActionsSection: some View {
        CollapsibleSection(lang.t("System Settings"), storageID: "quick") {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                ForEach(quickOrder, id: \.self) { id in
                    if let item = ToolCatalog.item(id) {
                        tile(for: item)
                            .onDrag {
                                draggingItem = id
                                return NSItemProvider(object: id as NSString)
                            }
                            .onDrop(of: [.utf8PlainText], delegate: ReorderDropDelegate(
                                itemID: id, dragging: $draggingItem,
                                indexOf: { quickOrder.firstIndex(of: $0) },
                                move: { from, to in quickOrder.move(fromOffsets: IndexSet(integer: from), toOffset: to) },
                                finish: { quickOrderRaw = quickOrder.joined(separator: ",") }
                            ))
                    }
                }
            }
        }
    }

    private var toolsSection: some View {
        CollapsibleSection(lang.t("Werkzeuge"), storageID: "tools") {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                ForEach(toolOrder, id: \.self) { id in
                    if let item = ToolCatalog.item(id) {
                        tile(for: item)
                            .contextMenu {
                                if !toolFavorites.contains(id) {
                                    Button(lang.t("Zu Favoriten")) {
                                        toolFavorites.append(id)
                                        saveFavorites()
                                    }
                                }
                            }
                            .onDrag {
                                draggingItem = id
                                return NSItemProvider(object: id as NSString)
                            }
                            .onDrop(of: [.utf8PlainText], delegate: ReorderDropDelegate(
                                itemID: id, dragging: $draggingItem,
                                indexOf: { toolOrder.firstIndex(of: $0) },
                                move: { from, to in toolOrder.move(fromOffsets: IndexSet(integer: from), toOffset: to) },
                                finish: { toolOrderRaw = toolOrder.joined(separator: ",") }
                            ))
                    }
                }
            }
        }
    }

    private func loadOrders() {
        if toolOrder.isEmpty {
            toolOrder = ToolCatalog.order(from: toolOrderRaw, defaults: ToolCatalog.tools)
        }
        if quickOrder.isEmpty {
            quickOrder = ToolCatalog.order(from: quickOrderRaw, defaults: ToolCatalog.quickActions)
        }
        if toolFavorites.isEmpty {
            toolFavorites = toolFavoritesRaw.split(separator: ",").map(String.init)
                .filter { ToolCatalog.item($0) != nil }
        }
        if sectionOrder.isEmpty {
            let stored = sectionOrderRaw.split(separator: ",").map(String.init)
                .filter { Self.defaultSectionOrder.contains($0) }
            sectionOrder = stored + Self.defaultSectionOrder.filter { !stored.contains($0) }
        }
    }

    private func saveFavorites() {
        toolFavoritesRaw = toolFavorites.joined(separator: ",")
    }

    // MARK: - Kacheln (einheitlich aus dem Catalog)

    @ViewBuilder
    private func tile(for item: ToolItem) -> some View {
        switch item.id {
        case "wake":
            ToolTile(icon: wake.isActive ? "cup.and.saucer.fill" : "cup.and.saucer",
                     title: lang.t(item.title),
                     active: wake.isActive,
                     subtitle: wakeSubtitle) {
                wake.toggle()
            }
            .contextMenu {
                Button(lang.t("Unbegrenzt")) { wake.start(minutes: nil) }
                Button(lang.t("30 Minuten")) { wake.start(minutes: 30) }
                Button(lang.t("1 Stunde")) { wake.start(minutes: 60) }
                Button(lang.t("2 Stunden")) { wake.start(minutes: 120) }
                if wake.isActive {
                    Divider()
                    Button(lang.t("Ausschalten")) { wake.stop() }
                }
            }
        case "timer":
            ToolTile(icon: item.icon, title: lang.t(item.title),
                     active: timerManager.isRunning,
                     subtitle: timerSubtitle) {
                perform(item)
            }
        default:
            ToolTile(icon: item.icon, title: lang.t(item.title)) {
                perform(item)
            }
        }
    }

    private func perform(_ item: ToolItem) {
        switch item.action {
        case .route(let route):
            path.append(route)
        case .wakeToggle:
            wake.toggle()
        case .darkMode:
            QuickActions.toggleDarkMode()
        case .airDrop:
            #if !MAS_BUILD
            QuickActions.openAirDrop()
            closePopoverWindow()
            #endif
        case .activityMonitor:
            QuickActions.openActivityMonitor()
            closePopoverWindow()
        case .focus:
            Task {
                let ok = await QuickActions.runShortcut(dndShortcutName)
                if !ok {
                    let alert = NSAlert()
                    alert.messageText = String(format: LanguageStore.current("Kurzbefehl «%@» nicht gefunden"), dndShortcutName)
                    alert.informativeText = LanguageStore.current("Lege in der Kurzbefehle-App einen Kurzbefehl mit genau diesem Namen an, der den Fokus «Nicht stören» umschaltet (Aktion «Fokus festlegen»). Der Name lässt sich in den AF-Toolbox-Einstellungen ändern.")
                    alert.addButton(withTitle: LanguageStore.current("Kurzbefehle öffnen"))
                    alert.addButton(withTitle: LanguageStore.current("OK"))
                    NSApplication.shared.activate(ignoringOtherApps: true)
                    if alert.runModal() == .alertFirstButtonReturn {
                        _ = try? await NSWorkspace.shared.openApplication(
                            at: URL(fileURLWithPath: "/System/Applications/Shortcuts.app"),
                            configuration: NSWorkspace.OpenConfiguration())
                    }
                }
            }
        }
    }

    private var wakeSubtitle: String? {
        guard wake.isActive else { return nil }
        if let until = wake.until {
            return lang.t("bis ") + until.formatted(date: .omitted, time: .shortened)
        }
        return lang.t("aktiv")
    }

    private var timerSubtitle: String? {
        guard timerManager.isRunning else { return nil }
        let total = Int(timerManager.remaining.rounded())
        return String(format: "%02d:%02d", total / 60, total % 60)
    }

    // MARK: - App-Favoriten

    private var favoriteAppsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionTitle(lang.t("Meine Apps"))
            Group {
                if favorites.apps.isEmpty {
                    Text(lang.t("Apps aus dem Finder hierhin ziehen"))
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                } else {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
                        ForEach(favorites.apps) { app in
                            AppIconView(path: app.path, size: 36)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    favorites.launch(app)
                                    closePopoverWindow()
                                }
                                .help(app.name)
                                .contextMenu {
                                    Button(lang.t("Im Finder zeigen")) {
                                        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: app.path)])
                                    }
                                    Button(lang.t("Entfernen"), role: .destructive) {
                                        favorites.remove(app)
                                    }
                                }
                                .onDrag {
                                    draggingFavorite = app.id
                                    return NSItemProvider(object: app.id as NSString)
                                }
                                .onDrop(of: [.utf8PlainText], delegate: ReorderDropDelegate(
                                    itemID: app.id,
                                    dragging: $draggingFavorite,
                                    indexOf: { id in favorites.apps.firstIndex(where: { $0.id == id }) },
                                    move: { from, to in favorites.move(from: IndexSet(integer: from), to: to) },
                                    finish: {}
                                ))
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .frame(maxWidth: .infinity)
            .background(Color.white.opacity(dropHover ? 0.10 : 0.03), in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [5]))
                    .foregroundStyle(dropHover ? Color.accentColor : Color.secondary.opacity(0.35))
            )
            .dropDestination(for: URL.self) { urls, _ in
                var added = false
                for url in urls where url.pathExtension == "app" {
                    favorites.add(url: url)
                    added = true
                }
                return added
            } isTargeted: { hovering in
                dropHover = hovering
            }
        }
    }

    // MARK: - Fusszeile mit Zieh-Griff

    private var footer: some View {
        HStack {
            Text("Toolbox \(AppInfo.version)")
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
            Spacer()
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
                .help(lang.t("Ziehen, um das Fenster höher oder kürzer zu machen"))
                .gesture(
                    DragGesture(coordinateSpace: .global)
                        .onChanged { value in
                            if dragBaseHeight == nil { dragBaseHeight = windowHeight }
                            windowHeight = min(900, max(480, (dragBaseHeight ?? windowHeight) + value.translation.height))
                        }
                        .onEnded { _ in dragBaseHeight = nil }
                )
            Spacer()
            Button(lang.t("Beenden")) { NSApplication.shared.terminate(nil) }
                .buttonStyle(.plain)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }
}
