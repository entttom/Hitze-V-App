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
    DE("de"),
    EN("en");

    fun resolvedLanguage(locale: Locale = Locale.getDefault()): ResolvedLanguage = when (this) {
        DE -> ResolvedLanguage.DE
        EN -> ResolvedLanguage.EN
        SYSTEM -> if (locale.language.lowercase(Locale.ROOT).startsWith("de")) ResolvedLanguage.DE else ResolvedLanguage.EN
    }

    companion object {
        fun fromRawValue(value: String?): AppLanguage = entries.firstOrNull { it.rawValue == value } ?: SYSTEM
    }
}

enum class ResolvedLanguage {
    DE,
    EN
}
