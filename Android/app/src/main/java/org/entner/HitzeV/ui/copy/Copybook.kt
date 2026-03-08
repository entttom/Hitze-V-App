package org.entner.HitzeV.ui.copy

import org.entner.HitzeV.model.AppLanguage
import org.entner.HitzeV.model.HazardSeverity
import org.entner.HitzeV.model.ResolvedLanguage
import java.time.DayOfWeek
import java.time.LocalDate

class Copybook(private val language: ResolvedLanguage) {
    fun t(german: String, english: String): String = when (language) {
        ResolvedLanguage.DE -> german
        ResolvedLanguage.EN -> english
        else -> TRANSLATIONS[language]?.get(english)
            ?: LONG_TEXT_TRANSLATIONS[language]?.get(english)
            ?: english
    }

    val shortTitle: String = t("Hitze-V", "Heat-V")
    val dashboardTitle: String = t("Sicher durch die Hitze", "Heat Safety at a Glance")
    val dashboardSubtitle: String = t(
        "Ampelstatus, UV und Arbeitsplätze live auf einen Blick.",
        "Traffic-light status, UV and workplaces live in one view."
    )
    val glanceTitle: String = t("Schnellübersicht", "Quick Glance")
    val glanceSubtitle: String = t("Maximalwerte aller Arbeitsplätze", "Maximum values across all workplaces")
    val currentRiskTitle: String = t("Aktuelles Risiko", "Current Risk")
    val uvPeakTitle: String = t("Höchster UV", "Peak UV")
    val apparentTitle: String = t("Max. gefühlte Temp", "Max. Feels Like")
    val workplaceLabel: String = t("Arbeitsplätze", "Workplaces")
    val warningsLabel: String = t("Warnungen", "Warnings")
    val addWorkplaceTitle: String = t("Neuen Arbeitsplatz anlegen", "Create New Workplace")
    val namePlaceholder: String = t("Bezeichnung (optional)", "Label (optional)")
    val addressPlaceholder: String = t("Adresse oder Ort suchen", "Search address or place")
    val addressFieldHint: String = t("Stadt, Straße...", "City, Street...")
    val searchAddressButton: String = t("Adresse suchen", "Search Address")
    val searchResultsTitle: String = t("Treffer auswählen", "Choose a result")
    val useAddressButton: String = t("Hinzufügen", "Add")
    val monitoredWorkplacesTitle: String = t("Überwachte Arbeitsplätze", "Monitored Workplaces")
    val noWorkplaces: String = t("Noch keine Arbeitsplätze vorhanden.", "No workplaces yet.")
    val loading: String = t("Lade Live-Daten", "Loading live data")
    val refreshButton: String = t("Aktualisieren", "Refresh")
    val deleteWorkplace: String = t("Arbeitsplatz löschen", "Delete workplace")
    val cancelButton: String = t("Abbrechen", "Cancel")
    val settingsCloseButton: String = t("Schließen", "Close")
    val settingsTitle: String = t("Einstellungen", "Settings")
    val infoScreenTitle: String = t("Info", "Info")
    val infoButtonLabel: String = t("Info öffnen", "Open info")
    val notAvailableShort: String = t("n/v", "n/a")
    val warningAllDay: String = t("Ganztägig", "All day")
    val heatWarningLevelLabel: String = t("Hitzewarnstufe", "Heat warning level")
    val addOutsideAustriaMessage: String = t(
        "Dieses Gebiet liegt vermutlich außerhalb Österreichs oder wird von GeoSphere nicht erkannt. Ein Hinzufügen ist nicht möglich.",
        "This area is likely outside Austria or not recognized by GeoSphere. Adding is not possible."
    )
    val uvWarningBadge67: String = t("UV-Warnung 6-7", "UV Warning 6-7")
    val uvWarningBadge810: String = t("UV-Warnung 8-10", "UV Warning 8-10")
    val uvWarningBadge11Plus: String = t("UV-Warnung >= 11", "UV Warning >= 11")
    val uvWarningDetail67: String = t(
        "Direkte Sonne zwischen 11:00 und 15:00 Uhr auf max. 2 Stunden begrenzen, sonst Schatten oder Indoor.",
        "Limit direct sun exposure between 11:00 and 15:00 to max. 2 hours, otherwise shade or indoors."
    )
    val uvWarningDetail67OutsideWindow: String = t(
        "Erhöhte UV-Belastung heute: Schutzkleidung, Kopfbedeckung, Sonnenbrille und Sonnencreme konsequent verwenden.",
        "Increased UV exposure today: consistently use protective clothing, head covering, sunglasses, and sunscreen."
    )
    val uvWarningDetail810: String = t(
        "Direkte Sonne zwischen 11:00 und 15:00 Uhr auf max. 1 Stunde begrenzen, sonst Schatten oder Indoor.",
        "Limit direct sun exposure between 11:00 and 15:00 to max. 1 hour, otherwise shade or indoors."
    )
    val uvWarningDetail810OutsideWindow: String = t(
        "Hohe UV-Belastung heute: Schutzmaßnahmen konsequent umsetzen und Arbeiten bevorzugt in den Schatten verlagern.",
        "High UV exposure today: apply protective measures consistently and prioritize work in shade."
    )
    val uvWarningDetail11Plus: String = t(
        "UV-Index >= 11 wurde im österreichischen Flachland bisher nicht gemessen. Falls gemeldet: direkte Sonne vermeiden, nur mit maximalem Schutz arbeiten.",
        "UV index >= 11 has not been measured in Austrian lowland regions so far. If reported: avoid direct sun and work only with maximum protection."
    )
    val appearanceSection: String = t("Erscheinungsbild", "Appearance")
    val aboutSection: String = t("Info & Rechtliches", "Info & Legal")
    val dataSourceLine: String = t("Datenquelle: GeoSphere Austria", "Data source: GeoSphere Austria")
    val geocodingAttributionLine: String = "Geocoding data © OpenStreetMap contributors"
    val themeSystem: String = t("System", "System")
    val themeLight: String = t("Hell", "Light")
    val themeDark: String = t("Dunkel", "Dark")
    val languageSection: String = t("Sprache", "Language")
    val developerSection: String = t("Entwicklung", "Development")
    val customGeoSphereUrlLabel: String = t("GeoSphere Test-URL", "GeoSphere test URL")
    val customGeoSphereUrlHint: String = t(
        "Wenn gesetzt, wird diese URL statt des GeoSphere-Servers verwendet.",
        "If set, this URL is used instead of the GeoSphere server."
    )
    val customGeoSphereUrlPlaceholder: String = "https://example.com/geosphere.json"
    val legalLinkURL: String = "https://www.arbeitsmediziner.wien"
    val legalLinkLabel: String = "arbeitsmediziner.wien"
    val onboardingWelcomeTitle: String = t("Willkommen bei Hitze-V", "Welcome to Hitze-V")
    val onboardingWelcomeText: String = t(
        "Wir helfen dir, die gesetzlichen Vorgaben zu Gefahren durch Hitze und natürliche UV-Strahlung bei Arbeiten im Freien einzuhalten. Behalte Temperaturen und UV-Index immer im Blick.",
        "We help you comply with legal requirements regarding hazards from heat and natural UV radiation for outdoor work. Keep an eye on temperatures and UV index at all times."
    )
    val onboardingPushTitle: String = t("Bleib informiert", "Stay informed")
    val onboardingPushText: String = t(
        "Damit wir dich bei gefährlichen Hitzewerten an deinen Arbeitsplätzen rechtzeitig warnen können, benötigen wir deine Erlaubnis für Push-Benachrichtigungen. Push-Nachrichten sind aktuell nur für Hitzewarnmeldungen auf iOS und Android verfügbar. UV-Warnmeldungen können derzeit nicht per Push versendet werden. Bitte erlaube diese im nächsten Schritt.",
        "So that we can warn you in time about dangerous heat levels at your workplaces, we need your permission for push notifications. Please allow them in the next step."
    )
    val onboardingAllowButton: String = t("Erlauben & Loslegen", "Allow & Start")
    val onboardingSkipButton: String = t("Später / Überspringen", "Later / Skip")
    val infoScreenHeatMeasuresTitle: String = t("Hitze-Schutzmaßnahmen", "Heat Protection Measures")
    val infoScreenHeatMeasuresSubtitle: String = t("Erklärung der Werte für die Stufen 2 bis 4", "Explanation of values for levels 2 to 4")
    val infoScreenUvMeasuresTitle: String = t("UV-Schutzmaßnahmen", "UV Protection Measures")
    val infoScreenUvMeasuresSubtitle: String = t(
        "Der höchste UV-Index des Tages bestimmt die Belastung durch UV-Strahlung. In Österreich ist von April bis September zwischen 11:00 und 15:00 Uhr meist mit einem UV-Index >= 5 zu rechnen.",
        "The highest UV index of the day determines UV exposure. In Austria, from April to September, a UV index >= 5 is usually expected between 11:00 and 15:00."
    )
    val infoScreenUvLevel35Title: String = t("UV-Index 3-5", "UV Index 3-5")
    val infoScreenUvLevel35Body: String = t(
        "Pflicht: T-Shirt bis mindestens Mitte Oberarm, Hose bis mindestens zum Knie. Empfohlen: Kopfbedeckung, Sonnenbrille, Sonnencreme. Keine Arbeitseinschränkungen.",
        "Mandatory: T-shirt to at least mid upper arm, trousers to at least the knee. Recommended: head covering, sunglasses, sunscreen. No work restrictions."
    )
    val infoScreenUvLevel67Title: String = t("UV-Index 6-7", "UV Index 6-7")
    val infoScreenUvLevel67Body: String = t(
        "Pflicht: Kleidung wie oben plus Kopfbedeckung (idealerweise mit Nackenschutz), Sonnenbrille und Sonnencreme. Arbeit in direkter Sonne zwischen 11:00 und 15:00 Uhr maximal 2 Stunden, sonst Schatten oder Indoor.",
        "Mandatory: clothing as above plus head covering (ideally with neck protection), sunglasses, and sunscreen. Direct sun exposure between 11:00 and 15:00 limited to a maximum of 2 hours, otherwise shade or indoors."
    )
    val infoScreenUvLevel810Title: String = t("UV-Index 8-10", "UV Index 8-10")
    val infoScreenUvLevel810Body: String = t(
        "Gleiche Schutzmaßnahmen wie bei UV-Index 6-7. Arbeit in direkter Sonne zwischen 11:00 und 15:00 Uhr maximal 1 Stunde, sonst Schatten oder Indoor.",
        "Same protective measures as UV index 6-7. Direct sun exposure between 11:00 and 15:00 limited to a maximum of 1 hour, otherwise shade or indoors."
    )
    val infoScreenUvLevel11Title: String = t("UV-Index >= 11", "UV Index >= 11")
    val infoScreenUvLevel11Body: String = t(
        "Wurde im österreichischen Flachland bisher nicht gemessen.",
        "Has not been measured in Austrian lowland regions so far."
    )
    val infoScreenLevel2Title: String = t("2 (gefühlte Temperatur ≥ 30 °C)", "2 (apparent temperature ≥ 30 °C)")
    val infoScreenLevel2Body: String = t(
        "Bei dieser Belastung sollte die Arbeit so organisiert werden, dass zwischen 11:00 und 15:00 Uhr keine mittelschweren Tätigkeiten im Freien durchgeführt werden. Nutzen Sie kühlere Tageszeiten, häufige Trinkpausen und schattige Bereiche, um die körperliche Belastung wirksam zu reduzieren.",
        "At this level, work should be organized so that no medium-heavy outdoor tasks are carried out between 11:00 and 15:00. Use cooler times of day, frequent hydration breaks, and shaded areas to effectively reduce physical strain."
    )
    val infoScreenLevel3Title: String = t("3 (gefühlte Temperatur ≥ 35 °C)", "3 (apparent temperature ≥ 35 °C)")
    val infoScreenLevel3Body: String = t(
        "Ab dieser Stufe sind Schutzmaßnahmen konsequent umzusetzen: Zwischen 11:00 und 15:00 Uhr maximal 2 Stunden direkte Sonneneinstrahlung, danach nur im Schatten oder in Innenbereichen arbeiten. Planen Sie zusätzliche Erholungspausen ein, rotieren Sie Teams und beobachten Sie Anzeichen von Hitzestress besonders aufmerksam.",
        "From this level onward, protective measures must be applied consistently: between 11:00 and 15:00, a maximum of 2 hours in direct sunlight, then continue work only in shade or indoors. Schedule extra recovery breaks, rotate teams, and closely monitor for signs of heat stress."
    )
    val infoScreenLevel4Title: String = t("4 (gefühlte Temperatur ≥ 40 °C)", "4 (apparent temperature ≥ 40 °C)")
    val infoScreenLevel4Body: String = t(
        "Diese Stufe bedeutet eine kritische Hitzebelastung. Tätigkeiten im Freien sollen nur dann stattfinden, wenn sie unbedingt notwendig und organisatorisch nicht verschiebbar sind. Priorisieren Sie sofortige Schutzmaßnahmen, verlagern Sie Arbeiten nach innen und stellen Sie eine engmaschige Betreuung der Beschäftigten sicher.",
        "This level indicates critical heat stress. Outdoor activities should only take place if they are absolutely necessary and cannot be postponed organizationally. Prioritize immediate protective actions, move tasks indoors whenever possible, and ensure close supervision of workers."
    )
    val enterAddressMessage: String = t("Bitte eine Adresse eingeben.", "Please enter an address.")
    val noAddressFoundMessage: String = t("Keine passende Adresse gefunden.", "No matching address found.")
    val addressSearchFailedMessage: String = t("Adresssuche fehlgeschlagen.", "Address search failed.")

