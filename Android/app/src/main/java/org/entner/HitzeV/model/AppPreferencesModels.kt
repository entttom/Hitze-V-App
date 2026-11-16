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

    fun resolvedLanguage(locale: Locale = Locale.getDefault()): ResolvedLanguage =
        if (this == SYSTEM) {
            ResolvedLanguage.fromCode(locale.language) ?: ResolvedLanguage.EN
        } else {
            ResolvedLanguage.fromCode(rawValue) ?: ResolvedLanguage.EN
        }

    /** BCP-47 tag used for the per-app locale; null means "follow the system". */
    val localeTag: String?
        get() = if (this == SYSTEM) null else resolvedLanguage().localeTag

    companion object {
        fun fromRawValue(value: String?): AppLanguage = entries.firstOrNull { it.rawValue == value } ?: SYSTEM

        fun fromLocale(locale: Locale?): AppLanguage {
            val code = locale?.language?.lowercase(Locale.ROOT) ?: return SYSTEM
            return entries.firstOrNull { it != SYSTEM && it.rawValue == code } ?: SYSTEM
        }
    }
}

enum class ResolvedLanguage(val code: String, val localeTag: String) {
    DE("de", "de-AT"),
    BG("bg", "bg-BG"),
    DA("da", "da-DK"),
    EN("en", "en-US"),
    ET("et", "et-EE"),
    FI("fi", "fi-FI"),
    FR("fr", "fr-FR"),
    EL("el", "el-GR"),
    GA("ga", "ga-IE"),
    IT("it", "it-IT"),
    HR("hr", "hr-HR"),
    LV("lv", "lv-LV"),
    LT("lt", "lt-LT"),
    MT("mt", "mt-MT"),
    NL("nl", "nl-NL"),
    PL("pl", "pl-PL"),
    PT("pt", "pt-PT"),
    RO("ro", "ro-RO"),
    SV("sv", "sv-SE"),
    SK("sk", "sk-SK"),
    SL("sl", "sl-SI"),
    ES("es", "es-ES"),
    CS("cs", "cs-CZ"),
    HU("hu", "hu-HU"),
    TR("tr", "tr-TR");

    val locale: Locale
        get() = Locale.forLanguageTag(localeTag)

    companion object {
        fun fromCode(code: String?): ResolvedLanguage? {
            val normalized = code?.trim()?.lowercase(Locale.ROOT) ?: return null
            return entries.firstOrNull { it.code == normalized }
        }
    }
}
