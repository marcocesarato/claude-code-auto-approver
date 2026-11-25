import Foundation

public enum Product {
    public static let name = "Claude Code - Auto Approver"
    public static let author = "Marco Cesarato"
    public static let repository = URL(string: "https://github.com/marcocesarato/claude-code-auto-approver")!
}

/// The app's own words, in the first of the user's languages it has; English otherwise.
public enum L10n {
    public enum Key: CaseIterable {
        case running, runningBody, needsAccessBody, by, statusOn, statusOff, detailOn, detailNeedsAccess
        case pause, resume, openLog, quit, untilResume, pausedUntil, skipChats, noChats
        case openWindow, paneStatus, paneChats, paneActivity, paneSettings, openAccessibility, skipHint
        case approvals, noActivity, labelsTitle, labelsHint, save, launchAtLogin, hide
        case edit, cut, copy, paste, selectAll, window, minimize, close
        case search, noResults, pages, approvedToday, lastApproval, noneYet, recent, showAll, manage, openChats, skippedChats
        case accessibility, granted, notGranted, keepAwake, keepAwakeBody, all, notifications, openNow, skippedClosed
        case general, files, showInFinder, about, builtInLabels, license
    }

    private static let name = Product.name
    private static let author = Product.author

    static let table: [String: [Key: String]] = [
        "en": [.running: "\(name) is on", .runningBody: "Claude's permission prompts are accepted automatically",
               .needsAccessBody: "Open System Settings → Privacy & Security → Accessibility and turn on \(name)",
               .by: "by \(author)", .statusOn: "● Auto-approve on", .statusOff: "○ Paused",
               .detailOn: "Accepts Claude's permission prompts", .detailNeedsAccess: "⚠️ Needs the Accessibility permission",
               .pause: "Pause", .resume: "Resume", .openLog: "Open log", .quit: "Quit",
               .untilResume: "Until I resume", .pausedUntil: "○ Paused until %@", .skipChats: "Skip chats", .noChats: "No chat open",
               .openWindow: "Open window…", .paneStatus: "Status", .paneChats: "Chats", .paneActivity: "Activity",
               .paneSettings: "Settings", .openAccessibility: "Open Accessibility settings", .skipHint: "A ticked chat is left to you: its prompts are not answered.", .approvals: "Approvals",
               .noActivity: "Nothing approved yet", .labelsTitle: "Buttons to press", .labelsHint: "One label per line. Empty uses the built-in labels, in every language.", .save: "Save",
               .launchAtLogin: "Open at login", .hide: "Hide", .edit: "Edit", .cut: "Cut",
               .copy: "Copy", .paste: "Paste", .selectAll: "Select All", .window: "Window",
               .minimize: "Minimize", .close: "Close",
               .search: "Search", .noResults: "No results", .pages: "Pages", .approvedToday: "Approved today", .lastApproval: "Last approval", .noneYet: "None yet",
               .recent: "Recent", .showAll: "Show all", .manage: "Manage", .openChats: "Open chats",
               .skippedChats: "Skipped chats", .accessibility: "Accessibility", .granted: "Granted", .notGranted: "Not granted",
               .keepAwake: "Keeps the Mac awake", .keepAwakeBody: "While it approves, the Mac does not go to sleep on its own. The screen can still lock.", .all: "All", .notifications: "Notifications",
               .openNow: "Open now", .skippedClosed: "Skipped, not open", .general: "General", .files: "Files",
               .showInFinder: "Show in Finder", .about: "About", .builtInLabels: "Built-in labels", .license: "License"],
        "it": [.running: "\(name) è attivo", .runningBody: "I prompt di permesso di Claude vengono accettati automaticamente",
               .needsAccessBody: "Apri Impostazioni di Sistema → Privacy e sicurezza → Accessibilità e attiva \(name)",
               .by: "di \(author)", .statusOn: "● Approvazione automatica attiva", .statusOff: "○ In pausa",
               .detailOn: "Accetta i prompt di permesso di Claude", .detailNeedsAccess: "⚠️ Serve il permesso Accessibilità",
               .pause: "Pausa", .resume: "Riprendi", .openLog: "Apri log", .quit: "Esci",
               .untilResume: "Finché non lo riattivo", .pausedUntil: "○ In pausa fino alle %@", .skipChats: "Salta chat", .noChats: "Nessuna chat aperta",
               .openWindow: "Apri finestra…", .paneStatus: "Stato", .paneChats: "Chat", .paneActivity: "Attività",
               .paneSettings: "Impostazioni", .openAccessibility: "Apri le impostazioni Accessibilità", .skipHint: "Le chat spuntate restano a te: i loro prompt non vengono accettati.", .approvals: "Approvazioni",
               .noActivity: "Ancora nessuna approvazione", .labelsTitle: "Bottoni da premere", .labelsHint: "Un’etichetta per riga. Vuoto usa quelle predefinite, in ogni lingua.", .save: "Salva",
               .launchAtLogin: "Apri al login", .hide: "Nascondi", .edit: "Modifica", .cut: "Taglia",
               .copy: "Copia", .paste: "Incolla", .selectAll: "Seleziona tutto", .window: "Finestra",
               .minimize: "Contrai", .close: "Chiudi",
               .search: "Cerca", .noResults: "Nessun risultato", .pages: "Pagine", .approvedToday: "Approvati oggi", .lastApproval: "Ultima approvazione", .noneYet: "Ancora nessuna",
               .recent: "Recenti", .showAll: "Mostra tutte", .manage: "Gestisci", .openChats: "Chat aperte",
               .skippedChats: "Chat saltate", .accessibility: "Accessibilità", .granted: "Concesso", .notGranted: "Non concesso",
               .keepAwake: "Tiene sveglio il Mac", .keepAwakeBody: "Mentre approva, il Mac non va in stop da solo. Lo schermo può comunque bloccarsi.", .all: "Tutte", .notifications: "Notifiche",
               .openNow: "Aperte ora", .skippedClosed: "Saltate, non aperte", .general: "Generali", .files: "File",
               .showInFinder: "Mostra nel Finder", .about: "Info", .builtInLabels: "Etichette predefinite", .license: "Licenza"],
        "de": [.running: "\(name) ist aktiv", .runningBody: "Berechtigungsanfragen von Claude werden automatisch akzeptiert",
               .needsAccessBody: "Öffne Systemeinstellungen → Datenschutz & Sicherheit → Bedienungshilfen und aktiviere \(name)",
               .by: "von \(author)", .statusOn: "● Automatische Freigabe aktiv", .statusOff: "○ Pausiert",
               .detailOn: "Akzeptiert Claudes Berechtigungsanfragen", .detailNeedsAccess: "⚠️ Bedienungshilfen-Berechtigung erforderlich",
               .pause: "Pausieren", .resume: "Fortsetzen", .openLog: "Protokoll öffnen", .quit: "Beenden",
               .untilResume: "Bis ich fortsetze", .pausedUntil: "○ Pausiert bis %@", .skipChats: "Chats überspringen", .noChats: "Kein Chat geöffnet",
               .openWindow: "Fenster öffnen…", .paneStatus: "Status", .paneChats: "Chats", .paneActivity: "Aktivität",
               .paneSettings: "Einstellungen", .openAccessibility: "Bedienungshilfen öffnen", .skipHint: "Markierte Chats bleiben dir überlassen: Ihre Anfragen werden nicht beantwortet.", .approvals: "Freigaben",
               .noActivity: "Noch nichts freigegeben", .labelsTitle: "Zu drückende Tasten", .labelsHint: "Eine Beschriftung pro Zeile. Leer nutzt die eingebauten, in jeder Sprache.", .save: "Sichern",
               .launchAtLogin: "Beim Anmelden öffnen", .hide: "Ausblenden", .edit: "Bearbeiten", .cut: "Ausschneiden",
               .copy: "Kopieren", .paste: "Einsetzen", .selectAll: "Alles auswählen", .window: "Fenster",
               .minimize: "Im Dock ablegen", .close: "Schließen",
               .search: "Suchen", .noResults: "Keine Treffer", .pages: "Seiten", .approvedToday: "Heute freigegeben", .lastApproval: "Letzte Freigabe", .noneYet: "Noch keine",
               .recent: "Zuletzt", .showAll: "Alle anzeigen", .manage: "Verwalten", .openChats: "Offene Chats",
               .skippedChats: "Übersprungene Chats", .accessibility: "Bedienungshilfen", .granted: "Erteilt", .notGranted: "Nicht erteilt",
               .keepAwake: "Hält den Mac wach", .keepAwakeBody: "Während der Freigabe geht der Mac nicht von selbst in den Ruhezustand. Der Bildschirm kann sich trotzdem sperren.", .all: "Alle", .notifications: "Mitteilungen",
               .openNow: "Jetzt geöffnet", .skippedClosed: "Übersprungen, nicht geöffnet", .general: "Allgemein", .files: "Dateien",
               .showInFinder: "Im Finder zeigen", .about: "Über", .builtInLabels: "Eingebaute Beschriftungen", .license: "Lizenz"],
        "es": [.running: "\(name) está activo", .runningBody: "Las solicitudes de permiso de Claude se aceptan automáticamente",
               .needsAccessBody: "Abre Ajustes del Sistema → Privacidad y seguridad → Accesibilidad y activa \(name)",
               .by: "de \(author)", .statusOn: "● Aprobación automática activa", .statusOff: "○ En pausa",
               .detailOn: "Acepta las solicitudes de permiso de Claude", .detailNeedsAccess: "⚠️ Necesita el permiso de Accesibilidad",
               .pause: "Pausar", .resume: "Reanudar", .openLog: "Abrir registro", .quit: "Salir",
               .untilResume: "Hasta que lo reanude", .pausedUntil: "○ En pausa hasta las %@", .skipChats: "Omitir chats", .noChats: "Ningún chat abierto",
               .openWindow: "Abrir ventana…", .paneStatus: "Estado", .paneChats: "Chats", .paneActivity: "Actividad",
               .paneSettings: "Ajustes", .openAccessibility: "Abrir ajustes de Accesibilidad", .skipHint: "Los chats marcados quedan para ti: sus solicitudes no se aceptan.", .approvals: "Aprobaciones",
               .noActivity: "Nada aprobado todavía", .labelsTitle: "Botones que pulsar", .labelsHint: "Una etiqueta por línea. Vacío usa las predeterminadas, en todos los idiomas.", .save: "Guardar",
               .launchAtLogin: "Abrir al iniciar sesión", .hide: "Ocultar", .edit: "Edición", .cut: "Cortar",
               .copy: "Copiar", .paste: "Pegar", .selectAll: "Seleccionar todo", .window: "Ventana",
               .minimize: "Minimizar", .close: "Cerrar",
               .search: "Buscar", .noResults: "Sin resultados", .pages: "Páginas", .approvedToday: "Aprobados hoy", .lastApproval: "Última aprobación", .noneYet: "Ninguna todavía",
               .recent: "Recientes", .showAll: "Ver todo", .manage: "Gestionar", .openChats: "Chats abiertos",
               .skippedChats: "Chats omitidos", .accessibility: "Accesibilidad", .granted: "Concedido", .notGranted: "No concedido",
               .keepAwake: "Mantiene el Mac despierto", .keepAwakeBody: "Mientras aprueba, el Mac no entra en reposo por sí solo. La pantalla puede bloquearse igualmente.", .all: "Todas", .notifications: "Notificaciones",
               .openNow: "Abiertos ahora", .skippedClosed: "Omitidos, no abiertos", .general: "General", .files: "Archivos",
               .showInFinder: "Mostrar en el Finder", .about: "Acerca de", .builtInLabels: "Etiquetas predeterminadas", .license: "Licencia"],
        "fr": [.running: "\(name) est actif", .runningBody: "Les demandes d’autorisation de Claude sont acceptées automatiquement",
               .needsAccessBody: "Ouvrez Réglages Système → Confidentialité et sécurité → Accessibilité et activez \(name)",
               .by: "par \(author)", .statusOn: "● Approbation automatique active", .statusOff: "○ En pause",
               .detailOn: "Accepte les demandes d’autorisation de Claude", .detailNeedsAccess: "⚠️ Autorisation Accessibilité requise",
               .pause: "Mettre en pause", .resume: "Reprendre", .openLog: "Ouvrir le journal", .quit: "Quitter",
               .untilResume: "Jusqu’à ce que je reprenne", .pausedUntil: "○ En pause jusqu’à %@", .skipChats: "Ignorer des chats", .noChats: "Aucun chat ouvert",
               .openWindow: "Ouvrir la fenêtre…", .paneStatus: "État", .paneChats: "Chats", .paneActivity: "Activité",
               .paneSettings: "Réglages", .openAccessibility: "Ouvrir les réglages d’Accessibilité", .skipHint: "Les chats cochés vous sont laissés : leurs demandes ne sont pas acceptées.", .approvals: "Approbations",
               .noActivity: "Rien d’approuvé pour l’instant", .labelsTitle: "Boutons à presser", .labelsHint: "Un libellé par ligne. Vide utilise ceux intégrés, dans toutes les langues.", .save: "Enregistrer",
               .launchAtLogin: "Ouvrir à l’ouverture de session", .hide: "Masquer", .edit: "Édition", .cut: "Couper",
               .copy: "Copier", .paste: "Coller", .selectAll: "Tout sélectionner", .window: "Fenêtre",
               .minimize: "Placer dans le Dock", .close: "Fermer",
               .search: "Rechercher", .noResults: "Aucun résultat", .pages: "Pages", .approvedToday: "Approuvés aujourd’hui", .lastApproval: "Dernière approbation", .noneYet: "Aucune pour l’instant",
               .recent: "Récents", .showAll: "Tout afficher", .manage: "Gérer", .openChats: "Chats ouverts",
               .skippedChats: "Chats ignorés", .accessibility: "Accessibilité", .granted: "Accordée", .notGranted: "Non accordée",
               .keepAwake: "Garde le Mac éveillé", .keepAwakeBody: "Pendant l’approbation, le Mac ne se met pas en veille de lui-même. L’écran peut quand même se verrouiller.", .all: "Toutes", .notifications: "Notifications",
               .openNow: "Ouverts maintenant", .skippedClosed: "Ignorés, non ouverts", .general: "Général", .files: "Fichiers",
               .showInFinder: "Afficher dans le Finder", .about: "À propos", .builtInLabels: "Libellés intégrés", .license: "Licence"],
        "pt": [.running: "\(name) está ativo", .runningBody: "Os pedidos de permissão do Claude são aceitos automaticamente",
               .needsAccessBody: "Abra Ajustes do Sistema → Privacidade e Segurança → Acessibilidade e ative o \(name)",
               .by: "por \(author)", .statusOn: "● Aprovação automática ativa", .statusOff: "○ Em pausa",
               .detailOn: "Aceita os pedidos de permissão do Claude", .detailNeedsAccess: "⚠️ Precisa da permissão de Acessibilidade",
               .pause: "Pausar", .resume: "Retomar", .openLog: "Abrir registro", .quit: "Sair",
               .untilResume: "Até eu retomar", .pausedUntil: "○ Em pausa até %@", .skipChats: "Ignorar chats", .noChats: "Nenhum chat aberto",
               .openWindow: "Abrir janela…", .paneStatus: "Estado", .paneChats: "Chats", .paneActivity: "Atividade",
               .paneSettings: "Ajustes", .openAccessibility: "Abrir ajustes de Acessibilidade", .skipHint: "Os chats marcados ficam com você: seus pedidos não são aceitos.", .approvals: "Aprovações",
               .noActivity: "Nada aprovado ainda", .labelsTitle: "Botões a pressionar", .labelsHint: "Um rótulo por linha. Vazio usa os padrão, em todos os idiomas.", .save: "Salvar",
               .launchAtLogin: "Abrir ao iniciar sessão", .hide: "Ocultar", .edit: "Editar", .cut: "Cortar",
               .copy: "Copiar", .paste: "Colar", .selectAll: "Selecionar tudo", .window: "Janela",
               .minimize: "Minimizar", .close: "Fechar",
               .search: "Buscar", .noResults: "Nenhum resultado", .pages: "Páginas", .approvedToday: "Aprovados hoje", .lastApproval: "Última aprovação", .noneYet: "Nenhuma ainda",
               .recent: "Recentes", .showAll: "Mostrar tudo", .manage: "Gerenciar", .openChats: "Chats abertos",
               .skippedChats: "Chats ignorados", .accessibility: "Acessibilidade", .granted: "Concedida", .notGranted: "Não concedida",
               .keepAwake: "Mantém o Mac acordado", .keepAwakeBody: "Enquanto aprova, o Mac não entra em repouso sozinho. A tela ainda pode bloquear.", .all: "Todas", .notifications: "Notificações",
               .openNow: "Abertos agora", .skippedClosed: "Ignorados, não abertos", .general: "Geral", .files: "Arquivos",
               .showInFinder: "Mostrar no Finder", .about: "Sobre", .builtInLabels: "Rótulos padrão", .license: "Licença"],
        "ja": [.running: "\(name) が有効です", .runningBody: "Claude の許可リクエストを自動的に承認します",
               .needsAccessBody: "システム設定 → プライバシーとセキュリティ → アクセシビリティ で \(name) をオンにしてください",
               .by: "作成: \(author)", .statusOn: "● 自動承認オン", .statusOff: "○ 一時停止中",
               .detailOn: "Claude の許可リクエストを承認します", .detailNeedsAccess: "⚠️ アクセシビリティの許可が必要です",
               .pause: "一時停止", .resume: "再開", .openLog: "ログを開く", .quit: "終了",
               .untilResume: "再開するまで", .pausedUntil: "○ %@ まで一時停止中", .skipChats: "スキップするチャット", .noChats: "開いているチャットはありません",
               .openWindow: "ウインドウを開く…", .paneStatus: "状態", .paneChats: "チャット", .paneActivity: "アクティビティ",
               .paneSettings: "設定", .openAccessibility: "アクセシビリティ設定を開く", .skipHint: "チェックしたチャットの許可リクエストは承認しません。", .approvals: "承認",
               .noActivity: "まだ承認はありません", .labelsTitle: "押すボタン", .labelsHint: "1行に1つのラベル。空欄なら全言語の既定のラベルを使います。", .save: "保存",
               .launchAtLogin: "ログイン時に開く", .hide: "隠す", .edit: "編集", .cut: "カット",
               .copy: "コピー", .paste: "ペースト", .selectAll: "すべてを選択", .window: "ウインドウ",
               .minimize: "しまう", .close: "閉じる",
               .search: "検索", .noResults: "結果なし", .pages: "ページ", .approvedToday: "今日の承認", .lastApproval: "最後の承認", .noneYet: "まだありません",
               .recent: "最近", .showAll: "すべて表示", .manage: "管理", .openChats: "開いているチャット",
               .skippedChats: "スキップ中のチャット", .accessibility: "アクセシビリティ", .granted: "許可済み", .notGranted: "未許可",
               .keepAwake: "Macをスリープさせません", .keepAwakeBody: "承認中はMacが自動でスリープしません。画面のロックは引き続き行われます。", .all: "すべて", .notifications: "通知",
               .openNow: "現在開いている", .skippedClosed: "スキップ中（開いていない）", .general: "一般", .files: "ファイル",
               .showInFinder: "Finderで表示", .about: "情報", .builtInLabels: "既定のラベル", .license: "ライセンス"],
    ]

