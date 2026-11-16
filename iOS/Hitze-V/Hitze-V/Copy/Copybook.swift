import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case bg
    case da
    case de
    case en
    case et
    case fi
    case fr
    case el
    case ga
    case it
    case hr
    case lv
    case lt
    case mt
    case nl
    case pl
    case pt
    case ro
    case sv
    case sk
    case sl
    case es
    case cs
    case hu
    case tr

    var id: String { rawValue }

    var resolvedLanguage: ResolvedLanguage {
        switch self {
        case .de:
            return .de
        case .bg:
            return .bg
        case .da:
            return .da
        case .en:
            return .en
        case .et:
            return .et
        case .fi:
            return .fi
        case .fr:
            return .fr
        case .el:
            return .el
        case .ga:
            return .ga
        case .it:
            return .it
        case .hr:
            return .hr
        case .lv:
            return .lv
        case .lt:
            return .lt
        case .mt:
            return .mt
        case .nl:
            return .nl
        case .pl:
            return .pl
        case .pt:
            return .pt
        case .ro:
            return .ro
        case .sv:
            return .sv
        case .sk:
            return .sk
        case .sl:
            return .sl
        case .es:
            return .es
        case .cs:
            return .cs
        case .hu:
            return .hu
        case .tr:
            return .tr
        case .system:
            let languageCode = Locale.current.language.languageCode?.identifier.lowercased() ?? "en"
            switch languageCode {
            case "de": return .de
            case "bg": return .bg
            case "da": return .da
            case "en": return .en
            case "et": return .et
            case "fi": return .fi
            case "fr": return .fr
            case "el": return .el
            case "ga": return .ga
            case "it": return .it
            case "hr": return .hr
            case "lv": return .lv
            case "lt": return .lt
            case "mt": return .mt
            case "nl": return .nl
            case "pl": return .pl
            case "pt": return .pt
            case "ro": return .ro
            case "sv": return .sv
            case "sk": return .sk
            case "sl": return .sl
            case "es": return .es
            case "cs": return .cs
            case "hu": return .hu
            case "tr": return .tr
            default: return .en
            }
        }
    }
}

enum ResolvedLanguage {
    case de
    case bg
    case da
    case en
    case et
    case fi
    case fr
    case el
    case ga
    case it
    case hr
    case lv
    case lt
    case mt
    case nl
    case pl
    case pt
    case ro
    case sv
    case sk
    case sl
    case es
    case cs
    case hu
    case tr

    var languageCode: String {
        switch self {
        case .de: return "de"
        case .bg: return "bg"
        case .da: return "da"
        case .en: return "en"
        case .et: return "et"
        case .fi: return "fi"
        case .fr: return "fr"
        case .el: return "el"
        case .ga: return "ga"
        case .it: return "it"
        case .hr: return "hr"
        case .lv: return "lv"
        case .lt: return "lt"
        case .mt: return "mt"
        case .nl: return "nl"
        case .pl: return "pl"
        case .pt: return "pt"
        case .ro: return "ro"
        case .sv: return "sv"
        case .sk: return "sk"
        case .sl: return "sl"
        case .es: return "es"
        case .cs: return "cs"
        case .hu: return "hu"
        case .tr: return "tr"
        }
    }
}

struct Copybook {
    let language: ResolvedLanguage

    struct InfoGroup {
        let title: String
        let bullets: [InfoBullet]
    }

    struct InfoSection {
        let title: String
        let groups: [InfoGroup]
    }

    struct InfoBullet {
        let text: String
        let cta: InfoCTA?
    }

    struct InfoCTA {
        let label: String
        let url: URL
    }

    func t(_ german: String, _ english: String) -> String {
        switch language {
        case .de:
            return german
        case .en:
            return english
        default:
            if let translated = CopybookTranslationCatalog.translation(for: language, english: english) {
                return translated
            }
            assertionFailure("Missing translation for \(language.languageCode): \(english)")
            return english
        }
    }

    private func bulletLines(_ german: String, _ english: String) -> [InfoBullet] {
        t(german, english)
            .split(separator: "\n")
            .map { InfoBullet(text: String($0), cta: nil) }
    }

