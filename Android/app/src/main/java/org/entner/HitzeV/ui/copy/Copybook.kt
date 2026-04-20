package org.entner.HitzeV.ui.copy

import org.entner.HitzeV.model.AppLanguage
import org.entner.HitzeV.model.HazardSeverity
import org.entner.HitzeV.model.ResolvedLanguage
import java.time.LocalDate
import java.time.format.TextStyle
import java.util.Locale

class Copybook(private val language: ResolvedLanguage) {
    data class InfoBullet(
        val text: String,
        val cta: InfoCta? = null
    )

    data class InfoGroup(
        val title: String,
        val bullets: List<InfoBullet>
    )

    data class InfoSection(
        val title: String,
        val groups: List<InfoGroup>
    )

    data class InfoCta(
        val label: String,
        val url: String
    )

    private val uiLocale: Locale = Locale.forLanguageTag(language.localeTag)

    fun t(german: String, english: String): String = when (language) {
        ResolvedLanguage.DE -> german
        ResolvedLanguage.EN -> english
        else -> requireNotNull(
            CopybookSupplementalTranslations.translation(language, english)
                ?: CopybookTranslationCatalog.translation(language, english)
        ) {
            "Missing Copybook translation for ${language.code}: $english"
        }
    }

    private fun bulletLines(german: String, english: String): List<InfoBullet> = t(german, english)
        .split('\n')
        .map { it.trim() }
        .filter { it.isNotEmpty() }
        .map { InfoBullet(text = it) }

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
    val apparentTitle: String = t("Gefühlte Temp.", "Feels Like")
    val workplaceLabel: String = t("Arbeitsplätze", "Workplaces")
    val warningsLabel: String = t("Hitzewarnungen", "Heat warnings")
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
    val refreshButton: String = t("Daten aktualisieren", "Refresh data")
    val deleteWorkplace: String = t("Arbeitsplatz löschen", "Delete workplace")
    val cancelButton: String = t("Abbrechen", "Cancel")
    val settingsCloseButton: String = t("Schließen", "Close")
    val settingsTitle: String = t("Einstellungen", "Settings")
    val infoScreenTitle: String = t("Info", "Info")
    val infoButtonLabel: String = t("Info öffnen", "Open info")
    val notAvailableShort: String = t("n/v", "n/a")
    val warningAllDay: String = t("Ganztägig", "All day")
    val heatWarningLevelLabel: String = t("Hitzewarnstufe", "Heat warning level")
    val addWorkplaceFailureTitle: String = t("Hinzufügen nicht möglich", "Unable to add")
    val addOutsideAustriaMessage: String = t(
        "Dieses Gebiet liegt vermutlich außerhalb Österreichs oder wird von GeoSphere nicht erkannt. Ein Hinzufügen ist nicht möglich.",
        "This area is likely outside Austria or not recognized by GeoSphere. Adding is not possible."
    )
    val addWorkplaceHeroBody: String = t(
        "Lege einen Namen fest und suche danach nach einer Adresse in Österreich.",
        "Set a label and then search for an address in Austria."
    )
    val optionalFieldPlaceholder: String = t("Optional", "Optional")
    val settingsHeroBody: String = t(
        "Passe Darstellung, Sprache und rechtliche Hinweise an.",
        "Adjust appearance, language, and legal details."
    )
    val uvWarningBadge5Plus: String = t("UV >= 5", "UV >= 5")
    val uvInfoDetail5Plus: String = t(
        "Ab UV-Index 5 steigt die Belastung deutlich. Schutzkleidung, Kopfbedeckung, Sonnenbrille und Sonnencreme konsequent verwenden.",
        "At UV index 5 and above, exposure increases significantly. Consistently use protective clothing, head covering, sunglasses, and sunscreen."
    )
    val uvInfoMeasures5Plus: String = t(
        "Direkte Sonne und belastende Arbeiten möglichst in den Schatten verlagern und Aufenthalte in voller Sonne begrenzen.",
        "Move direct sun exposure and strenuous work into shade whenever possible and limit time spent in full sun."
    )
    val appearanceSection: String = t("Erscheinungsbild", "Appearance")
    val pushNotificationsSection: String = t("Push-Benachrichtigungen", "Push notifications")
    val pushNotificationsDescription: String = t(
        "Lege fest, ob Hitzewarnungen per Push gesendet werden und für welche Arbeitsplätze.",
        "Choose whether heat alerts are sent as push notifications and for which worksites."
    )
    val pushNotificationsEnabledLabel: String = t(
        "Push-Benachrichtigungen aktivieren",
        "Enable push notifications"
    )
    val pushNotificationsEnabledDescription: String = t(
        "Beim Ausschalten werden alle aktuellen Push-Abos sofort entfernt.",
        "Turning this off immediately removes all current push subscriptions."
    )
    val pushWorksitesSectionTitle: String = t(
        "Arbeitsplätze für Push",
        "Worksites for push"
    )
    val pushNoWorksitesMessage: String = t(
        "Lege zuerst einen Arbeitsplatz an, um Push-Benachrichtigungen gezielt zu steuern.",
        "Add a worksite first to control push notifications individually."
    )
    val pushWorksiteFallbackSubtitle: String = t(
        "Kein Adresstext vorhanden",
        "No address available"
    )
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
    val machineTranslationDisclaimer: String = when (language) {
        ResolvedLanguage.DE -> "Texte in anderen Sprachen werden maschinell aus dem Deutschen übersetzt. Für Vollständigkeit und Korrektheit dieser Übersetzungen kann keine Gewähr übernommen werden."
        ResolvedLanguage.BG -> "Текстовете на други езици са машинно преведени от немски. Не се дава гаранция за пълнотата или точността на тези преводи."
        ResolvedLanguage.DA -> "Tekster på andre sprog er maskinoversat fra tysk. Der gives ingen garanti for disse oversættelsers fuldstændighed eller korrekthed."
        ResolvedLanguage.EN -> "Texts in other languages are machine-translated from German. No guarantee is given for the completeness or accuracy of these translations."
        ResolvedLanguage.ET -> "Teistes keeltes olevad tekstid on saksa keelest masintõlgitud. Nende tõlgete täielikkuse ega õigsuse eest ei anta garantiid."
        ResolvedLanguage.FI -> "Muiden kielten tekstit on konekäännetty saksasta. Näiden käännösten täydellisyydestä tai oikeellisuudesta ei anneta takuuta."
        ResolvedLanguage.FR -> "Les textes dans les autres langues sont traduits automatiquement à partir de l’allemand. Aucune garantie n’est donnée quant à l’exhaustivité ou à l’exactitude de ces traductions."
        ResolvedLanguage.EL -> "Τα κείμενα σε άλλες γλώσσες έχουν μεταφραστεί αυτόματα από τα γερμανικά. Δεν παρέχεται καμία εγγύηση για την πληρότητα ή την ακρίβεια αυτών των μεταφράσεων."
        ResolvedLanguage.GA -> "Tá na téacsanna i dteangacha eile aistrithe go huathoibríoch ón nGearmáinis. Ní thugtar aon ráthaíocht maidir le hiomláine ná cruinneas na n-aistriúchán seo."
        ResolvedLanguage.IT -> "I testi nelle altre lingue sono tradotti automaticamente dal tedesco. Non viene fornita alcuna garanzia circa la completezza o la correttezza di queste traduzioni."
        ResolvedLanguage.HR -> "Tekstovi na drugim jezicima strojno su prevedeni s njemačkog. Ne daje se nikakvo jamstvo za potpunost ili točnost tih prijevoda."
        ResolvedLanguage.LV -> "Teksti citās valodās ir mašīntulkoti no vācu valodas. Netiek sniegta nekāda garantija par šo tulkojumu pilnīgumu vai pareizību."
        ResolvedLanguage.LT -> "Tekstai kitomis kalbomis yra automatiškai išversti iš vokiečių kalbos. Nėra teikiama jokia garantija dėl šių vertimų išsamumo ar tikslumo."
        ResolvedLanguage.MT -> "It-testi b'lingwi oħra huma tradotti b'mod awtomatiku mill-Ġermaniż. Ma tingħata ebda garanzija dwar il-kompletezza jew il-korrettezza ta' dawn it-traduzzjonijiet."
        ResolvedLanguage.NL -> "Teksten in andere talen zijn machinaal vertaald vanuit het Duits. Voor de volledigheid of juistheid van deze vertalingen wordt geen garantie gegeven."
        ResolvedLanguage.PL -> "Teksty w innych językach są tłumaczone maszynowo z języka niemieckiego. Nie udziela się żadnej gwarancji co do kompletności ani poprawności tych tłumaczeń."
        ResolvedLanguage.PT -> "Os textos noutros idiomas são traduzidos automaticamente do alemão. Não é dada qualquer garantia quanto à integralidade ou correção dessas traduções."
        ResolvedLanguage.RO -> "Textele în alte limbi sunt traduse automat din germană. Nu se oferă nicio garanție privind caracterul complet sau corectitudinea acestor traduceri."
        ResolvedLanguage.SV -> "Texter på andra språk är maskinöversatta från tyska. Ingen garanti lämnas för att dessa översättningar är fullständiga eller korrekta."
        ResolvedLanguage.SK -> "Texty v iných jazykoch sú strojovo preložené z nemčiny. Za úplnosť ani správnosť týchto prekladov sa neposkytuje žiadna záruka."
        ResolvedLanguage.SL -> "Besedila v drugih jezikih so strojno prevedena iz nemščine. Za popolnost ali pravilnost teh prevodov ni mogoče jamčiti."
        ResolvedLanguage.ES -> "Los textos en otros idiomas están traducidos automáticamente del alemán. No se ofrece ninguna garantía sobre la integridad o la exactitud de estas traducciones."
        ResolvedLanguage.CS -> "Texty v jiných jazycích jsou strojově přeloženy z němčiny. Za úplnost ani správnost těchto překladů se neposkytuje žádná záruka."
        ResolvedLanguage.HU -> "A más nyelveken megjelenő szövegek németből gépi fordítással készültek. E fordítások teljességéért vagy helyességéért nem vállalunk garanciát."
        ResolvedLanguage.TR -> "Diğer dillerdeki metinler Almancadan makine çevirisiyle çevrilmiştir. Bu çevirilerin eksiksizliği veya doğruluğu konusunda herhangi bir garanti verilmez."
    }
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
    val infoScreenHeatScaleTitle: String = t("Skala der Hitzewarnstufen", "Heat warning scale")
    val infoScreenUvMeasuresTitle: String = t("UV-Schutzmaßnahmen", "UV Protection Measures")
    val infoScreenUvLevel5Title: String = t("UV-Index >= 5", "UV Index >= 5")
    val infoScreenLevel2Title: String = t("2 (gefühlte Temperatur ≥ 30 °C)", "2 (apparent temperature ≥ 30 °C)")
    val infoScreenLevel3Title: String = t("3 (gefühlte Temperatur ≥ 35 °C)", "3 (apparent temperature ≥ 35 °C)")
    val infoScreenLevel4Title: String = t("4 (gefühlte Temperatur ≥ 40 °C)", "4 (apparent temperature ≥ 40 °C)")
    val emergencyCallCta: InfoCta = InfoCta(
        label = t("Jetzt 144 anrufen", "Call 144 now"),
        url = "tel:144"
    )
    val infoIntro: String = t(
        "Ab einer Hitzewarnung der Stufe 2 (ab 30 °C) müssen ein Maßnahmenprogramm und Notfallmaßnahmen umgesetzt werden. Mögliche Maßnahmen sind z.B.",
        "Starting at heat warning level 2 (from 30 °C), a response plan and emergency measures must be implemented. Possible measures include:"
    )
    val heatProgramSection: InfoSection = InfoSection(
        title = t("Maßnahmenprogramm (STOP-Prinzip)", "Response plan (STOP principle)"),
        groups = listOf(
            InfoGroup(
                title = t("Technische Maßnahmen", "Technical measures"),
                bullets = bulletLines(
                    """
                    Beschattung von Arbeits- und Pausenplätzen mit Sonnenschirmen, Pavillons etc.
                    Technische Kühlmaßnahmen wie z.B. Ventilatoren
                    Reduzierung körperlich anstrengender Arbeiten z. B. durch Hebehilfen
                    """.trimIndent(),
                    """
                    Shade work and rest areas with parasols, pavilions, etc.
                    Technical cooling measures such as fans
                    Reduce physically strenuous work, e.g. by using lifting aids
                    """.trimIndent()
                )
            ),
            InfoGroup(
                title = t("Organisatorische Maßnahmen", "Organizational measures"),
                bullets = bulletLines(
                    """
                    Verlagerung von schweren Arbeiten in kühlere Tageszeiten
                    Pausen zum Abkühlen
                    Schwere Tätigkeiten im Schatten/Kühlen verrichten
                    """.trimIndent(),
                    """
                    Shift heavy work to cooler times of day
                    Take breaks to cool down
                    Carry out heavy tasks in shade or cool areas
                    """.trimIndent()
                )
            ),
            InfoGroup(
                title = t("Persönliche Schutzmaßnahmen", "Personal protective measures"),
                bullets = bulletLines(
                    """
                    Ausreichend Trinkwasser bereitstellen
                    Leichte Arbeitskleidung mit UV-Schutz und Sonnenschutzmittel (LSF von 50 empfohlen), UV-Schutzbrille, Kühltücher
                    Je nach Einsatzgebiet: Schutzhelm mit Nackenschutz
                    """.trimIndent(),
                    """
                    Provide sufficient drinking water
                    Light work clothing with UV protection and sunscreen (SPF 50 recommended), UV-protective glasses, cooling towels
                    Depending on the work area: safety helmet with neck protection
                    """.trimIndent()
                )
            )
        )
    )
    val heatEmergencySection: InfoSection = InfoSection(
        title = t("Notfallmaßnahmen", "Emergency measures"),
        groups = listOf(
            InfoGroup(
                title = t("Hitzebedingte Symptome können sein", "Heat-related symptoms can include"),
                bullets = bulletLines(
                    """
                    Kopfschmerzen, Schwindel, Übelkeit
                    Schwäche, Krämpfe, Verwirrtheit
                    Heiße, trockene oder stark schwitzende Haut
                    Bewusstseinsstörungen
                    """.trimIndent(),
                    """
                    Headaches, dizziness, nausea
                    Weakness, cramps, confusion
                    Hot, dry skin or very sweaty skin
                    Impaired consciousness
                    """.trimIndent()
                )
            ),
            InfoGroup(
                title = t("Mögliche Notfallmaßnahmen", "Possible emergency measures"),
                bullets = listOf(
                    InfoBullet(
                        text = t(
                            "Arbeit unterbrechen und Betroffene in den Schatten/ins Kühle bringen",
                            "Stop work and move the affected person to shade or a cool place"
                        )
                    ),
                    InfoBullet(
                        text = t(
                            "Kühlung des Körpers z.B. durch feuchte Tücher oder Ventilation",
                            "Cool the body, e.g. with damp cloths or ventilation"
                        )
                    ),
                    InfoBullet(
                        text = t("Kleidung lockern", "Loosen clothing")
                    ),
                    InfoBullet(
                        text = t(
                            "Langsam trinken lassen (Wasser, Tee, Elektrolytlösungen)",
                            "Let the person drink slowly (water, tea, electrolyte solutions)"
                        )
                    ),
                    InfoBullet(
                        text = t(
                            "Bei Bewusstlosigkeit in stabile Seitenlage bringen",
                            "If unconscious, place the person in the recovery position"
                        )
                    ),
                    InfoBullet(
                        text = t(
                            "Notruf (144) wählen, wenn Zustand nicht bald besser oder Anzeichen von Bewusstlosigkeit",
                            "Call emergency services (144) if the condition does not improve soon or there are signs of loss of consciousness"
                        )
                    ),
                    InfoBullet(
                        text = t(
                            "Bis zum Eintreffen der Rettung Bewusstsein und Atmung kontrollieren",
                            "Monitor consciousness and breathing until emergency services arrive"
                        )
                    ),
                    InfoBullet(
                        text = t(
                            "Ist keine normale Atmung vorhanden, sofort Wiederbelebungsmaßnahmen einleiten – Hilfe holen!",
                            "If there is no normal breathing, start CPR immediately and get help"
                        ),
                        cta = emergencyCallCta
                    )
                )
            )
        )
    )
    val optionalChecklistCta: InfoCta? = INFO_CHECKLIST_URL?.let { url ->
        InfoCta(
            label = t(
                "Hier geht’s zur Hitzeschutzcheckliste für Betriebe",
                "Heat protection checklist for businesses"
            ),
            url = url
        )
    }
    val uvSection: InfoSection = InfoSection(
        title = infoScreenUvMeasuresTitle,
        groups = listOf(
            InfoGroup(
                title = infoScreenUvLevel5Title,
                bullets = listOf(
                    InfoBullet(text = uvInfoDetail5Plus),
                    InfoBullet(text = uvInfoMeasures5Plus)
                )
            )
        )
    )
    val enterAddressMessage: String = t("Bitte eine Adresse eingeben.", "Please enter an address.")
    val noAddressFoundMessage: String = t("Keine passende Adresse gefunden.", "No matching address found.")
    val addressSearchFailedMessage: String = t("Adresssuche fehlgeschlagen. Bitte erneut versuchen.", "Address search failed. Please try again.")
    val liveDataUnavailableMessage: String = t(
        "Live-Daten konnten derzeit nicht geladen werden. Bitte später erneut versuchen.",
        "Live data could not be loaded right now. Please try again later."
    )
    val workplaceCouldNotBeAddedMessage: String = t(
        "Der Arbeitsplatz konnte nicht hinzugefügt werden.",
        "The workplace could not be added."
    )

