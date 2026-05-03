export const SUPPORTED_PUSH_LANGUAGES = [
  "bg",
  "da",
  "de",
  "en",
  "et",
  "fi",
  "fr",
  "el",
  "ga",
  "it",
  "hr",
  "lv",
  "lt",
  "mt",
  "nl",
  "pl",
  "pt",
  "ro",
  "sv",
  "sk",
  "sl",
  "es",
  "cs",
  "hu",
  "tr",
] as const;

export type SupportedPushLanguage = (typeof SUPPORTED_PUSH_LANGUAGES)[number];

export const DEFAULT_PUSH_LANGUAGE: SupportedPushLanguage = "en";

interface PushLocalizationTemplates {
  localeTag: string;
  municipalityLabel: string;
  heatWarningTitle: string;
  heatBodyTemplate: string;
  todayRangeTemplate: string;
  validRangeTemplate: string;
  todayFromTemplate: string;
  fromTemplate: string;
  todayUntilTemplate: string;
  untilTemplate: string;
  timeWindowChangedTemplate: string;
  timeWindowUpdatedTemplate: string;
  manualTestTopicBody: string;
  manualTestTokenBody: string;
}

const EN_LOCALIZATION: PushLocalizationTemplates = {
  localeTag: "en-GB",
  municipalityLabel: "Municipality",
  heatWarningTitle: "Heat Warning",
  heatBodyTemplate:
    "Warning level {level} has been reached in {name}. Follow the Heat-V protective measures.",
  todayRangeTemplate: "Today from {start} to {end}",
  validRangeTemplate: "Valid: {start} - {end}",
  todayFromTemplate: "Today from {start}",
  fromTemplate: "From: {start}",
  todayUntilTemplate: "Today until {end}",
  untilTemplate: "Until: {end}",
  timeWindowChangedTemplate: "Time window updated: from {previous} to {current}.",
  timeWindowUpdatedTemplate: "Updated time window: {current}.",
  manualTestTopicBody: "This is a manual backend test notification.",
  manualTestTokenBody: "Direct test delivery to one device token.",
};