    fun copyrightLine(year: Int): String = "© $year SFK Robert Lembacher und Dr. Thomas Entner"

    fun deleteWorkplaceMessage(name: String): String = t(
        "Der Arbeitsplatz \"$name\" wird gelöscht.",
        "The workplace \"$name\" will be deleted."
    )

    fun todayTitle(date: LocalDate): String = if (date == LocalDate.now()) t("Heute", "Today") else weekdayShort(date.dayOfWeek)

    fun weekdayShort(dayOfWeek: DayOfWeek): String = when (dayOfWeek) {
        DayOfWeek.MONDAY -> t("MO", "MON")
        DayOfWeek.TUESDAY -> t("DI", "TUE")
        DayOfWeek.WEDNESDAY -> t("MI", "WED")
        DayOfWeek.THURSDAY -> t("DO", "THU")
        DayOfWeek.FRIDAY -> t("FR", "FRI")
        DayOfWeek.SATURDAY -> t("SA", "SAT")
        DayOfWeek.SUNDAY -> t("SO", "SUN")
    }

    fun languageOption(language: AppLanguage): String = when (language) {
        AppLanguage.SYSTEM -> t("Systemsprache", "System language")
        AppLanguage.BG -> t("Bulgarisch", "Bulgarian")
        AppLanguage.DA -> t("Dänisch", "Danish")
        AppLanguage.DE -> t("Deutsch", "German")
        AppLanguage.EN -> t("Englisch", "English")
        AppLanguage.ET -> t("Estnisch", "Estonian")
        AppLanguage.FI -> t("Finnisch", "Finnish")
        AppLanguage.FR -> t("Französisch", "French")
        AppLanguage.EL -> t("Griechisch", "Greek")
        AppLanguage.GA -> t("Irisch", "Irish")
        AppLanguage.IT -> t("Italienisch", "Italian")
        AppLanguage.HR -> t("Kroatisch", "Croatian")
        AppLanguage.LV -> t("Lettisch", "Latvian")
        AppLanguage.LT -> t("Litauisch", "Lithuanian")
        AppLanguage.MT -> t("Maltesisch", "Maltese")
        AppLanguage.NL -> t("Niederländisch", "Dutch")
        AppLanguage.PL -> t("Polnisch", "Polish")
        AppLanguage.PT -> t("Portugiesisch", "Portuguese")
        AppLanguage.RO -> t("Rumänisch", "Romanian")
        AppLanguage.SV -> t("Schwedisch", "Swedish")
        AppLanguage.SK -> t("Slowakisch", "Slovak")
        AppLanguage.SL -> t("Slowenisch", "Slovenian")
        AppLanguage.ES -> t("Spanisch", "Spanish")
        AppLanguage.CS -> t("Tschechisch", "Czech")
        AppLanguage.HU -> t("Ungarisch", "Hungarian")
        AppLanguage.TR -> t("Türkisch", "Turkish")
    }