    fun copyrightLine(year: Int): String = "© $year SFK Robert Lembacher und Dr. Thomas Entner"

    fun deleteWorkplaceMessage(name: String): String = when (language) {
        ResolvedLanguage.DE -> "Der Arbeitsplatz \"$name\" wird gelöscht."
        ResolvedLanguage.BG -> "Работното място „$name“ ще бъде изтрито."
        ResolvedLanguage.DA -> "Arbejdspladsen \"$name\" bliver slettet."
        ResolvedLanguage.EN -> "The workplace \"$name\" will be deleted."
        ResolvedLanguage.ET -> "Töökoht „$name“ kustutatakse."
        ResolvedLanguage.FI -> "Työpaikka \"$name\" poistetaan."
        ResolvedLanguage.FR -> "Le lieu de travail « $name » sera supprimé."
        ResolvedLanguage.EL -> "Ο χώρος εργασίας «$name» θα διαγραφεί."
        ResolvedLanguage.GA -> "Scriosfar an láthair oibre \"$name\"."
        ResolvedLanguage.IT -> "Il luogo di lavoro \"$name\" verrà eliminato."
        ResolvedLanguage.HR -> "Radno mjesto „$name“ bit će izbrisano."
        ResolvedLanguage.LV -> "Darba vieta “$name” tiks dzēsta."
        ResolvedLanguage.LT -> "Darbo vieta „$name“ bus pašalinta."
        ResolvedLanguage.MT -> "Il-post tax-xogħol \"$name\" se jitħassar."
        ResolvedLanguage.NL -> "De werkplek \"$name\" wordt verwijderd."
        ResolvedLanguage.PL -> "Miejsce pracy „$name” zostanie usunięte."
        ResolvedLanguage.PT -> "O local de trabalho \"$name\" será removido."
        ResolvedLanguage.RO -> "Locul de muncă „$name” va fi șters."
        ResolvedLanguage.SV -> "Arbetsplatsen \"$name\" kommer att tas bort."
        ResolvedLanguage.SK -> "Pracovisko „$name“ bude odstránené."
        ResolvedLanguage.SL -> "Delovno mesto »$name« bo izbrisano."
        ResolvedLanguage.ES -> "El lugar de trabajo \"$name\" se eliminará."
        ResolvedLanguage.CS -> "Pracoviště „$name“ bude smazáno."
        ResolvedLanguage.HU -> "A(z) „$name” munkahely törlésre kerül."
        ResolvedLanguage.TR -> "\"$name\" iş yeri silinecek."
    }