const PUSH_LOCALIZATION: Record<SupportedPushLanguage, PushLocalizationTemplates> = {
  bg: {
    ...EN_LOCALIZATION,
    localeTag: "bg-BG",
    municipalityLabel: "Obshtina",
    heatWarningTitle: "Preduprezhdenie za zhega",
    heatBodyTemplate:
      "V {name} e dostignato nivo na preduprezhdenie {level}. Prilozhete merki za zashtita ot zhega po Hitze-V.",
    todayRangeTemplate: "Dnes ot {start} do {end}",
    validRangeTemplate: "Validno: {start} - {end}",
    todayFromTemplate: "Dnes ot {start}",
    fromTemplate: "Ot: {start}",
    todayUntilTemplate: "Dnes do {end}",
    untilTemplate: "Do: {end}",
    timeWindowChangedTemplate: "Vremeviyat prozorets e aktualiziran: ot {previous} na {current}.",
    timeWindowUpdatedTemplate: "Aktualiziran vremevi prozorets: {current}.",
    manualTestTopicBody: "Tova e rachna testova push notifikatsiya ot backend-a.",
    manualTestTokenBody: "Direkten testov push kum edin token na ustroystvo.",
  },
  da: {
    ...EN_LOCALIZATION,
    localeTag: "da-DK",
    municipalityLabel: "Kommune",
    heatWarningTitle: "Hedevarsel",
    heatBodyTemplate:
      "Advarselsniveau {level} er naaet i {name}. Foelg varmebeskyttelsesforanstaltningerne i Hitze-V.",
    todayRangeTemplate: "I dag fra {start} til {end}",
    validRangeTemplate: "Gyldig: {start} - {end}",
    todayFromTemplate: "I dag fra {start}",
    fromTemplate: "Fra: {start}",
    todayUntilTemplate: "I dag indtil {end}",
    untilTemplate: "Indtil: {end}",
    timeWindowChangedTemplate: "Tidsvinduet er opdateret: fra {previous} til {current}.",
    timeWindowUpdatedTemplate: "Opdateret tidsvindue: {current}.",
    manualTestTopicBody: "Dette er en manuel testbesked fra backend.",
    manualTestTokenBody: "Direkte testafsendelse til en enkelt enhedstoken.",
  },
  de: {
    ...EN_LOCALIZATION,
    localeTag: "de-AT",
    municipalityLabel: "Gemeinde",
    heatWarningTitle: "Hitze-Warnung",
    heatBodyTemplate:
      "In {name} wurde Warnstufe {level} erreicht. Hitzeschutzmassnahmen nach Hitze-V umsetzen.",
    todayRangeTemplate: "Heute von {start} bis {end} Uhr",
    validRangeTemplate: "Gueltig: {start} - {end}",
    todayFromTemplate: "Heute ab {start} Uhr",
    fromTemplate: "Ab: {start}",
    todayUntilTemplate: "Heute bis {end} Uhr",
    untilTemplate: "Bis: {end}",
    timeWindowChangedTemplate: "Zeitfenster aktualisiert: von {previous} auf {current}.",
    timeWindowUpdatedTemplate: "Aktualisiertes Zeitfenster: {current}.",
    manualTestTopicBody: "Dies ist eine manuelle Testnachricht vom Backend.",
    manualTestTokenBody: "Direkter Testversand an ein einzelnes Geraet.",
  },
  en: EN_LOCALIZATION,
  et: {
    ...EN_LOCALIZATION,
    localeTag: "et-EE",
    municipalityLabel: "Omavalitsus",
    heatWarningTitle: "Kuumahoiatus",
    heatBodyTemplate:
      "Piirkonnas {name} saavutati hoiatusaste {level}. Rakenda Hitze-V kuumakaitsemeetmeid.",
    todayRangeTemplate: "Tana {start}-{end}",
    validRangeTemplate: "Kehtib: {start} - {end}",
    todayFromTemplate: "Tana alates {start}",
    fromTemplate: "Alates: {start}",
    todayUntilTemplate: "Tana kuni {end}",
    untilTemplate: "Kuni: {end}",
    timeWindowChangedTemplate: "Ajavahemik uuendati: {previous} -> {current}.",
    timeWindowUpdatedTemplate: "Uuendatud ajavahemik: {current}.",
    manualTestTopicBody: "See on kasitsi saadetud backendi testteade.",
    manualTestTokenBody: "Otsene test saatmine uhele seadmetokenile.",
  },
  fi: {
    ...EN_LOCALIZATION,
    localeTag: "fi-FI",
    municipalityLabel: "Kunta",
    heatWarningTitle: "Hellevaroitus",
    heatBodyTemplate:
      "Alueella {name} on saavutettu varoitustaso {level}. Noudata Hitze-V:n helteensuojatoimia.",
    todayRangeTemplate: "Tanaan klo {start}-{end}",
    validRangeTemplate: "Voimassa: {start} - {end}",
    todayFromTemplate: "Tanaan klo {start} alkaen",
    fromTemplate: "Alkaen: {start}",
    todayUntilTemplate: "Tanaan klo {end} asti",
    untilTemplate: "Asti: {end}",
    timeWindowChangedTemplate: "Aikavali paivitetty: {previous} -> {current}.",
    timeWindowUpdatedTemplate: "Paivitetty aikavali: {current}.",
    manualTestTopicBody: "Tama on backendin manuaalinen testiviesti.",
    manualTestTokenBody: "Suora testilahetys yhteen laitteen tokeniin.",
  },
  fr: {
    ...EN_LOCALIZATION,
    localeTag: "fr-FR",
    municipalityLabel: "Commune",
    heatWarningTitle: "Alerte chaleur",
    heatBodyTemplate:
      "Le niveau d'alerte {level} est atteint a {name}. Appliquez les mesures de protection chaleur selon Hitze-V.",
    todayRangeTemplate: "Aujourd'hui de {start} a {end}",
    validRangeTemplate: "Valable: {start} - {end}",
    todayFromTemplate: "Aujourd'hui a partir de {start}",
    fromTemplate: "A partir de: {start}",
    todayUntilTemplate: "Aujourd'hui jusqu'a {end}",
    untilTemplate: "Jusqu'a: {end}",
    timeWindowChangedTemplate: "Fenetre horaire mise a jour: de {previous} a {current}.",
    timeWindowUpdatedTemplate: "Fenetre horaire mise a jour: {current}.",
    manualTestTopicBody: "Ceci est une notification de test manuelle du backend.",
    manualTestTokenBody: "Envoi de test direct vers un seul token d'appareil.",
  },
  el: {
    ...EN_LOCALIZATION,
    localeTag: "el-GR",
    municipalityLabel: "Dimos",
    heatWarningTitle: "Proeidopoiisi kausona",
    heatBodyTemplate:
      "Sto {name} eftase to epipedo proeidopoiisis {level}. Efarmoste metra prostasias zestis tou Hitze-V.",
    todayRangeTemplate: "Simera apo {start} eos {end}",
    validRangeTemplate: "Isxyei: {start} - {end}",
    todayFromTemplate: "Simera apo {start}",
    fromTemplate: "Apo: {start}",
    todayUntilTemplate: "Simera eos {end}",
    untilTemplate: "Eos: {end}",
    timeWindowChangedTemplate: "To xroniko parathyro enimerothike: apo {previous} se {current}.",
    timeWindowUpdatedTemplate: "Enimeromeno xroniko parathyro: {current}.",
    manualTestTopicBody: "Afto einai cheirokinito test notification apo to backend.",
    manualTestTokenBody: "Apeutheias test apostoli se ena token syskevis.",
  },
  ga: {
    ...EN_LOCALIZATION,
    localeTag: "ga-IE",
    municipalityLabel: "Bardas",
    heatWarningTitle: "Rabhadh teasa",
    heatBodyTemplate:
      "Sroicheadh leibheal rabhaidh {level} i {name}. Lean bearta cosanta teasa Hitze-V.",
    todayRangeTemplate: "Inniu o {start} go {end}",
    validRangeTemplate: "Baili: {start} - {end}",
    todayFromTemplate: "Inniu o {start}",
    fromTemplate: "O: {start}",
    todayUntilTemplate: "Inniu go dti {end}",
    untilTemplate: "Go dti: {end}",
    timeWindowChangedTemplate: "Nuashonru ama: o {previous} go {current}.",
    timeWindowUpdatedTemplate: "Fuinneog ama nuashonraithe: {current}.",
    manualTestTopicBody: "Seo fogra tástála laimhe on backend.",
    manualTestTokenBody: "Seachadadh tástála díreach chuig token gléis amháin.",
  },
  it: {
    ...EN_LOCALIZATION,
    localeTag: "it-IT",
    municipalityLabel: "Comune",
    heatWarningTitle: "Allerta caldo",
    heatBodyTemplate:
      "Nel comune di {name} e stato raggiunto il livello di allerta {level}. Applicare le misure di protezione caldo di Hitze-V.",
    todayRangeTemplate: "Oggi dalle {start} alle {end}",
    validRangeTemplate: "Valido: {start} - {end}",
    todayFromTemplate: "Oggi dalle {start}",
    fromTemplate: "Da: {start}",
    todayUntilTemplate: "Oggi fino alle {end}",
    untilTemplate: "Fino a: {end}",
    timeWindowChangedTemplate: "Finestra temporale aggiornata: da {previous} a {current}.",
    timeWindowUpdatedTemplate: "Finestra temporale aggiornata: {current}.",
    manualTestTopicBody: "Questa e una notifica di test manuale dal backend.",
    manualTestTokenBody: "Invio test diretto a un singolo token dispositivo.",
  },
  hr: {
    ...EN_LOCALIZATION,
    localeTag: "hr-HR",
    municipalityLabel: "Opcina",
    heatWarningTitle: "Upozorenje na vrucinu",
    heatBodyTemplate:
      "U {name} je dosegnuta razina upozorenja {level}. Primijenite Hitze-V mjere zastite od vrucine.",
    todayRangeTemplate: "Danas od {start} do {end}",
    validRangeTemplate: "Vrijedi: {start} - {end}",
    todayFromTemplate: "Danas od {start}",
    fromTemplate: "Od: {start}",
    todayUntilTemplate: "Danas do {end}",
    untilTemplate: "Do: {end}",
    timeWindowChangedTemplate: "Vremenski prozor azuriran: od {previous} do {current}.",
    timeWindowUpdatedTemplate: "Azurirani vremenski prozor: {current}.",
    manualTestTopicBody: "Ovo je rucna testna obavijest iz backenda.",
    manualTestTokenBody: "Izravna testna isporuka na jedan token uredaja.",
  },
  lv: {
    ...EN_LOCALIZATION,
    localeTag: "lv-LV",
    municipalityLabel: "Pashvaldiba",
    heatWarningTitle: "Karstuma bridinajums",
    heatBodyTemplate:
      "{name} sasniegts bridinajuma limenis {level}. Ieverojiet Hitze-V karstuma aizsardzibas pasakumus.",
    todayRangeTemplate: "Sodien no {start} lidz {end}",
    validRangeTemplate: "Speka: {start} - {end}",
    todayFromTemplate: "Sodien no {start}",
    fromTemplate: "No: {start}",
    todayUntilTemplate: "Sodien lidz {end}",
    untilTemplate: "Lidz: {end}",
    timeWindowChangedTemplate: "Laika logs atjauninats: no {previous} uz {current}.",
    timeWindowUpdatedTemplate: "Atjauninats laika logs: {current}.",
    manualTestTopicBody: "Sis ir backenda manuals testa pazinojums.",
    manualTestTokenBody: "Tiesa testa piegade vienam ierices tokenam.",
  },
  lt: {
    ...EN_LOCALIZATION,
    localeTag: "lt-LT",
    municipalityLabel: "Savivaldybe",
    heatWarningTitle: "Karscio ispejimas",
    heatBodyTemplate:
      "{name} pasiektas ispejimo lygis {level}. Taikykite Hitze-V apsaugos nuo karscio priemones.",
    todayRangeTemplate: "Siandien nuo {start} iki {end}",
    validRangeTemplate: "Galioja: {start} - {end}",
    todayFromTemplate: "Siandien nuo {start}",
    fromTemplate: "Nuo: {start}",
    todayUntilTemplate: "Siandien iki {end}",
    untilTemplate: "Iki: {end}",
    timeWindowChangedTemplate: "Laiko langas atnaujintas: nuo {previous} iki {current}.",
    timeWindowUpdatedTemplate: "Atnaujintas laiko langas: {current}.",
    manualTestTopicBody: "Tai rankinis backend testo pranesimas.",
    manualTestTokenBody: "Tiesioginis testinis siuntimas i viena irenginio tokena.",
  },
  mt: {
    ...EN_LOCALIZATION,
    localeTag: "mt-MT",
    municipalityLabel: "Kunsill",
    heatWarningTitle: "Twissija tas-sahna",
    heatBodyTemplate:
      "F'{name} intlahet livell ta' twissija {level}. Segwi mizuri ta' protezzjoni mis-sahna ta' Hitze-V.",
    todayRangeTemplate: "Illum minn {start} sa {end}",
    validRangeTemplate: "Validu: {start} - {end}",
    todayFromTemplate: "Illum minn {start}",
    fromTemplate: "Minn: {start}",
    todayUntilTemplate: "Illum sa {end}",
    untilTemplate: "Sa: {end}",
    timeWindowChangedTemplate: "Il-hin gie aggornat: minn {previous} ghal {current}.",
    timeWindowUpdatedTemplate: "Tieqa tal-hin aggornata: {current}.",
    manualTestTopicBody: "Din hija notifika ta' test manwali mill-backend.",
    manualTestTokenBody: "Kunsinna ta' test diretta lil token wiehed ta' apparat.",
  },
  nl: {
    ...EN_LOCALIZATION,
    localeTag: "nl-NL",
    municipalityLabel: "Gemeente",
    heatWarningTitle: "Hittewaarschuwing",
    heatBodyTemplate:
      "In {name} is waarschuwingsniveau {level} bereikt. Voer hittebeschermingsmaatregelen volgens Hitze-V uit.",
    todayRangeTemplate: "Vandaag van {start} tot {end}",
    validRangeTemplate: "Geldig: {start} - {end}",
    todayFromTemplate: "Vandaag vanaf {start}",
    fromTemplate: "Vanaf: {start}",
    todayUntilTemplate: "Vandaag tot {end}",
    untilTemplate: "Tot: {end}",
    timeWindowChangedTemplate: "Tijdsvenster bijgewerkt: van {previous} naar {current}.",
    timeWindowUpdatedTemplate: "Bijgewerkt tijdsvenster: {current}.",
    manualTestTopicBody: "Dit is een handmatige backend testmelding.",
    manualTestTokenBody: "Directe testlevering naar een enkel apparaattoken.",
  },
  pl: {
    ...EN_LOCALIZATION,
    localeTag: "pl-PL",
    municipalityLabel: "Gmina",
    heatWarningTitle: "Ostrzezenie przed upalem",
    heatBodyTemplate:
      "W {name} osiagnieto poziom ostrzezenia {level}. Zastosuj srodki ochrony przed upalem wg Hitze-V.",
    todayRangeTemplate: "Dzis od {start} do {end}",
    validRangeTemplate: "Wazne: {start} - {end}",
    todayFromTemplate: "Dzis od {start}",
    fromTemplate: "Od: {start}",
    todayUntilTemplate: "Dzis do {end}",
    untilTemplate: "Do: {end}",
    timeWindowChangedTemplate: "Okno czasowe zaktualizowano: z {previous} na {current}.",
    timeWindowUpdatedTemplate: "Zaktualizowane okno czasowe: {current}.",
    manualTestTopicBody: "To jest reczne testowe powiadomienie z backendu.",
    manualTestTokenBody: "Bezposrednia testowa wysylka do pojedynczego tokenu urzadzenia.",
  },
  pt: {
    ...EN_LOCALIZATION,
    localeTag: "pt-PT",
    municipalityLabel: "Municipio",
    heatWarningTitle: "Alerta de calor",
    heatBodyTemplate:
      "No municipio de {name} foi atingido o nivel de alerta {level}. Aplique medidas de protecao de calor segundo o Hitze-V.",
    todayRangeTemplate: "Hoje das {start} as {end}",
    validRangeTemplate: "Valido: {start} - {end}",
    todayFromTemplate: "Hoje a partir das {start}",
    fromTemplate: "A partir de: {start}",
    todayUntilTemplate: "Hoje ate {end}",
    untilTemplate: "Ate: {end}",
    timeWindowChangedTemplate: "Janela temporal atualizada: de {previous} para {current}.",
    timeWindowUpdatedTemplate: "Janela temporal atualizada: {current}.",
    manualTestTopicBody: "Esta e uma notificacao de teste manual do backend.",
    manualTestTokenBody: "Envio de teste direto para um unico token de dispositivo.",
  },
  ro: {
    ...EN_LOCALIZATION,
    localeTag: "ro-RO",
    municipalityLabel: "Municipiu",
    heatWarningTitle: "Avertizare de caldura",
    heatBodyTemplate:
      "In {name} a fost atins nivelul de avertizare {level}. Aplicati masurile de protectie la caldura conform Hitze-V.",
    todayRangeTemplate: "Astazi intre {start} si {end}",
    validRangeTemplate: "Valabil: {start} - {end}",
    todayFromTemplate: "Astazi de la {start}",
    fromTemplate: "De la: {start}",
    todayUntilTemplate: "Astazi pana la {end}",
    untilTemplate: "Pana la: {end}",
    timeWindowChangedTemplate: "Intervalul a fost actualizat: de la {previous} la {current}.",
    timeWindowUpdatedTemplate: "Interval actualizat: {current}.",
    manualTestTopicBody: "Aceasta este o notificare de test manuala din backend.",
    manualTestTokenBody: "Livrare de test directa catre un singur token de dispozitiv.",
  },
  sv: {
    ...EN_LOCALIZATION,
    localeTag: "sv-SE",
    municipalityLabel: "Kommun",
    heatWarningTitle: "Varning for varme",
    heatBodyTemplate:
      "I {name} har varningsniva {level} uppnatts. Folj Hitze-V:s atgarder for varmeskydd.",
    todayRangeTemplate: "I dag fran {start} till {end}",
    validRangeTemplate: "Giltig: {start} - {end}",
    todayFromTemplate: "I dag fran {start}",
    fromTemplate: "Fran: {start}",
    todayUntilTemplate: "I dag till {end}",
    untilTemplate: "Till: {end}",
    timeWindowChangedTemplate: "Tidsfonstret uppdaterades: fran {previous} till {current}.",
    timeWindowUpdatedTemplate: "Uppdaterat tidsfonster: {current}.",
    manualTestTopicBody: "Detta ar ett manuellt testmeddelande fran backend.",
    manualTestTokenBody: "Direkt testleverans till en enda enhetstoken.",
  },
  sk: {
    ...EN_LOCALIZATION,
    localeTag: "sk-SK",
    municipalityLabel: "Obec",
    heatWarningTitle: "Upozornenie na horucavu",
    heatBodyTemplate:
      "V oblasti {name} bola dosiahnuta uroven varovania {level}. Uplatnite opatrenia ochrany pred horucavou podla Hitze-V.",
    todayRangeTemplate: "Dnes od {start} do {end}",
    validRangeTemplate: "Platne: {start} - {end}",
    todayFromTemplate: "Dnes od {start}",
    fromTemplate: "Od: {start}",
    todayUntilTemplate: "Dnes do {end}",
    untilTemplate: "Do: {end}",
    timeWindowChangedTemplate: "Casove okno aktualizovane: z {previous} na {current}.",
    timeWindowUpdatedTemplate: "Aktualizovane casove okno: {current}.",
    manualTestTopicBody: "Toto je manualne testovacie upozornenie z backendu.",
    manualTestTokenBody: "Priame testovacie odoslanie na jeden token zariadenia.",
  },
  sl: {
    ...EN_LOCALIZATION,
    localeTag: "sl-SI",
    municipalityLabel: "Obcina",
    heatWarningTitle: "Opozorilo za vrocino",
    heatBodyTemplate:
      "V obcini {name} je dosezena stopnja opozorila {level}. Uporabite ukrepe zascite pred vrocino po Hitze-V.",
    todayRangeTemplate: "Danes od {start} do {end}",
    validRangeTemplate: "Velja: {start} - {end}",
    todayFromTemplate: "Danes od {start}",
    fromTemplate: "Od: {start}",
    todayUntilTemplate: "Danes do {end}",
    untilTemplate: "Do: {end}",
    timeWindowChangedTemplate: "Casovno okno posodobljeno: iz {previous} na {current}.",
    timeWindowUpdatedTemplate: "Posodobljeno casovno okno: {current}.",
    manualTestTopicBody: "To je rocno testno obvestilo iz backenda.",
    manualTestTokenBody: "Neposredna testna dostava na en token naprave.",
  },
  es: {
    ...EN_LOCALIZATION,
    localeTag: "es-ES",
    municipalityLabel: "Municipio",
    heatWarningTitle: "Alerta de calor",
    heatBodyTemplate:
      "En {name} se ha alcanzado el nivel de alerta {level}. Aplique las medidas de proteccion frente al calor de Hitze-V.",
    todayRangeTemplate: "Hoy de {start} a {end}",
    validRangeTemplate: "Valido: {start} - {end}",
    todayFromTemplate: "Hoy desde {start}",
    fromTemplate: "Desde: {start}",
    todayUntilTemplate: "Hoy hasta {end}",
    untilTemplate: "Hasta: {end}",
    timeWindowChangedTemplate: "Ventana horaria actualizada: de {previous} a {current}.",
    timeWindowUpdatedTemplate: "Ventana horaria actualizada: {current}.",
    manualTestTopicBody: "Esta es una notificacion manual de prueba del backend.",
    manualTestTokenBody: "Envio de prueba directo a un unico token de dispositivo.",
  },
  cs: {
    ...EN_LOCALIZATION,
    localeTag: "cs-CZ",
    municipalityLabel: "Obec",
    heatWarningTitle: "Varovani pred vedrem",
    heatBodyTemplate:
      "V oblasti {name} byl dosazen stupen varovani {level}. Provedte opatreni ochrany pred vedrem podle Hitze-V.",
    todayRangeTemplate: "Dnes od {start} do {end}",
    validRangeTemplate: "Platnost: {start} - {end}",
    todayFromTemplate: "Dnes od {start}",
    fromTemplate: "Od: {start}",
    todayUntilTemplate: "Dnes do {end}",
    untilTemplate: "Do: {end}",
    timeWindowChangedTemplate: "Casove okno aktualizovano: z {previous} na {current}.",
    timeWindowUpdatedTemplate: "Aktualizovane casove okno: {current}.",
    manualTestTopicBody: "Toto je rucni testovaci oznameni z backendu.",
    manualTestTokenBody: "Priame testovaci doruceni na jeden token zarizeni.",
  },
  hu: {
    ...EN_LOCALIZATION,
    localeTag: "hu-HU",
    municipalityLabel: "Onkormanyzat",
    heatWarningTitle: "Hoszegriasztas",
    heatBodyTemplate:
      "{name} teruleten elertek a {level} riasztasi szintet. Alkalmazza a Hitze-V hosvedelmi intezkedeseit.",
    todayRangeTemplate: "Ma {start}-{end}",
    validRangeTemplate: "Ervenyes: {start} - {end}",
    todayFromTemplate: "Ma {start}-tol",
    fromTemplate: "Ettol: {start}",
    todayUntilTemplate: "Ma {end}-ig",
    untilTemplate: "Eddig: {end}",
    timeWindowChangedTemplate: "Idoablak frissitve: {previous} -> {current}.",
    timeWindowUpdatedTemplate: "Frissitett idoablak: {current}.",
    manualTestTopicBody: "Ez egy kezi backend tesztertesites.",
    manualTestTokenBody: "Kozvetlen tesztkuldes egyetlen eszkoztokenre.",
  },
  tr: {
    ...EN_LOCALIZATION,
    localeTag: "tr-TR",
    municipalityLabel: "Belediye",
    heatWarningTitle: "Sicaklik uyarisi",
    heatBodyTemplate:
      "{name} bolgesinde {level} uyari seviyesi goruldu. Hitze-V sicaklik korunma onlemlerini uygulayin.",
    todayRangeTemplate: "Bugun {start} - {end}",
    validRangeTemplate: "Gecerli: {start} - {end}",
    todayFromTemplate: "Bugun {start} itibariyla",
    fromTemplate: "Baslangic: {start}",
    todayUntilTemplate: "Bugun {end} kadar",
    untilTemplate: "Bitis: {end}",
    timeWindowChangedTemplate: "Zaman penceresi guncellendi: {previous} -> {current}.",
    timeWindowUpdatedTemplate: "Guncellenmis zaman penceresi: {current}.",
    manualTestTopicBody: "Bu, backend'den manuel test bildirimidir.",
    manualTestTokenBody: "Tek bir cihaz tokenina dogrudan test gonderimi.",
  },
};