    /// The app name is never translated.
    var shortTitle: String { "HitzeV" }
    var dashboardTitle: String { t("Sicher durch die Hitze", "Heat Safety at a Glance") }
    var glanceTitle: String { t("Schnellübersicht", "Quick Glance") }
    var glanceSubtitle: String { t("Maximalwerte aller Arbeitsplätze", "Maximum values across all workplaces") }
    var currentRiskTitle: String { t("Aktuelles Risiko", "Current Risk") }
    var uvPeakTitle: String { t("Höchster UV", "Peak UV") }
    var apparentTitle: String { t("Gefühlt max. (Prognose)", "Feels like max (forecast)") }
    var apparentAccessibilityLabel: String { t("Gefühlte Höchsttemperatur (Prognose)", "Feels-like maximum temperature (forecast)") }
    var uvAccessibilityLabel: String { t("Höchster UV-Index", "Maximum UV index") }
    var workplaceLabel: String { t("Arbeitsplätze", "Workplaces") }
    var warningsLabel: String { t("Hitzewarnungen", "Heat warnings") }
    var addWorkplaceTitle: String { t("Neuer Arbeitsplatz", "New Workplace") }
    var addWorkplaceButton: String { t("Arbeitsplatz hinzufügen", "Add workplace") }
    var namePlaceholder: String { t("Bezeichnung (optional)", "Label (optional)") }
    var addressPlaceholder: String { t("Adresse oder Ort suchen", "Search address or place") }
    var searchResultsTitle: String { t("Treffer auswählen", "Choose a result") }
    var useAddressButton: String { t("Hinzufügen", "Add") }
    var addingWorkplace: String { t("Wird hinzugefügt …", "Adding…") }
    var clearSearchLabel: String { t("Suche löschen", "Clear search") }
    var monitoredWorkplacesTitle: String { t("Überwachte Arbeitsplätze", "Monitored Workplaces") }
    var noWorkplaces: String { t("Noch keine Arbeitsplätze vorhanden.", "No workplaces yet.") }
    var noWorkplacesDescription: String { t("Füge einen Arbeitsplatz hinzu, um Hitze- und UV-Warnungen dafür zu sehen.", "Add a workplace to see heat and UV warnings for it.") }
    var loading: String { t("Lade Live-Daten", "Loading live data") }
    var loadFailed: String { t("Daten konnten nicht geladen werden.", "Data could not be loaded.") }
    var notUpToDate: String { t("Nicht aktuell", "Not up to date") }
    var retryButton: String { t("Erneut versuchen", "Try again") }
    var deleteWorkplace: String { t("Arbeitsplatz löschen", "Delete workplace") }
    var notAvailableShort: String { "—" }
    var notAvailableSpoken: String { t("nicht verfügbar", "not available") }
    var cancelButton: String { t("Abbrechen", "Cancel") }
    var settingsCloseButton: String { t("Schließen", "Close") }
    var settingsTitle: String { t("Einstellungen", "Settings") }
    var infoButtonLabel: String { t("Info öffnen", "Open info") }
    var infoScreenTitle: String { t("Info", "Info") }
    var infoScreenHeatMeasuresTitle: String { t("Hitze-Schutzmaßnahmen", "Heat Protection Measures") }
    var infoScreenHeatScaleTitle: String { t("Skala der Hitzewarnstufen", "Heat warning scale") }
    var infoScreenUvMeasuresTitle: String { t("UV-Schutzmaßnahmen", "UV Protection Measures") }
    var infoScreenUvLevel5Title: String { t("Ab UV-Index 5", "UV index 5 or higher") }
    var infoScreenLevel2Title: String { t("2 (gefühlte Temperatur ≥ 30 °C)", "2 (apparent temperature ≥ 30 °C)") }
    var infoScreenLevel3Title: String { t("3 (gefühlte Temperatur ≥ 35 °C)", "3 (apparent temperature ≥ 35 °C)") }
    var infoScreenLevel4Title: String { t("4 (gefühlte Temperatur ≥ 40 °C)", "4 (apparent temperature ≥ 40 °C)") }