    fun todayTitle(date: LocalDate): String = if (date == LocalDate.now()) t("Heute", "Today") else weekdayShort(date)

    fun weekdayShort(date: LocalDate): String = date.dayOfWeek.getDisplayName(TextStyle.SHORT, uiLocale).uppercase(uiLocale)

    fun languageOption(language: AppLanguage): String {
        if (language == AppLanguage.SYSTEM) {
            return t("Systemsprache", "System language")
        }

        val targetLocale = Locale.forLanguageTag(language.resolvedLanguage().localeTag)
        val localized = targetLocale.getDisplayLanguage(uiLocale).ifBlank {
            targetLocale.getDisplayLanguage(targetLocale)
        }
        return localized.replaceFirstChar { if (it.isLowerCase()) it.titlecase(uiLocale) else it.toString() }
    }

    fun formatUv(value: Double?): String {
        if (value == null) return notAvailableShort
        return "UV ${String.format(uiLocale, "%.1f", value)}"
    }

    fun formatTemperature(value: Double?): String {
        if (value == null) return notAvailableShort
        return String.format(uiLocale, "%.1f C", value)
    }

    fun formatForecastTemperature(value: Double?): String = value?.let { String.format(uiLocale, "%.0f°", it) } ?: "-"

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

    fun dashboardRiskHeadline(isUvOnlyElevated: Boolean, severity: HazardSeverity): String =
        if (isUvOnlyElevated) severityHeadline(HazardSeverity.HEAT_YELLOW) else severityHeadline(severity)