function formatTemplate(
  template: string,
  values: Record<string, string | number>
): string {
  return template.replace(/\{([a-zA-Z0-9_]+)\}/g, (match, key) => {
    if (Object.prototype.hasOwnProperty.call(values, key)) {
      return String(values[key]);
    }
    return match;
  });
}

export interface PushLocalization {
  languageCode: SupportedPushLanguage;
  localeTag: string;
  municipalityLabel: string;
  heatWarningTitle: string;
  buildHeatBody: (name: string, level: number) => string;
  formatTodayRange: (startClock: string, endClock: string) => string;
  formatValidRange: (startText: string, endText: string) => string;
  formatTodayFrom: (startClock: string) => string;
  formatFrom: (startText: string) => string;
  formatTodayUntil: (endClock: string) => string;
  formatUntil: (endText: string) => string;
  formatTimeWindowChanged: (previousText: string, currentText: string) => string;
  formatTimeWindowUpdated: (currentText: string) => string;
  defaultTopicTestTitle: string;
  defaultTopicTestBody: string;
  defaultTokenTestTitle: string;
  defaultTokenTestBody: string;
}

export function listSupportedPushLanguages(): SupportedPushLanguage[] {
  return [...SUPPORTED_PUSH_LANGUAGES];
}

export function parseSupportedPushLanguage(value: string | null | undefined): SupportedPushLanguage | null {
  if (!value) {
    return null;
  }

  const normalized = value.trim().toLowerCase();
  if (!normalized) {
    return null;
  }

  if (!SUPPORTED_PUSH_LANGUAGES.includes(normalized as SupportedPushLanguage)) {
    return null;
  }

  return normalized as SupportedPushLanguage;
}