    var heroLoadingHeadline: String { t("Daten werden geladen", "Loading data") }
    var heroUnknownHeadline: String { t("Warnstatus unbekannt", "Warning status unknown") }
    var heroLoadFailedText: String { t("Aktuelle Daten konnten nicht geladen werden. Bitte Verbindung prüfen und aktualisieren.", "Current data could not be loaded. Check your connection and refresh.") }
    var heroPartialDataText: String { t("Für einige Arbeitsplätze fehlen aktuelle Daten. Warnungen sind möglicherweise unvollständig.", "Current data is missing for some workplaces. Warnings may be incomplete.") }
    var heroNoWorkplacesText: String { t("Lege einen Arbeitsplatz an, um Hitzewarnungen zu sehen.", "Add a workplace to see heat warnings.") }
    var unknownRisk: String { t("Unbekannt", "Unknown") }

    func updatedAt(_ time: String) -> String {
        String(format: t("Stand: %@", "Updated %@"), time)
    }

    func municipalityFallback(_ id: String) -> String {
        String(format: t("Gemeinde %@", "Municipality %@"), id)
    }

    // MARK: Push permission

    var pushDeniedTitle: String { t("Mitteilungen sind ausgeschaltet", "Notifications are turned off") }
    var pushDeniedMessage: String {
        t(
            "Du hast Mitteilungen für HitzeV nicht erlaubt. Hitzewarnungen können dich deshalb nicht als Push-Benachrichtigung erreichen. Du kannst das in der Einstellungen-App ändern.",
            "You have not allowed notifications for HitzeV, so heat warnings cannot reach you as push notifications. You can change this in the Settings app."
        )
    }
    var openSettingsButton: String { t("Einstellungen öffnen", "Open Settings") }
    var pushSyncFailedMessage: String {
        t(
            "Für einige Arbeitsplätze konnten Push-Benachrichtigungen nicht eingerichtet werden. Die App versucht es beim nächsten Aktualisieren erneut.",
            "Push notifications could not be set up for some workplaces. The app will try again on the next refresh."
        )
    }

