package org.entner.HitzeV.ui.copy

import org.entner.HitzeV.model.AppLanguage
import org.entner.HitzeV.model.HazardSeverity
import org.entner.HitzeV.model.ResolvedLanguage
import java.time.DayOfWeek
import java.time.LocalDate

class Copybook(private val language: ResolvedLanguage) {
    private val isGerman: Boolean
        get() = language == ResolvedLanguage.DE

    fun t(german: String, english: String): String = if (isGerman) german else english

    val shortTitle: String = t("Hitze-V", "Heat-V")
    val dashboardTitle: String = t("Sicher durch Hitze", "Heat Safety at a Glance")
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
    val appearanceSection: String = t("Erscheinungsbild", "Appearance")
    val aboutSection: String = t("Info & Rechtliches", "Info & Legal")
    val dataSourceLine: String = t("Datenquelle: GeoSphere Austria", "Data source: GeoSphere Austria")
    val geocodingAttributionLine: String = "Geocoding data © OpenStreetMap contributors"
    val themeSystem: String = t("System", "System")
    val themeLight: String = t("Hell", "Light")
    val themeDark: String = t("Dunkel", "Dark")
    val languageSection: String = t("Sprache", "Language")
    val legalLinkURL: String = "https://www.arbeitsmediziner.wien"
    val legalLinkLabel: String = "arbeitsmediziner.wien"
    val onboardingWelcomeTitle: String = t("Willkommen bei Hitze-V", "Welcome to Hitze-V")
    val onboardingWelcomeText: String = t(
        "Wir helfen dir, die gesetzlichen Vorgaben zu Gefahren durch Hitze und natürliche UV-Strahlung bei Arbeiten im Freien einzuhalten. Behalte Temperaturen und UV-Index immer im Blick.",
        "We help you comply with legal requirements regarding hazards from heat and natural UV radiation for outdoor work. Keep an eye on temperatures and UV index at all times."
    )
    val onboardingPushTitle: String = t("Bleib informiert", "Stay informed")
    val onboardingPushText: String = t(
        "Damit wir dich bei gefährlichen Hitzewerten an deinen Arbeitsplätzen rechtzeitig warnen können, benötigen wir deine Erlaubnis für Push-Benachrichtigungen. Bitte erlaube diese im nächsten Schritt.",
        "So that we can warn you in time about dangerous heat levels at your workplaces, we need your permission for push notifications. Please allow them in the next step."
    )
    val onboardingAllowButton: String = t("Erlauben & Loslegen", "Allow & Start")
    val onboardingSkipButton: String = t("Später / Überspringen", "Later / Skip")
    val infoScreenHeatMeasuresTitle: String = t("Hitze-Schutzmaßnahmen", "Heat Protection Measures")
    val infoScreenHeatMeasuresSubtitle: String = t("Erklärung der Werte für die Stufen 2 bis 4", "Explanation of values for levels 2 to 4")
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
        AppLanguage.DE -> t("Deutsch", "German")
        AppLanguage.EN -> t("Englisch", "English")
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
}
