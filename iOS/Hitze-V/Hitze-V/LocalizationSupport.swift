import Foundation

enum DashboardUserMessage: Equatable {
    case enterAddress
    case noMatchingAddress
    case addressSearchFailed
    case unsupportedArea
    case liveDataUnavailable
    case workplaceCouldNotBeAdded
}

extension UserDefaults {
    var selectedAppLanguage: AppLanguage {
        AppLanguage(rawValue: string(forKey: "dashboard.language") ?? AppLanguage.system.rawValue) ?? .system
    }

    var resolvedAppLanguage: ResolvedLanguage {
        selectedAppLanguage.resolvedLanguage
    }
}

extension ResolvedLanguage {
    var localeIdentifier: String {
        switch self {
        case .de: return "de_AT"
        case .bg: return "bg_BG"
        case .da: return "da_DK"
        case .en: return "en_US"
        case .et: return "et_EE"
        case .fi: return "fi_FI"
        case .fr: return "fr_FR"
        case .el: return "el_GR"
        case .ga: return "ga_IE"
        case .it: return "it_IT"
        case .hr: return "hr_HR"
        case .lv: return "lv_LV"
        case .lt: return "lt_LT"
        case .mt: return "mt_MT"
        case .nl: return "nl_NL"
        case .pl: return "pl_PL"
        case .pt: return "pt_PT"
        case .ro: return "ro_RO"
        case .sv: return "sv_SE"
        case .sk: return "sk_SK"
        case .sl: return "sl_SI"
        case .es: return "es_ES"
        case .cs: return "cs_CZ"
        case .hu: return "hu_HU"
        case .tr: return "tr_TR"
        }
    }
}

extension Copybook {
    func deleteWorkplaceMessage(_ name: String) -> String {
        switch language {
        case .de:
            return "Der Arbeitsplatz \"\(name)\" wird gelöscht."
        case .bg:
            return "Работното място „\(name)“ ще бъде изтрито."
        case .da:
            return "Arbejdspladsen \"\(name)\" bliver slettet."
        case .en:
            return "The workplace \"\(name)\" will be deleted."
        case .et:
            return "Töökoht „\(name)“ kustutatakse."
        case .fi:
            return "Työpaikka \"\(name)\" poistetaan."
        case .fr:
            return "Le lieu de travail « \(name) » sera supprimé."
        case .el:
            return "Ο χώρος εργασίας «\(name)» θα διαγραφεί."
        case .ga:
            return "Scriosfar an láthair oibre \"\(name)\"."
        case .it:
            return "Il luogo di lavoro \"\(name)\" verrà eliminato."
        case .hr:
            return "Radno mjesto „\(name)“ bit će izbrisano."
        case .lv:
            return "Darba vieta “\(name)” tiks dzēsta."
        case .lt:
            return "Darbo vieta „\(name)“ bus pašalinta."
        case .mt:
            return "Il-post tax-xogħol \"\(name)\" se jitħassar."
        case .nl:
            return "De werkplek \"\(name)\" wordt verwijderd."
        case .pl:
            return "Miejsce pracy „\(name)” zostanie usunięte."
        case .pt:
            return "O local de trabalho \"\(name)\" será removido."
        case .ro:
            return "Locul de muncă „\(name)” va fi șters."
        case .sv:
            return "Arbetsplatsen \"\(name)\" kommer att tas bort."
        case .sk:
            return "Pracovisko „\(name)“ bude odstránené."
        case .sl:
            return "Delovno mesto »\(name)« bo izbrisano."
        case .es:
            return "El lugar de trabajo \"\(name)\" se eliminará."
        case .cs:
            return "Pracoviště „\(name)“ bude smazáno."
        case .hu:
            return "A(z) „\(name)” munkahely törlésre kerül."
        case .tr:
            return "\"\(name)\" iş yeri silinecek."
        }
    }