    var infoIntro: String {
        t(
            "Ab einer Hitzewarnung der Stufe 2 (ab 30 °C) müssen ein Maßnahmenprogramm und Notfallmaßnahmen umgesetzt werden. Mögliche Maßnahmen sind z.B.",
            "Starting at heat warning level 2 (from 30 °C), a response plan and emergency measures must be implemented. Possible measures include:"
        )
    }
    var heatProgramSection: InfoSection {
        InfoSection(
            title: t("Maßnahmenprogramm (STOP-Prinzip)", "Response plan (STOP principle)"),
            groups: [
                InfoGroup(
                    title: t("Technische Maßnahmen", "Technical measures"),
                    bullets: bulletLines(
                        """
                        Beschattung von Arbeits- und Pausenplätzen mit Sonnenschirmen, Pavillons etc.
                        Technische Kühlmaßnahmen wie z.B. Ventilatoren
                        Reduzierung körperlich anstrengender Arbeiten z. B. durch Hebehilfen
                        """,
                        """
                        Shade work and rest areas with parasols, pavilions, etc.
                        Technical cooling measures such as fans
                        Reduce physically strenuous work, e.g. by using lifting aids
                        """
                    )
                ),
                InfoGroup(
                    title: t("Organisatorische Maßnahmen", "Organizational measures"),
                    bullets: bulletLines(
                        """
                        Verlagerung von schweren Arbeiten in kühlere Tageszeiten
                        Pausen zum Abkühlen
                        Schwere Tätigkeiten im Schatten/Kühlen verrichten
                        """,
                        """
                        Shift heavy work to cooler times of day
                        Take breaks to cool down
                        Carry out heavy tasks in shade or cool areas
                        """
                    )
                ),
                InfoGroup(
                    title: t("Persönliche Schutzmaßnahmen", "Personal protective measures"),
                    bullets: bulletLines(
                        """
                        Ausreichend Trinkwasser bereitstellen
                        Leichte Arbeitskleidung mit UV-Schutz und Sonnenschutzmittel (LSF von 50 empfohlen), UV-Schutzbrille, Kühltücher
                        Je nach Einsatzgebiet: Schutzhelm mit Nackenschutz
                        """,
                        """
                        Provide sufficient drinking water
                        Light work clothing with UV protection and sunscreen (SPF 50 recommended), UV-protective glasses, cooling towels
                        Depending on the work area: safety helmet with neck protection
                        """
                    )
                )
            ]
        )
    }
    var heatEmergencySection: InfoSection {
        InfoSection(
            title: t("Notfallmaßnahmen", "Emergency measures"),
            groups: [
                InfoGroup(
                    title: t("Hitzebedingte Symptome können sein", "Heat-related symptoms can include"),
                    bullets: bulletLines(
                        """
                        Kopfschmerzen, Schwindel, Übelkeit
                        Schwäche, Krämpfe, Verwirrtheit
                        Heiße, trockene oder stark schwitzende Haut
                        Bewusstseinsstörungen
                        """,
                        """
                        Headaches, dizziness, nausea
                        Weakness, cramps, confusion
                        Hot, dry skin or very sweaty skin
                        Impaired consciousness
                        """
                    )
                ),
                InfoGroup(
                    title: t("Mögliche Notfallmaßnahmen", "Possible emergency measures"),
                    bullets: [
                        InfoBullet(
                            text: t(
                                "Arbeit unterbrechen und Betroffene in den Schatten/ins Kühle bringen",
                                "Stop work and move the affected person to shade or a cool place"
                            ),
                            cta: nil
                        ),
                        InfoBullet(
                            text: t(
                                "Kühlung des Körpers z.B. durch feuchte Tücher oder Ventilation",
                                "Cool the body, e.g. with damp cloths or ventilation"
                            ),
                            cta: nil
                        ),
                        InfoBullet(
                            text: t("Kleidung lockern", "Loosen clothing"),
                            cta: nil
                        ),
                        InfoBullet(
                            text: t(
                                "Langsam trinken lassen (Wasser, Tee, Elektrolytlösungen)",
                                "Let the person drink slowly (water, tea, electrolyte solutions)"
                            ),
                            cta: nil
                        ),
                        InfoBullet(
                            text: t(
                                "Bei Bewusstlosigkeit in stabile Seitenlage bringen",
                                "If unconscious, place the person in the recovery position"
                            ),
                            cta: nil
                        ),
                        InfoBullet(
                            text: t(
                                "Notruf (144) wählen, wenn Zustand nicht bald besser oder Anzeichen von Bewusstlosigkeit",
                                "Call emergency services (144) if the condition does not improve soon or there are signs of loss of consciousness"
                            ),
                            cta: nil
                        ),
                        InfoBullet(
                            text: t(
                                "Bis zum Eintreffen der Rettung Bewusstsein und Atmung kontrollieren",
                                "Monitor consciousness and breathing until emergency services arrive"
                            ),
                            cta: nil
                        ),
                        InfoBullet(
                            text: t(
                                "Ist keine normale Atmung vorhanden, sofort Wiederbelebungsmaßnahmen einleiten – Hilfe holen!",
                                "If there is no normal breathing, start CPR immediately and get help"
                            ),
                            cta: emergencyCallCTA
                        )
                    ]
                )
            ]
        )
    }
    var optionalChecklistCta: InfoCTA? {
        guard let urlString = Self.infoChecklistURL, let url = URL(string: urlString) else {
            return nil
        }
        return InfoCTA(
            label: t(
                "Hier geht’s zur Hitzeschutzcheckliste für Betriebe",
                "Heat protection checklist for businesses"
            ),
            url: url
        )
    }
    var uvSection: InfoSection {
        InfoSection(
            title: infoScreenUvMeasuresTitle,
            groups: [
                InfoGroup(
                    title: infoScreenUvLevel5Title,
                    bullets: [
                        InfoBullet(text: uvInfoDetail5Plus, cta: nil),
                        InfoBullet(text: uvInfoMeasures5Plus, cta: nil)
                    ]
                )
            ]
        )
    }
    var emergencyCallCTA: InfoCTA? {
        guard let url = URL(string: "tel://144") else {
            return nil
        }
        return InfoCTA(
            label: t("Jetzt 144 anrufen", "Call 144 now"),
            url: url
        )
    }
    var appearanceSection: String { t("Erscheinungsbild", "Appearance") }
    var aboutSection: String { t("Info & Rechtliches", "Info & Legal") }
    var dataSourceLine: String {
        t(
            "Datenquellen: GeoSphere Austria (Hitzewarnungen), Open-Meteo (UV-Index und gefühlte Temperatur, CC BY 4.0)",
            "Data sources: GeoSphere Austria (heat warnings), Open-Meteo (UV index and feels-like temperature, CC BY 4.0)"
        )
    }
    var warningAllDay: String { t("Ganztägig", "All day") }
    var themeSystem: String { t("System", "System") }
    var themeLight: String { t("Hell", "Light") }
    var themeDark: String { t("Dunkel", "Dark") }
    var languageSection: String { t("Sprache", "Language") }
    var machineTranslationDisclaimer: String {
        switch language {
        case .de:
            return "Texte in anderen Sprachen werden maschinell aus dem Deutschen übersetzt. Für Vollständigkeit und Korrektheit dieser Übersetzungen kann keine Gewähr übernommen werden."
        case .bg:
            return "Текстовете на други езици са машинно преведени от немски. Не се дава гаранция за пълнотата или точността на тези преводи."
        case .da:
            return "Tekster på andre sprog er maskinoversat fra tysk. Der gives ingen garanti for disse oversættelsers fuldstændighed eller korrekthed."
        case .en:
            return "Texts in other languages are machine-translated from German. No guarantee is given for the completeness or accuracy of these translations."
        case .et:
            return "Teistes keeltes olevad tekstid on saksa keelest masintõlgitud. Nende tõlgete täielikkuse ega õigsuse eest ei anta garantiid."
        case .fi:
            return "Muiden kielten tekstit on konekäännetty saksasta. Näiden käännösten täydellisyydestä tai oikeellisuudesta ei anneta takuuta."
        case .fr:
            return "Les textes dans les autres langues sont traduits automatiquement à partir de l’allemand. Aucune garantie n’est donnée quant à l’exhaustivité ou à l’exactitude de ces traductions."
        case .el:
            return "Τα κείμενα σε άλλες γλώσσες έχουν μεταφραστεί αυτόματα από τα γερμανικά. Δεν παρέχεται καμία εγγύηση για την πληρότητα ή την ακρίβεια αυτών των μεταφράσεων."
        case .ga:
            return "Tá na téacsanna i dteangacha eile aistrithe go huathoibríoch ón nGearmáinis. Ní thugtar aon ráthaíocht maidir le hiomláine ná cruinneas na n-aistriúchán seo."
        case .it:
            return "I testi nelle altre lingue sono tradotti automaticamente dal tedesco. Non viene fornita alcuna garanzia circa la completezza o la correttezza di queste traduzioni."
        case .hr:
            return "Tekstovi na drugim jezicima strojno su prevedeni s njemačkog. Ne daje se nikakvo jamstvo za potpunost ili točnost tih prijevoda."
        case .lv:
            return "Teksti citās valodās ir mašīntulkoti no vācu valodas. Netiek sniegta nekāda garantija par šo tulkojumu pilnīgumu vai pareizību."
        case .lt:
            return "Tekstai kitomis kalbomis yra automatiškai išversti iš vokiečių kalbos. Nėra teikiama jokia garantija dėl šių vertimų išsamumo ar tikslumo."
        case .mt:
            return "It-testi b'lingwi oħra huma tradotti b'mod awtomatiku mill-Ġermaniż. Ma tingħata ebda garanzija dwar il-kompletezza jew il-korrettezza ta' dawn it-traduzzjonijiet."
        case .nl:
            return "Teksten in andere talen zijn machinaal vertaald vanuit het Duits. Voor de volledigheid of juistheid van deze vertalingen wordt geen garantie gegeven."
        case .pl:
            return "Teksty w innych językach są tłumaczone maszynowo z języka niemieckiego. Nie udziela się żadnej gwarancji co do kompletności ani poprawności tych tłumaczeń."
        case .pt:
            return "Os textos noutros idiomas são traduzidos automaticamente do alemão. Não é dada qualquer garantia quanto à integralidade ou correção dessas traduções."
        case .ro:
            return "Textele în alte limbi sunt traduse automat din germană. Nu se oferă nicio garanție privind caracterul complet sau corectitudinea acestor traduceri."
        case .sv:
            return "Texter på andra språk är maskinöversatta från tyska. Ingen garanti lämnas för att dessa översättningar är fullständiga eller korrekta."
        case .sk:
            return "Texty v iných jazykoch sú strojovo preložené z nemčiny. Za úplnosť ani správnosť týchto prekladov sa neposkytuje žiadna záruka."
        case .sl:
            return "Besedila v drugih jezikih so strojno prevedena iz nemščine. Za popolnost ali pravilnost teh prevodov ni mogoče jamčiti."
        case .es:
            return "Los textos en otros idiomas están traducidos automáticamente del alemán. No se ofrece ninguna garantía sobre la integridad o la exactitud de estas traducciones."
        case .cs:
            return "Texty v jiných jazycích jsou strojově přeloženy z němčiny. Za úplnost ani správnost těchto překladů se neposkytuje žádná záruka."
        case .hu:
            return "A más nyelveken megjelenő szövegek németből gépi fordítással készültek. E fordítások teljességéért vagy helyességéért nem vállalunk garanciát."
        case .tr:
            return "Diğer dillerdeki metinler Almancadan makine çevirisiyle çevrilmiştir. Bu çevirilerin eksiksizliği veya doğruluğu konusunda herhangi bir garanti verilmez."
        }
    }
    var mockModeActiveBadge: String { t("Mock aktiv", "Mock active") }
    var mockModeBanner: String {
        t(
            "Mock-Modus aktiv: Es werden zufällige Testdaten angezeigt. Push-Benachrichtigungen sind davon nicht betroffen.",
            "Mock mode active: random test data is shown. Push notifications are not affected."
        )
    }
    var mockModeSessionHint: String {
        t(
            "Mock-Modus ist bis zum nächsten App-Neustart aktiv.",
            "Mock mode stays active until the app is restarted."
        )
    }
    var mockModeActivatedTitle: String { t("Mock-Modus aktiviert", "Mock mode enabled") }
    var mockModeActivatedMessage: String {
        t(
            "Für diese App-Sitzung werden zufällige Warnstufen für alle Arbeitsplätze angezeigt. Beim nächsten Neustart ist der Modus wieder aus.",
            "This app session now shows random warning levels for all worksites. The mode turns off again on the next restart."
        )
    }
    var legalLinkURL: String { "https://www.arbeitsmediziner.wien" }
    var legalLinkLabel: String { "arbeitsmediziner.wien" }
    var onboardingWelcomeTitle: String { t("Willkommen bei HitzeV", "Welcome to HitzeV") }
    var onboardingWelcomeText: String { t("Wir helfen dir, die gesetzlichen Vorgaben zu Gefahren durch Hitze und natürliche UV-Strahlung bei Arbeiten im Freien einzuhalten. Behalte Temperaturen und UV-Index immer im Blick.", "We help you comply with legal requirements regarding hazards from heat and natural UV radiation for outdoor work. Keep an eye on temperatures and UV index at all times.") }
    var onboardingPushTitle: String { t("Bleib informiert", "Stay informed") }
    var onboardingPushText: String {
        t(
            "Damit wir dich bei gefährlichen Hitzewerten an deinen Arbeitsplätzen rechtzeitig warnen können, benötigen wir deine Erlaubnis für Push-Benachrichtigungen. Push-Nachrichten sind aktuell nur für Hitzewarnmeldungen auf iOS und Android verfügbar. UV-Warnmeldungen können derzeit nicht per Push versendet werden.",
            "So that we can warn you in time about dangerous heat levels at your workplaces, we need your permission for push notifications. Push notifications are currently only available for heat warnings on iOS and Android. UV warnings cannot be sent as push notifications at the moment."
        )
    }
    var continueButton: String { t("Weiter", "Continue") }
    var todayTitle: String { t("Heute", "Today") }
    var uvWarningBadge5Plus: String { "UV ≥ 5" }
    var uvInfoDetail5Plus: String { t("Ab UV-Index 5 steigt die Belastung deutlich. Schutzkleidung, Kopfbedeckung, Sonnenbrille und Sonnencreme konsequent verwenden.", "At UV index 5 and above, exposure increases significantly. Consistently use protective clothing, head covering, sunglasses, and sunscreen.") }
    var uvInfoMeasures5Plus: String { t("Direkte Sonne und belastende Arbeiten möglichst in den Schatten verlagern und Aufenthalte in voller Sonne begrenzen.", "Move direct sun exposure and strenuous work into shade whenever possible and limit time spent in full sun.") }

