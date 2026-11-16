package org.entner.HitzeV.ui

import androidx.appcompat.app.AppCompatDelegate
import androidx.core.os.LocaleListCompat
import org.entner.HitzeV.model.AppLanguage

/** Per-app locale (AppCompat / Android 13 app languages) as the single source of truth for the UI language. */
object AppLocales {
    fun current(): AppLanguage {
        val locales = AppCompatDelegate.getApplicationLocales()
        return if (locales.isEmpty) AppLanguage.SYSTEM else AppLanguage.fromLocale(locales[0])
    }

    fun apply(language: AppLanguage) {
        val tag = language.localeTag
        val locales = if (tag == null) LocaleListCompat.getEmptyLocaleList() else LocaleListCompat.forLanguageTags(tag)
        if (AppCompatDelegate.getApplicationLocales().toLanguageTags() != locales.toLanguageTags()) {
            AppCompatDelegate.setApplicationLocales(locales)
        }
    }
}
