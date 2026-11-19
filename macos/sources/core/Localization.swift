import Foundation

public enum Product {
    public static let name = "Claude Code - Auto Approver"
    public static let author = "Marco Cesarato"
}

/// The app's own words, in the first of the user's languages it has; English otherwise.
public enum L10n {
    public enum Key: CaseIterable {
        case running, runningBody, needsAccessBody, by, statusOn, statusOff, detailOn, detailNeedsAccess
        case pause, resume, openLog, quit, untilResume, pausedUntil, skipChats, noChats
    }

    private static let name = Product.name
    private static let author = Product.author

    static let table: [String: [Key: String]] = [
        "en": [.running: "\(name) is on", .runningBody: "Claude's permission prompts are accepted automatically",
               .needsAccessBody: "Open System Settings → Privacy & Security → Accessibility and turn on \(name)",
               .by: "by \(author)", .statusOn: "● Auto-approve on", .statusOff: "○ Paused",
               .detailOn: "Accepts Claude's permission prompts", .detailNeedsAccess: "⚠️ Needs the Accessibility permission",
               .pause: "Pause", .resume: "Resume", .openLog: "Open log", .quit: "Quit",
               .untilResume: "Until I resume", .pausedUntil: "○ Paused until %@", .skipChats: "Skip chats", .noChats: "No chat open"],
        "it": [.running: "\(name) è attivo", .runningBody: "I prompt di permesso di Claude vengono accettati automaticamente",
               .needsAccessBody: "Apri Impostazioni di Sistema → Privacy e sicurezza → Accessibilità e attiva \(name)",
               .by: "di \(author)", .statusOn: "● Approvazione automatica attiva", .statusOff: "○ In pausa",
               .detailOn: "Accetta i prompt di permesso di Claude", .detailNeedsAccess: "⚠️ Serve il permesso Accessibilità",
               .pause: "Pausa", .resume: "Riprendi", .openLog: "Apri log", .quit: "Esci",
               .untilResume: "Finché non lo riattivo", .pausedUntil: "○ In pausa fino alle %@", .skipChats: "Salta chat", .noChats: "Nessuna chat aperta"],
        "de": [.running: "\(name) ist aktiv", .runningBody: "Berechtigungsanfragen von Claude werden automatisch akzeptiert",
               .needsAccessBody: "Öffne Systemeinstellungen → Datenschutz & Sicherheit → Bedienungshilfen und aktiviere \(name)",
               .by: "von \(author)", .statusOn: "● Automatische Freigabe aktiv", .statusOff: "○ Pausiert",
               .detailOn: "Akzeptiert Claudes Berechtigungsanfragen", .detailNeedsAccess: "⚠️ Bedienungshilfen-Berechtigung erforderlich",
               .pause: "Pausieren", .resume: "Fortsetzen", .openLog: "Protokoll öffnen", .quit: "Beenden",
               .untilResume: "Bis ich fortsetze", .pausedUntil: "○ Pausiert bis %@", .skipChats: "Chats überspringen", .noChats: "Kein Chat geöffnet"],
        "es": [.running: "\(name) está activo", .runningBody: "Las solicitudes de permiso de Claude se aceptan automáticamente",
               .needsAccessBody: "Abre Ajustes del Sistema → Privacidad y seguridad → Accesibilidad y activa \(name)",
               .by: "de \(author)", .statusOn: "● Aprobación automática activa", .statusOff: "○ En pausa",
               .detailOn: "Acepta las solicitudes de permiso de Claude", .detailNeedsAccess: "⚠️ Necesita el permiso de Accesibilidad",
               .pause: "Pausar", .resume: "Reanudar", .openLog: "Abrir registro", .quit: "Salir",
               .untilResume: "Hasta que lo reanude", .pausedUntil: "○ En pausa hasta las %@", .skipChats: "Omitir chats", .noChats: "Ningún chat abierto"],
        "fr": [.running: "\(name) est actif", .runningBody: "Les demandes d’autorisation de Claude sont acceptées automatiquement",
               .needsAccessBody: "Ouvrez Réglages Système → Confidentialité et sécurité → Accessibilité et activez \(name)",
               .by: "par \(author)", .statusOn: "● Approbation automatique active", .statusOff: "○ En pause",
               .detailOn: "Accepte les demandes d’autorisation de Claude", .detailNeedsAccess: "⚠️ Autorisation Accessibilité requise",
               .pause: "Mettre en pause", .resume: "Reprendre", .openLog: "Ouvrir le journal", .quit: "Quitter",
               .untilResume: "Jusqu’à ce que je reprenne", .pausedUntil: "○ En pause jusqu’à %@", .skipChats: "Ignorer des chats", .noChats: "Aucun chat ouvert"],
        "pt": [.running: "\(name) está ativo", .runningBody: "Os pedidos de permissão do Claude são aceitos automaticamente",
               .needsAccessBody: "Abra Ajustes do Sistema → Privacidade e Segurança → Acessibilidade e ative o \(name)",
               .by: "por \(author)", .statusOn: "● Aprovação automática ativa", .statusOff: "○ Em pausa",
               .detailOn: "Aceita os pedidos de permissão do Claude", .detailNeedsAccess: "⚠️ Precisa da permissão de Acessibilidade",
               .pause: "Pausar", .resume: "Retomar", .openLog: "Abrir registro", .quit: "Sair",
               .untilResume: "Até eu retomar", .pausedUntil: "○ Em pausa até %@", .skipChats: "Ignorar chats", .noChats: "Nenhum chat aberto"],
        "ja": [.running: "\(name) が有効です", .runningBody: "Claude の許可リクエストを自動的に承認します",
               .needsAccessBody: "システム設定 → プライバシーとセキュリティ → アクセシビリティ で \(name) をオンにしてください",
               .by: "作成: \(author)", .statusOn: "● 自動承認オン", .statusOff: "○ 一時停止中",
               .detailOn: "Claude の許可リクエストを承認します", .detailNeedsAccess: "⚠️ アクセシビリティの許可が必要です",
               .pause: "一時停止", .resume: "再開", .openLog: "ログを開く", .quit: "終了",
               .untilResume: "再開するまで", .pausedUntil: "○ %@ まで一時停止中", .skipChats: "スキップするチャット", .noChats: "開いているチャットはありません"],
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