    public static let languages = Set(table.keys)

    /// The first of `preferred` (BCP 47 tags, most wanted first) the app has words for.
    public static func language(for preferred: [String]) -> String {
        preferred.map { String($0.prefix { $0 != "-" && $0 != "_" }) }.first { table[$0] != nil } ?? "en"
    }

    public static let current = language(for: Locale.preferredLanguages)

    public static func t(_ key: Key, language: String = current) -> String {
        table[language]?[key] ?? table["en"]![key]!
    }

    /// "1 hour", "30 minuti": a pause length in the app's language.
    public static func duration(_ seconds: TimeInterval, language: String = current) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .full
        var calendar = Calendar.current
        calendar.locale = Locale(identifier: language)
        formatter.calendar = calendar
        return formatter.string(from: seconds) ?? "\(Int(seconds / 60)) min"
    }

    /// A pause length as the menu and the window offer it: "1 hour", or "Until I resume" for nil.
    public static func pauseLength(_ seconds: TimeInterval?, language: String = current) -> String {
        seconds.map { duration($0, language: language) } ?? t(.untilResume, language: language)
    }

    /// "Today", "Yesterday" or "24 Nov 2026" for a day the log writes as "2026-11-24".
    public static func day(_ isoDay: String, language: String = current) -> String {
        let parser = DateFormatter()
        parser.locale = Locale(identifier: "en_US_POSIX")
        parser.dateFormat = "yyyy-MM-dd"
        guard let date = parser.date(from: isoDay) else { return isoDay }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: language)
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.doesRelativeDateFormatting = true
        return formatter.string(from: date)
    }

    /// "○ Paused until 15:30".
    public static func pausedUntil(_ date: Date, language: String = current) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: language)
        formatter.timeStyle = .short
        formatter.dateStyle = Calendar.current.isDateInToday(date) ? .none : .short
        return t(.pausedUntil, language: language).replacingOccurrences(of: "%@", with: formatter.string(from: date))
    }
}

public enum Pause {
    /// The pause lengths the menu offers; nil is "until I resume".
    public static let durations: [TimeInterval?] = [5 * 60, 15 * 60, 30 * 60, 3600, 3 * 3600, 6 * 3600, nil]
}