    func languageOption(_ language: AppLanguage) -> String {
        localizedLanguageName(for: language)
    }

    func severityName(_ severity: HazardSeverity) -> String {
        switch severity {
        case .none:
            return t("Grün", "Green")
        case .heatYellow:
            return t("Gelb", "Yellow")
        case .heatOrange:
            return t("Orange", "Orange")
        case .heatRed:
            return t("Rot", "Red")
        }
    }

    func levelShort(_ level: Int) -> String {
        String(format: t("Stufe %d", "Level %d"), locale: locale, level)
    }

    /// "Hitzewarnstufe 3 (Orange)" or "Keine Hitzewarnung"; never conveys the level by colour alone.
    func severityDescription(_ severity: HazardSeverity) -> String {
        guard severity.isHeatWarning else {
            return t("Keine Hitzewarnung", "No heat warning")
        }
        return String(format: t("Hitzewarnstufe %d (%@)", "Heat warning level %d (%@)"), locale: locale, severity.level, severityName(severity))
    }

    func severityHeadline(_ severity: HazardSeverity) -> String {
        switch severity {
        case .none:
            return t("Stabil", "Stable")
        case .heatYellow:
            return t("Erhöht", "Elevated")
        case .heatOrange:
            return t("Hoch", "High")
        case .heatRed:
            return t("Kritisch", "Critical")
        }
    }