    fun severityHeadline(severity: HazardSeverity): String = when (severity) {
        HazardSeverity.NONE, HazardSeverity.COLD_YELLOW, HazardSeverity.COLD_ORANGE, HazardSeverity.COLD_RED -> t("Stabil", "Stable")
        HazardSeverity.HEAT_YELLOW -> t("Erhöht", "Elevated")
        HazardSeverity.HEAT_ORANGE -> t("Hoch", "High")
        HazardSeverity.HEAT_RED -> t("Kritisch", "Critical")
    }

    fun severityAction(severity: HazardSeverity): String = when (severity) {
        HazardSeverity.NONE, HazardSeverity.COLD_YELLOW, HazardSeverity.COLD_ORANGE, HazardSeverity.COLD_RED ->
            t("Alles ruhig. Standardmaßnahmen reichen aus.", "All clear. Standard precautions are sufficient.")
        HazardSeverity.HEAT_YELLOW -> t("Pausen und Schatten erhöhen.", "Increase breaks and shade usage.")
        HazardSeverity.HEAT_ORANGE -> t("Arbeitszeiten anpassen und Teams aktiv schützen.", "Adjust schedules and actively protect teams.")
        HazardSeverity.HEAT_RED -> t("Sofort Hitze-V Schutzmaßnahmen umsetzen.", "Apply Heat-V protective measures immediately.")
    }