    fun dashboardActionText(
        isUvOnlyElevated: Boolean,
        severity: HazardSeverity,
        uvAffectedWorksitesCount: Int
    ): String = if (isUvOnlyElevated) {
        uvOnlyAction(uvAffectedWorksitesCount)
    } else {
        severityAction(severity)
    }

    fun uvOnlyAction(worksitesCount: Int): String {
        val format = if (worksitesCount == 1) {
            t(
                "%d Arbeitsplatz über UV-Index 5. UV-Schutzmaßnahmen umsetzen.",
                "%d workplace above UV index 5. Implement UV protection measures."
            )
        } else {
            t(
                "%d Arbeitsplätze über UV-Index 5. UV-Schutzmaßnahmen umsetzen.",
                "%d workplaces above UV index 5. Implement UV protection measures."
            )
        }
        val message = String.format(uiLocale, format, worksitesCount)
        val sentenceBreakIndex = message.indexOf(". ")
        if (sentenceBreakIndex == -1) {
            return message
        }
        return buildString(message.length + 1) {
            append(message, 0, sentenceBreakIndex + 1)
            append('\n')
            append(message, sentenceBreakIndex + 2, message.length)
        }
    }

    companion object {
        private val INFO_CHECKLIST_URL: String? = null
    }
}

private val ResolvedLanguage.localeTag: String
    get() = when (this) {
        ResolvedLanguage.DE -> "de-AT"
        ResolvedLanguage.BG -> "bg-BG"
        ResolvedLanguage.DA -> "da-DK"
        ResolvedLanguage.EN -> "en-US"
        ResolvedLanguage.ET -> "et-EE"
        ResolvedLanguage.FI -> "fi-FI"
        ResolvedLanguage.FR -> "fr-FR"
        ResolvedLanguage.EL -> "el-GR"
        ResolvedLanguage.GA -> "ga-IE"
        ResolvedLanguage.IT -> "it-IT"
        ResolvedLanguage.HR -> "hr-HR"
        ResolvedLanguage.LV -> "lv-LV"
        ResolvedLanguage.LT -> "lt-LT"
        ResolvedLanguage.MT -> "mt-MT"
        ResolvedLanguage.NL -> "nl-NL"
        ResolvedLanguage.PL -> "pl-PL"
        ResolvedLanguage.PT -> "pt-PT"
        ResolvedLanguage.RO -> "ro-RO"
        ResolvedLanguage.SV -> "sv-SE"
        ResolvedLanguage.SK -> "sk-SK"
        ResolvedLanguage.SL -> "sl-SI"
        ResolvedLanguage.ES -> "es-ES"
        ResolvedLanguage.CS -> "cs-CZ"
        ResolvedLanguage.HU -> "hu-HU"
        ResolvedLanguage.TR -> "tr-TR"
    }