    func severityAction(_ severity: HazardSeverity) -> String {
        switch severity {
        case .none:
            return t("Alles ruhig. Standardmaßnahmen reichen aus.", "All clear. Standard precautions are sufficient.")
        case .heatYellow:
            return t("Pausen und Schatten erhöhen.", "Increase breaks and shade usage.")
        case .heatOrange:
            return t("Arbeitszeiten anpassen und Teams aktiv schützen.", "Adjust schedules and actively protect teams.")
        case .heatRed:
            return t("Sofort Schutzmaßnahmen nach Hitze-V umsetzen.", "Take protective measures as required by the Hitze-V immediately.")
        }
    }

    func uvOnlyAction(worksitesCount: Int) -> String {
        let format = worksitesCount == 1
            ? t("%d Arbeitsplatz mit UV-Index 5 oder höher. UV-Schutzmaßnahmen umsetzen.", "%d workplace with UV index 5 or higher. Implement UV protection measures.")
            : t("%d Arbeitsplätze mit UV-Index 5 oder höher. UV-Schutzmaßnahmen umsetzen.", "%d workplaces with UV index 5 or higher. Implement UV protection measures.")
        let message = String(format: format, locale: locale, worksitesCount)
        guard let lineBreakRange = message.range(of: ". ") else {
            return message
        }
        return message.replacingCharacters(in: lineBreakRange, with: ".\n")
    }

    func copyrightLine(year: Int) -> String {
        "© \(year) SFK Robert Lembacher \(t("und", "and")) Dr. Thomas Entner"
    }

    private static let infoChecklistURL: String? = nil
}