    var addWorkplaceFailureTitle: String { t("Hinzufügen nicht möglich", "Unable to add") }
    var optionalFieldPlaceholder: String { t("Optional", "Optional") }
    var pushNotificationsSection: String {
        switch language {
        case .de: return "Push-Benachrichtigungen"
        case .bg: return "Push известия"
        case .da: return "Push-notifikationer"
        case .en: return "Push notifications"
        case .et: return "Push-teavitused"
        case .fi: return "Push-ilmoitukset"
        case .fr: return "Notifications push"
        case .el: return "Ειδοποιήσεις push"
        case .ga: return "Fógraí brú"
        case .it: return "Notifiche push"
        case .hr: return "Push obavijesti"
        case .lv: return "Push paziņojumi"
        case .lt: return "Push pranešimai"
        case .mt: return "Notifikazzjonijiet push"
        case .nl: return "Pushmeldingen"
        case .pl: return "Powiadomienia push"
        case .pt: return "Notificações push"
        case .ro: return "Notificări push"
        case .sv: return "Pushnotiser"
        case .sk: return "Push notifikácie"
        case .sl: return "Push obvestila"
        case .es: return "Notificaciones push"
        case .cs: return "Push oznámení"
        case .hu: return "Push értesítések"
        case .tr: return "Push bildirimleri"
        }
    }
    var pushNotificationsDescription: String {
        switch language {
        case .de: return "Lege fest, ob Hitzewarnungen per Push gesendet werden und für welche Arbeitsplätze."
        case .bg: return "Изберете дали предупрежденията за горещини да се изпращат като push известия и за кои работни места."
        case .da: return "Vælg, om varmeadvarsler skal sendes som push-notifikationer, og for hvilke arbejdspladser."
        case .en: return "Choose whether heat alerts are sent as push notifications and for which worksites."
        case .et: return "Vali, kas kuumahoiatused saadetakse push-teavitustena ja milliste töökohtade jaoks."
        case .fi: return "Valitse, lähetetäänkö kuumuusvaroitukset push-ilmoituksina ja mille työpaikoille."
        case .fr: return "Choisissez si les alertes de chaleur doivent être envoyées sous forme de notifications push et pour quels lieux de travail."
        case .el: return "Επιλέξτε αν οι προειδοποιήσεις ζέστης θα αποστέλλονται ως ειδοποιήσεις push και για ποιους χώρους εργασίας."
        case .ga: return "Roghnaigh an seolfar foláirimh teasa mar fhógraí brú agus do na hionaid oibre a gheobhaidh iad."
        case .it: return "Scegli se inviare gli avvisi di calore come notifiche push e per quali luoghi di lavoro."
        case .hr: return "Odaberite hoće li se upozorenja na vrućinu slati kao push obavijesti i za koja radna mjesta."
        case .lv: return "Izvēlieties, vai karstuma brīdinājumi jānosūta kā push paziņojumi un kurām darba vietām."
        case .lt: return "Pasirinkite, ar karščio įspėjimai turi būti siunčiami kaip push pranešimai ir kurioms darbo vietoms."
        case .mt: return "Agħżel jekk it-twissijiet tas-sħana għandhomx jintbagħtu bħala notifikazzjonijiet push u għal liema postijiet tax-xogħol."
        case .nl: return "Kies of hittewaarschuwingen als pushmeldingen moeten worden verzonden en voor welke werkplekken."
        case .pl: return "Wybierz, czy ostrzeżenia o upale mają być wysyłane jako powiadomienia push i dla których miejsc pracy."
        case .pt: return "Escolha se os alertas de calor devem ser enviados como notificações push e para quais locais de trabalho."
        case .ro: return "Alege dacă alertele de căldură trebuie trimise ca notificări push și pentru ce locuri de muncă."
        case .sv: return "Välj om värmevarningar ska skickas som pushnotiser och för vilka arbetsplatser."
        case .sk: return "Vyberte, či sa majú upozornenia na teplo odosielať ako push notifikácie a pre ktoré pracoviská."
        case .sl: return "Izberite, ali naj se opozorila o vročini pošiljajo kot push obvestila in za katera delovna mesta."
        case .es: return "Elige si las alertas de calor deben enviarse como notificaciones push y para qué lugares de trabajo."
        case .cs: return "Vyberte, zda se mají upozornění na horko posílat jako push oznámení a pro která pracoviště."
        case .hu: return "Válaszd ki, hogy a hőségriasztások push értesítésként legyenek-e elküldve, és mely munkahelyekre."
        case .tr: return "Sıcaklık uyarılarının push bildirimleri olarak gönderilip gönderilmeyeceğini ve hangi iş yerleri için gönderileceğini seçin."
        }
    }
    var pushNotificationsEnabledLabel: String {
        switch language {
        case .de: return "Push-Benachrichtigungen aktivieren"
        case .bg: return "Активиране на push известия"
        case .da: return "Aktivér push-notifikationer"
        case .en: return "Enable push notifications"
        case .et: return "Luba push-teavitused"
        case .fi: return "Ota push-ilmoitukset käyttöön"
        case .fr: return "Activer les notifications push"
        case .el: return "Ενεργοποίηση ειδοποιήσεων push"
        case .ga: return "Cumasaigh fógraí brú"
        case .it: return "Attiva le notifiche push"
        case .hr: return "Omogući push obavijesti"
        case .lv: return "Ieslēgt push paziņojumus"
        case .lt: return "Įjungti push pranešimus"
        case .mt: return "Attiva n-notifikazzjonijiet push"
        case .nl: return "Pushmeldingen inschakelen"
        case .pl: return "Włącz powiadomienia push"
        case .pt: return "Ativar notificações push"
        case .ro: return "Activează notificările push"
        case .sv: return "Aktivera pushnotiser"
        case .sk: return "Povoliť push notifikácie"
        case .sl: return "Omogoči push obvestila"
        case .es: return "Activar notificaciones push"
        case .cs: return "Povolit push oznámení"
        case .hu: return "Push értesítések engedélyezése"
        case .tr: return "Push bildirimlerini etkinleştir"
        }
    }
    var pushWorksitesSectionTitle: String {
        switch language {
        case .de: return "Arbeitsplätze für Push"
        case .bg: return "Работни места за push"
        case .da: return "Arbejdspladser til push"
        case .en: return "Worksites for push"
        case .et: return "Töökohad push-teavitustele"
        case .fi: return "Työpaikat push-ilmoituksille"
        case .fr: return "Lieux de travail pour les notifications push"
        case .el: return "Χώροι εργασίας για push"
        case .ga: return "Ionaid oibre le haghaidh fógraí brú"
        case .it: return "Luoghi di lavoro per le notifiche push"
        case .hr: return "Radna mjesta za push obavijesti"
        case .lv: return "Darba vietas push paziņojumiem"
        case .lt: return "Darbo vietos push pranešimams"
        case .mt: return "Postijiet tax-xogħol għan-notifikazzjonijiet push"
        case .nl: return "Werkplekken voor pushmeldingen"
        case .pl: return "Miejsca pracy dla powiadomień push"
        case .pt: return "Locais de trabalho para notificações push"
        case .ro: return "Locuri de muncă pentru notificări push"
        case .sv: return "Arbetsplatser för pushnotiser"
        case .sk: return "Pracoviská pre push notifikácie"
        case .sl: return "Delovna mesta za push obvestila"
        case .es: return "Lugares de trabajo para notificaciones push"
        case .cs: return "Pracoviště pro push oznámení"
        case .hu: return "Munkahelyek push értesítésekhez"
        case .tr: return "Push bildirimleri için iş yerleri"
        }
    }
    var pushNoWorksitesMessage: String {
        switch language {
        case .de: return "Lege zuerst einen Arbeitsplatz an, um Push-Benachrichtigungen gezielt zu steuern."
        case .bg: return "Първо добавете работно място, за да управлявате push известията поотделно."
        case .da: return "Opret først en arbejdsplads for at styre push-notifikationer individuelt."
        case .en: return "Add a worksite first to control push notifications individually."
        case .et: return "Lisa esmalt töökoht, et saaksid push-teavitusi eraldi hallata."
        case .fi: return "Lisää ensin työpaikka, jotta voit hallita push-ilmoituksia erikseen."
        case .fr: return "Ajoutez d'abord un lieu de travail pour gérer les notifications push individuellement."
        case .el: return "Προσθέστε πρώτα έναν χώρο εργασίας για να διαχειρίζεστε ξεχωριστά τις ειδοποιήσεις push."
        case .ga: return "Cuir láthair oibre leis ar dtús chun fógraí brú a bhainistiú ina n-aonar."
        case .it: return "Aggiungi prima un luogo di lavoro per gestire le notifiche push singolarmente."
        case .hr: return "Najprije dodajte radno mjesto kako biste pojedinačno upravljali push obavijestima."
        case .lv: return "Vispirms pievienojiet darba vietu, lai varētu atsevišķi pārvaldīt push paziņojumus."
        case .lt: return "Pirmiausia pridėkite darbo vietą, kad galėtumėte atskirai valdyti push pranešimus."
        case .mt: return "L-ewwel żid post tax-xogħol biex timmaniġġja n-notifikazzjonijiet push individwalment."
        case .nl: return "Voeg eerst een werkplek toe om pushmeldingen afzonderlijk te beheren."
        case .pl: return "Najpierw dodaj miejsce pracy, aby zarządzać powiadomieniami push osobno."
        case .pt: return "Adicione primeiro um local de trabalho para gerir as notificações push individualmente."
        case .ro: return "Adaugă mai întâi un loc de muncă pentru a gestiona individual notificările push."
        case .sv: return "Lägg först till en arbetsplats för att styra pushnotiser individuellt."
        case .sk: return "Najprv pridajte pracovisko, aby ste mohli push notifikácie spravovať jednotlivo."
        case .sl: return "Najprej dodajte delovno mesto, da boste lahko push obvestila upravljali posamezno."
        case .es: return "Primero añade un lugar de trabajo para controlar las notificaciones push individualmente."
        case .cs: return "Nejprve přidejte pracoviště, abyste mohli push oznámení spravovat jednotlivě."
        case .hu: return "Először adj hozzá egy munkahelyet, hogy külön kezeld a push értesítéseket."
        case .tr: return "Push bildirimlerini ayrı ayrı yönetmek için önce bir iş yeri ekleyin."
        }
    }
    var pushWorksiteFallbackSubtitle: String {
        switch language {
        case .de: return "Kein Adresstext vorhanden"
        case .bg: return "Няма наличен адрес"
        case .da: return "Ingen adresse tilgængelig"
        case .en: return "No address available"
        case .et: return "Aadress puudub"
        case .fi: return "Osoitetta ei ole saatavilla"
        case .fr: return "Aucune adresse disponible"
        case .el: return "Δεν υπάρχει διαθέσιμη διεύθυνση"
        case .ga: return "Níl seoladh ar fáil"
        case .it: return "Nessun indirizzo disponibile"
        case .hr: return "Adresa nije dostupna"
        case .lv: return "Adrese nav pieejama"
        case .lt: return "Adresas nepasiekiamas"
        case .mt: return "L-ebda indirizz disponibbli"
        case .nl: return "Geen adres beschikbaar"
        case .pl: return "Brak dostępnego adresu"
        case .pt: return "Sem endereço disponível"
        case .ro: return "Nicio adresă disponibilă"
        case .sv: return "Ingen adress tillgänglig"
        case .sk: return "Adresa nie je k dispozícii"
        case .sl: return "Naslov ni na voljo"
        case .es: return "No hay dirección disponible"
        case .cs: return "Adresa není k dispozici"
        case .hu: return "Nincs elérhető cím"
        case .tr: return "Adres mevcut değil"
        }
    }
    var cityStreetPlaceholder: String { t("Stadt, Straße...", "City, Street...") }
    var addressRequiredMessage: String { t("Bitte eine Adresse eingeben.", "Please enter an address.") }
    var noMatchingAddressMessage: String { t("Keine passende Adresse gefunden.", "No matching address found.") }
    var addressSearchFailedMessage: String { t("Adresssuche fehlgeschlagen. Bitte erneut versuchen.", "Address search failed. Please try again.") }
    var unsupportedAreaMessage: String {
        t(
            "Dieses Gebiet liegt vermutlich außerhalb Österreichs oder wird von GeoSphere nicht erkannt. Ein Hinzufügen ist nicht möglich.",
            "This area is likely outside Austria or not recognized by GeoSphere. Adding is not possible."
        )
    }
    var liveDataUnavailableMessage: String {
        t(
            "Live-Daten konnten derzeit nicht geladen werden. Bitte später erneut versuchen.",
            "Live data could not be loaded right now. Please try again later."
        )
    }
    var workplaceCouldNotBeAddedMessage: String {
        t(
            "Der Arbeitsplatz konnte nicht hinzugefügt werden.",
            "The workplace could not be added."
        )
    }

