package org.entner.HitzeV.model

import java.util.Locale

enum class AppTheme(val rawValue: String) {
    SYSTEM("system"),
    LIGHT("light"),
    DARK("dark");

    companion object {
        fun fromRawValue(value: String?): AppTheme = entries.firstOrNull { it.rawValue == value } ?: SYSTEM
    }
}

enum class AppLanguage(val rawValue: String) {
    SYSTEM("system"),
    BG("bg"),
    DA("da"),
    DE("de"),
    EN("en"),
    ET("et"),
    FI("fi"),
    FR("fr"),
    EL("el"),
    GA("ga"),
    IT("it"),
    HR("hr"),
    LV("lv"),
    LT("lt"),
    MT("mt"),
    NL("nl"),
    PL("pl"),
    PT("pt"),
    RO("ro"),
    SV("sv"),
    SK("sk"),
    SL("sl"),
    ES("es"),
    CS("cs"),
    HU("hu"),
    TR("tr");

    fun resolvedLanguage(locale: Locale = Locale.getDefault()): ResolvedLanguage = when (this) {
        DE -> ResolvedLanguage.DE
        BG -> ResolvedLanguage.BG
        DA -> ResolvedLanguage.DA
        EN -> ResolvedLanguage.EN
        ET -> ResolvedLanguage.ET
        FI -> ResolvedLanguage.FI
        FR -> ResolvedLanguage.FR
        EL -> ResolvedLanguage.EL
        GA -> ResolvedLanguage.GA
        IT -> ResolvedLanguage.IT
        HR -> ResolvedLanguage.HR
        LV -> ResolvedLanguage.LV
        LT -> ResolvedLanguage.LT
        MT -> ResolvedLanguage.MT
        NL -> ResolvedLanguage.NL
        PL -> ResolvedLanguage.PL
        PT -> ResolvedLanguage.PT
        RO -> ResolvedLanguage.RO
        SV -> ResolvedLanguage.SV
        SK -> ResolvedLanguage.SK
        SL -> ResolvedLanguage.SL
        ES -> ResolvedLanguage.ES
        CS -> ResolvedLanguage.CS
        HU -> ResolvedLanguage.HU
        TR -> ResolvedLanguage.TR
        SYSTEM -> when (locale.language.lowercase(Locale.ROOT)) {
            "de" -> ResolvedLanguage.DE
            "bg" -> ResolvedLanguage.BG
            "da" -> ResolvedLanguage.DA
            "en" -> ResolvedLanguage.EN
            "et" -> ResolvedLanguage.ET
            "fi" -> ResolvedLanguage.FI
            "fr" -> ResolvedLanguage.FR
            "el" -> ResolvedLanguage.EL
            "ga" -> ResolvedLanguage.GA
            "it" -> ResolvedLanguage.IT
            "hr" -> ResolvedLanguage.HR
            "lv" -> ResolvedLanguage.LV
            "lt" -> ResolvedLanguage.LT
            "mt" -> ResolvedLanguage.MT
            "nl" -> ResolvedLanguage.NL
            "pl" -> ResolvedLanguage.PL
            "pt" -> ResolvedLanguage.PT
            "ro" -> ResolvedLanguage.RO
            "sv" -> ResolvedLanguage.SV
            "sk" -> ResolvedLanguage.SK
            "sl" -> ResolvedLanguage.SL
            "es" -> ResolvedLanguage.ES
            "cs" -> ResolvedLanguage.CS
            "hu" -> ResolvedLanguage.HU
            "tr" -> ResolvedLanguage.TR
            else -> ResolvedLanguage.EN
        }
    }

    companion object {
        fun fromRawValue(value: String?): AppLanguage = entries.firstOrNull { it.rawValue == value } ?: SYSTEM
    }
}

enum class ResolvedLanguage {
    DE,
    BG,
    DA,
    EN,
    ET,
    FI,
    FR,
    EL,
    GA,
    IT,
    HR,
    LV,
    LT,
    MT,
    NL,
    PL,
    PT,
    RO,
    SV,
    SK,
    SL,
    ES,
    CS,
    HU,
    TR
}