export function normalizeSupportedPushLanguage(
  value: string | null | undefined
): SupportedPushLanguage {
  return parseSupportedPushLanguage(value) ?? DEFAULT_PUSH_LANGUAGE;
}

export function pushLocalizationFor(languageCode: SupportedPushLanguage): PushLocalization {
  const templates = PUSH_LOCALIZATION[languageCode] ?? EN_LOCALIZATION;

  return {
    languageCode,
    localeTag: templates.localeTag,
    municipalityLabel: templates.municipalityLabel,
    heatWarningTitle: templates.heatWarningTitle,
    buildHeatBody: (name: string, level: number) =>
      formatTemplate(templates.heatBodyTemplate, { name, level }),
    formatTodayRange: (startClock: string, endClock: string) =>
      formatTemplate(templates.todayRangeTemplate, { start: startClock, end: endClock }),
    formatValidRange: (startText: string, endText: string) =>
      formatTemplate(templates.validRangeTemplate, { start: startText, end: endText }),
    formatTodayFrom: (startClock: string) =>
      formatTemplate(templates.todayFromTemplate, { start: startClock }),
    formatFrom: (startText: string) => formatTemplate(templates.fromTemplate, { start: startText }),
    formatTodayUntil: (endClock: string) =>
      formatTemplate(templates.todayUntilTemplate, { end: endClock }),
    formatUntil: (endText: string) => formatTemplate(templates.untilTemplate, { end: endText }),
    formatTimeWindowChanged: (previousText: string, currentText: string) =>
      formatTemplate(templates.timeWindowChangedTemplate, {
        previous: previousText,
        current: currentText,
      }),
    formatTimeWindowUpdated: (currentText: string) =>
      formatTemplate(templates.timeWindowUpdatedTemplate, { current: currentText }),
    defaultTopicTestTitle: `Test: ${templates.heatWarningTitle}`,
    defaultTopicTestBody: templates.manualTestTopicBody,
    defaultTokenTestTitle: `Test: ${templates.heatWarningTitle} (Token)`,
    defaultTokenTestBody: templates.manualTestTokenBody,
  };
}