    func text(for message: DashboardUserMessage) -> String {
        switch message {
        case .enterAddress:
            return addressRequiredMessage
        case .noMatchingAddress:
            return noMatchingAddressMessage
        case .addressSearchFailed:
            return addressSearchFailedMessage
        case .unsupportedArea:
            return unsupportedAreaMessage
        case .liveDataUnavailable:
            return liveDataUnavailableMessage
        case .workplaceCouldNotBeAdded:
            return workplaceCouldNotBeAddedMessage
        }
    }

    func localizedLanguageName(for appLanguage: AppLanguage) -> String {
        guard appLanguage != .system else {
            return t("Systemsprache", "System language")
        }

        let uiLocale = Locale(identifier: language.localeIdentifier)
        let targetLocale = Locale(identifier: appLanguage.resolvedLanguage.localeIdentifier)

        return uiLocale.localizedString(forLanguageCode: targetLocale.language.languageCode?.identifier ?? appLanguage.rawValue)
            ?? targetLocale.localizedString(forLanguageCode: targetLocale.language.languageCode?.identifier ?? appLanguage.rawValue)
            ?? appLanguage.rawValue.uppercased()
    }

    func localizedWeekdayShort(_ weekday: Int) -> String {
        guard (1...7).contains(weekday) else {
            return "-"
        }

        var formatterCalendar = Calendar(identifier: .gregorian)
        formatterCalendar.locale = Locale(identifier: language.localeIdentifier)

        let formatter = DateFormatter()
        formatter.calendar = formatterCalendar
        formatter.locale = formatterCalendar.locale

        let symbols = formatter.shortWeekdaySymbols ?? formatter.veryShortWeekdaySymbols ?? []
        guard symbols.count == 7 else {
            return "-"
        }

        return symbols[weekday - 1].uppercased(with: formatterCalendar.locale)
    }
}