    companion object {
        private val TRANSLATIONS: Map<ResolvedLanguage, Map<String, String>> = mapOf(
            ResolvedLanguage.BG to mapOf(
                "Settings" to "Настройки",
                "Language" to "Език",
                "Appearance" to "Външен вид",
                "Info & Legal" to "Информация и правна информация",
                "Development" to "Разработка",
                "System" to "Система",
                "Light" to "Светъл",
                "Dark" to "Тъмен",
                "Close" to "Затвори",
                "Cancel" to "Отказ",
                "Refresh" to "Обновяване",
                "Create New Workplace" to "Създаване на ново работно място",
                "Delete workplace" to "Изтриване на работно място",
                "Workplaces" to "Работни места",
                "Warnings" to "Предупреждения",
                "Current Risk" to "Текущ риск",
                "Peak UV" to "Пик UV",
                "Today" to "Днес"
            ),
            ResolvedLanguage.DA to mapOf(
                "Settings" to "Indstillinger",
                "Language" to "Sprog",
                "Appearance" to "Udseende",
                "Info & Legal" to "Info og jura",
                "Development" to "Udvikling",
                "System" to "System",
                "Light" to "Lys",
                "Dark" to "Mørk",
                "Close" to "Luk",
                "Cancel" to "Annuller",
                "Refresh" to "Opdater",
                "Create New Workplace" to "Opret ny arbejdsplads",
                "Delete workplace" to "Slet arbejdsplads",
                "Workplaces" to "Arbejdspladser",
                "Warnings" to "Advarsler",
                "Current Risk" to "Aktuel risiko",
                "Peak UV" to "Højeste UV",
                "Today" to "I dag"
            ),
            ResolvedLanguage.ET to mapOf(
                "Settings" to "Seaded",
                "Language" to "Keel",
                "Appearance" to "Välimus",
                "Info & Legal" to "Info ja õigus",
                "Development" to "Arendus",
                "System" to "Süsteem",
                "Light" to "Hele",
                "Dark" to "Tume",
                "Close" to "Sulge",
                "Cancel" to "Tühista",
                "Refresh" to "Värskenda",
                "Create New Workplace" to "Loo uus töökoht",
                "Delete workplace" to "Kustuta töökoht",
                "Workplaces" to "Töökohad",
                "Warnings" to "Hoiatused",
                "Current Risk" to "Praegune risk",
                "Peak UV" to "Maksimaalne UV",
                "Today" to "Täna"
            ),
            ResolvedLanguage.FI to mapOf(
                "Settings" to "Asetukset",
                "Language" to "Kieli",
                "Appearance" to "Ulkoasu",
                "Info & Legal" to "Tiedot ja oikeudellinen",
                "Development" to "Kehitys",
                "System" to "Järjestelmä",
                "Light" to "Vaalea",
                "Dark" to "Tumma",
                "Close" to "Sulje",
                "Cancel" to "Peruuta",
                "Refresh" to "Päivitä",
                "Create New Workplace" to "Luo uusi työpaikka",
                "Delete workplace" to "Poista työpaikka",
                "Workplaces" to "Työpaikat",
                "Warnings" to "Varoitukset",
                "Current Risk" to "Nykyinen riski",
                "Peak UV" to "Korkein UV",
                "Today" to "Tänään"
            ),
            ResolvedLanguage.FR to mapOf(
                "Settings" to "Paramètres",
                "Language" to "Langue",
                "Appearance" to "Apparence",
                "Info & Legal" to "Infos et mentions légales",
                "Development" to "Développement",
                "System" to "Système",
                "Light" to "Clair",
                "Dark" to "Sombre",
                "Close" to "Fermer",
                "Cancel" to "Annuler",
                "Refresh" to "Actualiser",
                "Create New Workplace" to "Créer un nouveau lieu de travail",
                "Delete workplace" to "Supprimer le lieu de travail",
                "Workplaces" to "Lieux de travail",
                "Warnings" to "Avertissements",
                "Current Risk" to "Risque actuel",
                "Peak UV" to "Pic UV",
                "Today" to "Aujourd'hui"
            ),
            ResolvedLanguage.EL to mapOf(
                "Settings" to "Ρυθμίσεις",
                "Language" to "Γλώσσα",
                "Appearance" to "Εμφάνιση",
                "Info & Legal" to "Πληροφορίες και νομικά",
                "Development" to "Ανάπτυξη",
                "System" to "Σύστημα",
                "Light" to "Φωτεινό",
                "Dark" to "Σκούρο",
                "Close" to "Κλείσιμο",
                "Cancel" to "Ακύρωση",
                "Refresh" to "Ανανέωση",
                "Create New Workplace" to "Δημιουργία νέου χώρου εργασίας",
                "Delete workplace" to "Διαγραφή χώρου εργασίας",
                "Workplaces" to "Χώροι εργασίας",
                "Warnings" to "Προειδοποιήσεις",
                "Current Risk" to "Τρέχων κίνδυνος",
                "Peak UV" to "Μέγιστο UV",
                "Today" to "Σήμερα"
            ),
            ResolvedLanguage.GA to mapOf("Language" to "Teanga", "Settings" to "Socruithe"),
            ResolvedLanguage.IT to mapOf(
                "Settings" to "Impostazioni",
                "Language" to "Lingua",
                "Appearance" to "Aspetto",
                "Info & Legal" to "Info e note legali",
                "Development" to "Sviluppo",
                "System" to "Sistema",
                "Light" to "Chiaro",
                "Dark" to "Scuro",
                "Close" to "Chiudi",
                "Cancel" to "Annulla",
                "Refresh" to "Aggiorna",
                "Create New Workplace" to "Crea nuovo luogo di lavoro",
                "Delete workplace" to "Elimina luogo di lavoro",
                "Workplaces" to "Luoghi di lavoro",
                "Warnings" to "Avvisi",
                "Current Risk" to "Rischio attuale",
                "Peak UV" to "Picco UV",
                "Today" to "Oggi"
            ),
            ResolvedLanguage.HR to mapOf("Language" to "Jezik", "Settings" to "Postavke"),
            ResolvedLanguage.LV to mapOf("Language" to "Valoda", "Settings" to "Iestatījumi"),
            ResolvedLanguage.LT to mapOf("Language" to "Kalba", "Settings" to "Nustatymai"),
            ResolvedLanguage.MT to mapOf("Language" to "Lingwa", "Settings" to "Settings"),
            ResolvedLanguage.NL to mapOf(
                "Settings" to "Instellingen",
                "Language" to "Taal",
                "Appearance" to "Weergave",
                "Info & Legal" to "Info en juridisch",
                "Development" to "Ontwikkeling",
                "System" to "Systeem",
                "Light" to "Licht",
                "Dark" to "Donker",
                "Close" to "Sluiten",
                "Cancel" to "Annuleren",
                "Refresh" to "Vernieuwen",
                "Create New Workplace" to "Nieuwe werkplek aanmaken",
                "Delete workplace" to "Werkplek verwijderen",
                "Workplaces" to "Werkplekken",
                "Warnings" to "Waarschuwingen",
                "Current Risk" to "Huidig risico",
                "Peak UV" to "Piek UV",
                "Today" to "Vandaag"
            ),
            ResolvedLanguage.PL to mapOf("Language" to "Język", "Settings" to "Ustawienia"),
            ResolvedLanguage.PT to mapOf("Language" to "Idioma", "Settings" to "Definições"),
            ResolvedLanguage.RO to mapOf("Language" to "Limbă", "Settings" to "Setări"),
            ResolvedLanguage.SV to mapOf(
                "Settings" to "Inställningar",
                "Language" to "Språk",
                "Appearance" to "Utseende",
                "Info & Legal" to "Info och juridik",
                "Development" to "Utveckling",
                "System" to "System",
                "Light" to "Ljust",
                "Dark" to "Mörkt",
                "Close" to "Stäng",
                "Cancel" to "Avbryt",
                "Refresh" to "Uppdatera",
                "Create New Workplace" to "Skapa ny arbetsplats",
                "Delete workplace" to "Ta bort arbetsplats",
                "Workplaces" to "Arbetsplatser",
                "Warnings" to "Varningar",
                "Current Risk" to "Aktuell risk",
                "Peak UV" to "Högsta UV",
                "Today" to "I dag"
            ),
            ResolvedLanguage.SK to mapOf("Language" to "Jazyk", "Settings" to "Nastavenia"),
            ResolvedLanguage.SL to mapOf("Language" to "Jezik", "Settings" to "Nastavitve"),
            ResolvedLanguage.ES to mapOf(
                "Settings" to "Ajustes",
                "Language" to "Idioma",
                "Appearance" to "Apariencia",
                "Info & Legal" to "Información y legal",
                "Development" to "Desarrollo",
                "System" to "Sistema",
                "Light" to "Claro",
                "Dark" to "Oscuro",
                "Close" to "Cerrar",
                "Cancel" to "Cancelar",
                "Refresh" to "Actualizar",
                "Create New Workplace" to "Crear nuevo lugar de trabajo",
                "Delete workplace" to "Eliminar lugar de trabajo",
                "Workplaces" to "Lugares de trabajo",
                "Warnings" to "Advertencias",
                "Current Risk" to "Riesgo actual",
                "Peak UV" to "Pico UV",
                "Today" to "Hoy"
            ),
            ResolvedLanguage.CS to mapOf("Language" to "Jazyk", "Settings" to "Nastavení"),
            ResolvedLanguage.HU to mapOf("Language" to "Nyelv", "Settings" to "Beállítások"),
            ResolvedLanguage.TR to mapOf(
                "Settings" to "Ayarlar",
                "Language" to "Dil",
                "Appearance" to "Görünüm",
                "Info & Legal" to "Bilgi ve yasal",
                "Development" to "Geliştirme",
                "System" to "Sistem",
                "Light" to "Açık",
                "Dark" to "Koyu",
                "Close" to "Kapat",
                "Cancel" to "İptal",
                "Refresh" to "Yenile",
                "Create New Workplace" to "Yeni iş yeri oluştur",
                "Delete workplace" to "İş yerini sil",
                "Workplaces" to "İş yerleri",
                "Warnings" to "Uyarılar",
                "Current Risk" to "Mevcut risk",
                "Peak UV" to "En yüksek UV",
                "Today" to "Bugün"
            )
        )

        private val LONG_TEXT_TRANSLATIONS: Map<ResolvedLanguage, Map<String, String>> = mapOf(
            ResolvedLanguage.BG to mapOf(
                "We help you comply with legal requirements regarding hazards from heat and natural UV radiation for outdoor work. Keep an eye on temperatures and UV index at all times." to "Помагаме ви да спазвате законовите изисквания за рисковете от жега и естествено UV лъчение при работа на открито. Следете постоянно температурите и UV индекса.",
                "So that we can warn you in time about dangerous heat levels at your workplaces, we need your permission for push notifications. Please allow them in the next step." to "За да ви предупреждаваме навреме за опасни нива на жега на работните ви места, ни е нужно разрешение за push известия. Моля, разрешете ги в следващата стъпка.",
                "The highest UV index of the day determines UV exposure. In Austria, from April to September, a UV index >= 5 is usually expected between 11:00 and 15:00." to "Най-високият UV индекс за деня определя UV натоварването. В Австрия от април до септември между 11:00 и 15:00 обикновено се очаква UV индекс >= 5."
            ),
            ResolvedLanguage.DA to mapOf(
                "We help you comply with legal requirements regarding hazards from heat and natural UV radiation for outdoor work. Keep an eye on temperatures and UV index at all times." to "Vi hjælper dig med at overholde lovkrav om farer fra varme og naturlig UV-stråling ved udendørs arbejde. Hold altid øje med temperaturer og UV-indeks.",
                "So that we can warn you in time about dangerous heat levels at your workplaces, we need your permission for push notifications. Please allow them in the next step." to "For at vi kan advare dig i tide om farlige varmeniveauer på dine arbejdspladser, har vi brug for din tilladelse til push-notifikationer. Tillad dem i næste trin.",
                "The highest UV index of the day determines UV exposure. In Austria, from April to September, a UV index >= 5 is usually expected between 11:00 and 15:00." to "Dagens højeste UV-indeks bestemmer UV-belastningen. I Østrig forventes der fra april til september normalt et UV-indeks >= 5 mellem kl. 11:00 og 15:00."
            ),
            ResolvedLanguage.ET to mapOf(
                "We help you comply with legal requirements regarding hazards from heat and natural UV radiation for outdoor work. Keep an eye on temperatures and UV index at all times." to "Aitame sul täita õigusnõudeid, mis puudutavad kuumuse ja loodusliku UV-kiirguse ohte välitöödel. Hoia temperatuuridel ja UV-indeksil alati silm peal.",
                "So that we can warn you in time about dangerous heat levels at your workplaces, we need your permission for push notifications. Please allow them in the next step." to "Et saaksime sind töökohtade ohtlikest kuumatasemetest õigel ajal hoiatada, vajame push-teavituste luba. Luba need järgmises sammus.",
                "The highest UV index of the day determines UV exposure. In Austria, from April to September, a UV index >= 5 is usually expected between 11:00 and 15:00." to "Päeva kõrgeim UV-indeks määrab UV-koormuse. Austrias on aprillist septembrini ajavahemikus 11:00–15:00 tavaliselt oodata UV-indeksit >= 5."
            ),
            ResolvedLanguage.FI to mapOf(
                "We help you comply with legal requirements regarding hazards from heat and natural UV radiation for outdoor work. Keep an eye on temperatures and UV index at all times." to "Autamme sinua noudattamaan lakisääteisiä vaatimuksia, jotka koskevat kuumuuden ja luonnollisen UV-säteilyn riskejä ulkotyössä. Seuraa lämpötiloja ja UV-indeksiä jatkuvasti.",
                "So that we can warn you in time about dangerous heat levels at your workplaces, we need your permission for push notifications. Please allow them in the next step." to "Jotta voimme varoittaa sinua ajoissa vaarallisista kuumuustasoista työpaikoillasi, tarvitsemme luvan push-ilmoituksiin. Salli ne seuraavassa vaiheessa.",
                "The highest UV index of the day determines UV exposure. In Austria, from April to September, a UV index >= 5 is usually expected between 11:00 and 15:00." to "Päivän korkein UV-indeksi määrittää UV-altistuksen. Itävallassa huhti-syyskuussa UV-indeksi >= 5 on yleensä odotettavissa klo 11:00–15:00."
            ),
            ResolvedLanguage.FR to mapOf(
                "We help you comply with legal requirements regarding hazards from heat and natural UV radiation for outdoor work. Keep an eye on temperatures and UV index at all times." to "Nous vous aidons à respecter les exigences légales liées aux risques de chaleur et de rayonnement UV naturel lors du travail en extérieur. Gardez toujours un œil sur les températures et l'indice UV.",
                "So that we can warn you in time about dangerous heat levels at your workplaces, we need your permission for push notifications. Please allow them in the next step." to "Afin de vous avertir à temps des niveaux de chaleur dangereux sur vos lieux de travail, nous avons besoin de votre autorisation pour les notifications push. Veuillez les autoriser à l'étape suivante.",
                "The highest UV index of the day determines UV exposure. In Austria, from April to September, a UV index >= 5 is usually expected between 11:00 and 15:00." to "L'indice UV maximal de la journée détermine l'exposition aux UV. En Autriche, d'avril à septembre, un indice UV >= 5 est généralement attendu entre 11h00 et 15h00."
            ),
            ResolvedLanguage.EL to mapOf(
                "We help you comply with legal requirements regarding hazards from heat and natural UV radiation for outdoor work. Keep an eye on temperatures and UV index at all times." to "Σας βοηθάμε να συμμορφώνεστε με τις νομικές απαιτήσεις σχετικά με τους κινδύνους από τη ζέστη και τη φυσική υπεριώδη ακτινοβολία στην υπαίθρια εργασία. Παρακολουθείτε πάντα τη θερμοκρασία και τον δείκτη UV.",
                "So that we can warn you in time about dangerous heat levels at your workplaces, we need your permission for push notifications. Please allow them in the next step." to "Για να σας προειδοποιούμε έγκαιρα για επικίνδυνα επίπεδα ζέστης στους χώρους εργασίας σας, χρειαζόμαστε την άδειά σας για push ειδοποιήσεις. Επιτρέψτε τις στο επόμενο βήμα.",
                "The highest UV index of the day determines UV exposure. In Austria, from April to September, a UV index >= 5 is usually expected between 11:00 and 15:00." to "Ο υψηλότερος δείκτης UV της ημέρας καθορίζει την έκθεση στην υπεριώδη ακτινοβολία. Στην Αυστρία, από Απρίλιο έως Σεπτέμβριο, αναμένεται συνήθως δείκτης UV >= 5 μεταξύ 11:00 και 15:00."
            ),
            ResolvedLanguage.GA to mapOf(
                "We help you comply with legal requirements regarding hazards from heat and natural UV radiation for outdoor work. Keep an eye on temperatures and UV index at all times." to "Cabhraímid leat riachtanais dhlíthiúla maidir le rioscaí ó theas agus radaíocht UV nádúrtha in obair lasmuigh a chomhlíonadh. Coinnigh súil ar theocht agus ar an innéacs UV i gcónaí.",
                "So that we can warn you in time about dangerous heat levels at your workplaces, we need your permission for push notifications. Please allow them in the next step." to "Chun rabhadh tráthúil a thabhairt duit faoi leibhéil dainséaracha teasa ag d'ionaid oibre, teastaíonn cead uainn le haghaidh fógraí brú. Ceadaigh iad sa chéad chéim eile.",
                "The highest UV index of the day determines UV exposure. In Austria, from April to September, a UV index >= 5 is usually expected between 11:00 and 15:00." to "Cinneann an t-innéacs UV is airde den lá an nochtadh UV. San Ostair, ó Aibreán go Meán Fómhair, bíonn innéacs UV >= 5 le súil de ghnáth idir 11:00 agus 15:00."
            ),
            ResolvedLanguage.IT to mapOf(
                "We help you comply with legal requirements regarding hazards from heat and natural UV radiation for outdoor work. Keep an eye on temperatures and UV index at all times." to "Ti aiutiamo a rispettare i requisiti legali relativi ai rischi da calore e radiazione UV naturale per il lavoro all'aperto. Tieni sempre sotto controllo temperature e indice UV.",
                "So that we can warn you in time about dangerous heat levels at your workplaces, we need your permission for push notifications. Please allow them in the next step." to "Per avvisarti in tempo sui livelli di calore pericolosi nei tuoi luoghi di lavoro, abbiamo bisogno della tua autorizzazione per le notifiche push. Consentile nel passaggio successivo.",
                "The highest UV index of the day determines UV exposure. In Austria, from April to September, a UV index >= 5 is usually expected between 11:00 and 15:00." to "L'indice UV massimo della giornata determina l'esposizione ai raggi UV. In Austria, da aprile a settembre, tra le 11:00 e le 15:00 è generalmente previsto un indice UV >= 5."
            ),
            ResolvedLanguage.HR to mapOf(
                "We help you comply with legal requirements regarding hazards from heat and natural UV radiation for outdoor work. Keep an eye on temperatures and UV index at all times." to "Pomažemo vam uskladiti se sa zakonskim zahtjevima vezanim uz opasnosti od vrućine i prirodnog UV zračenja pri radu na otvorenom. Uvijek pratite temperaturu i UV indeks.",
                "So that we can warn you in time about dangerous heat levels at your workplaces, we need your permission for push notifications. Please allow them in the next step." to "Kako bismo vas na vrijeme upozorili na opasne razine vrućine na vašim radnim mjestima, trebamo vaše dopuštenje za push obavijesti. Molimo omogućite ih u sljedećem koraku.",
                "The highest UV index of the day determines UV exposure. In Austria, from April to September, a UV index >= 5 is usually expected between 11:00 and 15:00." to "Najviši dnevni UV indeks određuje izloženost UV zračenju. U Austriji se od travnja do rujna između 11:00 i 15:00 obično očekuje UV indeks >= 5."
            ),
            ResolvedLanguage.LV to mapOf(
                "We help you comply with legal requirements regarding hazards from heat and natural UV radiation for outdoor work. Keep an eye on temperatures and UV index at all times." to "Mēs palīdzam ievērot juridiskās prasības attiecībā uz karstuma un dabiskā UV starojuma riskiem āra darbā. Vienmēr sekojiet temperatūrai un UV indeksam.",
                "So that we can warn you in time about dangerous heat levels at your workplaces, we need your permission for push notifications. Please allow them in the next step." to "Lai mēs varētu savlaicīgi brīdināt par bīstamu karstuma līmeni jūsu darba vietās, mums nepieciešama atļauja push paziņojumiem. Lūdzu, atļaujiet tos nākamajā solī.",
                "The highest UV index of the day determines UV exposure. In Austria, from April to September, a UV index >= 5 is usually expected between 11:00 and 15:00." to "Dienas augstākais UV indekss nosaka UV slodzi. Austrijā no aprīļa līdz septembrim laikā no 11:00 līdz 15:00 parasti gaidāms UV indekss >= 5."
            ),
            ResolvedLanguage.LT to mapOf(
                "We help you comply with legal requirements regarding hazards from heat and natural UV radiation for outdoor work. Keep an eye on temperatures and UV index at all times." to "Padedame laikytis teisinių reikalavimų dėl karščio ir natūralios UV spinduliuotės pavojų dirbant lauke. Visada stebėkite temperatūrą ir UV indeksą.",
                "So that we can warn you in time about dangerous heat levels at your workplaces, we need your permission for push notifications. Please allow them in the next step." to "Kad galėtume laiku įspėti apie pavojingą karščio lygį jūsų darbo vietose, mums reikia leidimo siųsti push pranešimus. Prašome juos leisti kitame žingsnyje.",
                "The highest UV index of the day determines UV exposure. In Austria, from April to September, a UV index >= 5 is usually expected between 11:00 and 15:00." to "Didžiausias dienos UV indeksas lemia UV poveikį. Austrijoje nuo balandžio iki rugsėjo tarp 11:00 ir 15:00 paprastai tikimasi UV indekso >= 5."
            ),
            ResolvedLanguage.MT to mapOf(
                "We help you comply with legal requirements regarding hazards from heat and natural UV radiation for outdoor work. Keep an eye on temperatures and UV index at all times." to "Ngħinuk tikkonforma mar-rekwiżiti legali dwar ir-riskji mis-sħana u r-radjazzjoni UV naturali fix-xogħol barra. Żomm għajnejk fuq it-temperaturi u l-indiċi UV il-ħin kollu.",
                "So that we can warn you in time about dangerous heat levels at your workplaces, we need your permission for push notifications. Please allow them in the next step." to "Biex inwissuk fil-ħin dwar livelli perikolużi ta' sħana fil-postijiet tax-xogħol tiegħek, għandna bżonn il-permess tiegħek għan-notifiki push. Jekk jogħġbok ippermettilhom fil-pass li jmiss.",
                "The highest UV index of the day determines UV exposure. In Austria, from April to September, a UV index >= 5 is usually expected between 11:00 and 15:00." to "L-ogħla indiċi UV tal-jum jiddetermina l-espożizzjoni UV. Fl-Awstrija, minn April sa Settembru, normalment ikun mistenni indiċi UV >= 5 bejn 11:00 u 15:00."
            ),
            ResolvedLanguage.NL to mapOf(
                "We help you comply with legal requirements regarding hazards from heat and natural UV radiation for outdoor work. Keep an eye on temperatures and UV index at all times." to "We helpen je te voldoen aan wettelijke eisen rond risico's door hitte en natuurlijke UV-straling bij buitenwerk. Houd temperaturen en UV-index altijd in de gaten.",
                "So that we can warn you in time about dangerous heat levels at your workplaces, we need your permission for push notifications. Please allow them in the next step." to "Om je op tijd te waarschuwen voor gevaarlijke hitteniveaus op je werkplekken, hebben we toestemming nodig voor pushmeldingen. Sta die toe in de volgende stap.",
                "The highest UV index of the day determines UV exposure. In Austria, from April to September, a UV index >= 5 is usually expected between 11:00 and 15:00." to "De hoogste UV-index van de dag bepaalt de UV-belasting. In Oostenrijk wordt van april tot september tussen 11:00 en 15:00 meestal een UV-index >= 5 verwacht."
            ),
            ResolvedLanguage.PL to mapOf(
                "We help you comply with legal requirements regarding hazards from heat and natural UV radiation for outdoor work. Keep an eye on temperatures and UV index at all times." to "Pomagamy spełniać wymogi prawne dotyczące zagrożeń związanych z upałem i naturalnym promieniowaniem UV przy pracy na zewnątrz. Zawsze monitoruj temperaturę i indeks UV.",
                "So that we can warn you in time about dangerous heat levels at your workplaces, we need your permission for push notifications. Please allow them in the next step." to "Abyśmy mogli na czas ostrzegać o niebezpiecznych poziomach upału w Twoich miejscach pracy, potrzebujemy zgody na powiadomienia push. Włącz je w następnym kroku.",
                "The highest UV index of the day determines UV exposure. In Austria, from April to September, a UV index >= 5 is usually expected between 11:00 and 15:00." to "Najwyższy dzienny indeks UV określa ekspozycję na UV. W Austrii od kwietnia do września między 11:00 a 15:00 zwykle oczekuje się indeksu UV >= 5."
            ),
            ResolvedLanguage.PT to mapOf(
                "We help you comply with legal requirements regarding hazards from heat and natural UV radiation for outdoor work. Keep an eye on temperatures and UV index at all times." to "Ajudamos a cumprir os requisitos legais relativos aos perigos do calor e da radiação UV natural no trabalho ao ar livre. Acompanhe sempre as temperaturas e o índice UV.",
                "So that we can warn you in time about dangerous heat levels at your workplaces, we need your permission for push notifications. Please allow them in the next step." to "Para o avisarmos a tempo sobre níveis perigosos de calor nos seus locais de trabalho, precisamos da sua permissão para notificações push. Permita-as no próximo passo.",
                "The highest UV index of the day determines UV exposure. In Austria, from April to September, a UV index >= 5 is usually expected between 11:00 and 15:00." to "O índice UV mais elevado do dia determina a exposição UV. Na Áustria, de abril a setembro, normalmente espera-se um índice UV >= 5 entre as 11:00 e as 15:00."
            ),
            ResolvedLanguage.RO to mapOf(
                "We help you comply with legal requirements regarding hazards from heat and natural UV radiation for outdoor work. Keep an eye on temperatures and UV index at all times." to "Te ajutăm să respecți cerințele legale privind riscurile de căldură și radiație UV naturală la munca în aer liber. Urmărește permanent temperaturile și indicele UV.",
                "So that we can warn you in time about dangerous heat levels at your workplaces, we need your permission for push notifications. Please allow them in the next step." to "Pentru a te avertiza la timp despre niveluri periculoase de căldură la locurile tale de muncă, avem nevoie de permisiunea pentru notificări push. Te rugăm să le permiți la pasul următor.",
                "The highest UV index of the day determines UV exposure. In Austria, from April to September, a UV index >= 5 is usually expected between 11:00 and 15:00." to "Cel mai mare indice UV al zilei determină expunerea la UV. În Austria, din aprilie până în septembrie, între 11:00 și 15:00 se așteaptă de obicei un indice UV >= 5."
            ),
            ResolvedLanguage.SV to mapOf(
                "We help you comply with legal requirements regarding hazards from heat and natural UV radiation for outdoor work. Keep an eye on temperatures and UV index at all times." to "Vi hjälper dig att uppfylla lagkrav kring risker från värme och naturlig UV-strålning vid utomhusarbete. Håll alltid koll på temperaturer och UV-index.",
                "So that we can warn you in time about dangerous heat levels at your workplaces, we need your permission for push notifications. Please allow them in the next step." to "För att vi ska kunna varna dig i tid om farliga värmenivåer på dina arbetsplatser behöver vi ditt tillstånd för pushnotiser. Tillåt dem i nästa steg.",
                "The highest UV index of the day determines UV exposure. In Austria, from April to September, a UV index >= 5 is usually expected between 11:00 and 15:00." to "Dagens högsta UV-index bestämmer UV-belastningen. I Österrike förväntas från april till september vanligtvis ett UV-index >= 5 mellan 11:00 och 15:00."
            ),
            ResolvedLanguage.SK to mapOf(
                "We help you comply with legal requirements regarding hazards from heat and natural UV radiation for outdoor work. Keep an eye on temperatures and UV index at all times." to "Pomáhame vám dodržiavať zákonné požiadavky týkajúce sa rizík z tepla a prirodzeného UV žiarenia pri práci vonku. Neustále sledujte teploty a UV index.",
                "So that we can warn you in time about dangerous heat levels at your workplaces, we need your permission for push notifications. Please allow them in the next step." to "Aby sme vás mohli včas upozorniť na nebezpečné úrovne tepla na vašich pracoviskách, potrebujeme váš súhlas s push notifikáciami. Povoľte ich v ďalšom kroku.",
                "The highest UV index of the day determines UV exposure. In Austria, from April to September, a UV index >= 5 is usually expected between 11:00 and 15:00." to "Najvyšší UV index dňa určuje UV záťaž. V Rakúsku sa od apríla do septembra medzi 11:00 a 15:00 zvyčajne očakáva UV index >= 5."
            ),
            ResolvedLanguage.SL to mapOf(
                "We help you comply with legal requirements regarding hazards from heat and natural UV radiation for outdoor work. Keep an eye on temperatures and UV index at all times." to "Pomagamo vam izpolnjevati zakonske zahteve glede nevarnosti vročine in naravnega UV sevanja pri delu na prostem. Vedno spremljajte temperature in UV indeks.",
                "So that we can warn you in time about dangerous heat levels at your workplaces, we need your permission for push notifications. Please allow them in the next step." to "Da vas lahko pravočasno opozorimo na nevarne ravni vročine na vaših delovnih mestih, potrebujemo vaše dovoljenje za push obvestila. Omogočite jih v naslednjem koraku.",
                "The highest UV index of the day determines UV exposure. In Austria, from April to September, a UV index >= 5 is usually expected between 11:00 and 15:00." to "Najvišji dnevni UV indeks določa UV obremenitev. V Avstriji je od aprila do septembra med 11:00 in 15:00 običajno pričakovan UV indeks >= 5."
            ),
            ResolvedLanguage.ES to mapOf(
                "We help you comply with legal requirements regarding hazards from heat and natural UV radiation for outdoor work. Keep an eye on temperatures and UV index at all times." to "Te ayudamos a cumplir los requisitos legales sobre riesgos por calor y radiación UV natural en trabajos al aire libre. Mantén siempre bajo control las temperaturas y el índice UV.",
                "So that we can warn you in time about dangerous heat levels at your workplaces, we need your permission for push notifications. Please allow them in the next step." to "Para poder avisarte a tiempo sobre niveles peligrosos de calor en tus lugares de trabajo, necesitamos tu permiso para notificaciones push. Permítelas en el siguiente paso.",
                "The highest UV index of the day determines UV exposure. In Austria, from April to September, a UV index >= 5 is usually expected between 11:00 and 15:00." to "El índice UV más alto del día determina la exposición a UV. En Austria, de abril a septiembre, normalmente se espera un índice UV >= 5 entre las 11:00 y las 15:00."
            ),
            ResolvedLanguage.CS to mapOf(
                "We help you comply with legal requirements regarding hazards from heat and natural UV radiation for outdoor work. Keep an eye on temperatures and UV index at all times." to "Pomáháme vám dodržovat zákonné požadavky týkající se rizik z horka a přirozeného UV záření při práci venku. Neustále sledujte teploty a UV index.",
                "So that we can warn you in time about dangerous heat levels at your workplaces, we need your permission for push notifications. Please allow them in the next step." to "Abychom vás mohli včas varovat před nebezpečnými úrovněmi horka na vašich pracovištích, potřebujeme vaše povolení k push oznámením. Povolte je v dalším kroku.",
                "The highest UV index of the day determines UV exposure. In Austria, from April to September, a UV index >= 5 is usually expected between 11:00 and 15:00." to "Nejvyšší denní UV index určuje UV zátěž. V Rakousku se od dubna do září mezi 11:00 a 15:00 obvykle očekává UV index >= 5."
            ),
            ResolvedLanguage.HU to mapOf(
                "We help you comply with legal requirements regarding hazards from heat and natural UV radiation for outdoor work. Keep an eye on temperatures and UV index at all times." to "Segítünk megfelelni a szabadtéri munkát érintő hő- és természetes UV-sugárzási kockázatokra vonatkozó jogi követelményeknek. Mindig figyeld a hőmérsékletet és az UV-indexet.",
                "So that we can warn you in time about dangerous heat levels at your workplaces, we need your permission for push notifications. Please allow them in the next step." to "Ahhoz, hogy időben figyelmeztethessünk a munkahelyeiden jelentkező veszélyes hőszintekre, engedélyre van szükségünk a push értesítésekhez. Kérjük, engedélyezd a következő lépésben.",
                "The highest UV index of the day determines UV exposure. In Austria, from April to September, a UV index >= 5 is usually expected between 11:00 and 15:00." to "A napi legmagasabb UV-index határozza meg az UV-terhelést. Ausztriában áprilistól szeptemberig 11:00 és 15:00 között általában >= 5 UV-index várható."
            ),
            ResolvedLanguage.TR to mapOf(
                "We help you comply with legal requirements regarding hazards from heat and natural UV radiation for outdoor work. Keep an eye on temperatures and UV index at all times." to "Açık havada çalışma sırasında ısı ve doğal UV ışınımı risklerine ilişkin yasal gerekliliklere uymanıza yardımcı oluyoruz. Sıcaklıkları ve UV indeksini her zaman takip edin.",
                "So that we can warn you in time about dangerous heat levels at your workplaces, we need your permission for push notifications. Please allow them in the next step." to "Çalışma alanlarınızdaki tehlikeli sıcaklık seviyeleri hakkında sizi zamanında uyarabilmemiz için push bildirimlerine izin vermeniz gerekir. Lütfen bir sonraki adımda izin verin.",
                "The highest UV index of the day determines UV exposure. In Austria, from April to September, a UV index >= 5 is usually expected between 11:00 and 15:00." to "Günün en yüksek UV indeksi UV maruziyetini belirler. Avusturya'da Nisan-Eylül arasında 11:00-15:00 saatleri arasında genellikle UV indeksi >= 5 beklenir."
            )
        )
    }
}
