<table align="center">
  <tr>
    <td align="center">
      <a href="https://apps.apple.com/at/app/hitze-v/id6760189444">
        <img src="https://tools.applemediaservices.com/api/badges/download-on-the-app-store/black/en-us?size=250x83" alt="Download on the App Store" width="190" height="64">
      </a>
    </td>
    <td align="center">
      <a href="https://play.google.com/store/apps/details?id=org.entner.HitzeV">
        <img src="https://play.google.com/intl/en_us/badges/images/generic/en_badge_web_generic.png" alt="Get it on Google Play" width="190" height="64">
      </a>
    </td>
  </tr>
</table>

# Hitze-V

Hitze-V ist eine liebevoll gestaltete App für alle, die Hitze an Arbeitsorten in Österreich rechtzeitig im Blick behalten möchten. Sie hilft dabei, wichtige Wetter- und Warninformationen übersichtlich an einem Ort zu sehen, damit gute Entscheidungen im Alltag einfacher werden.

## Was die App macht

Mit Hitze-V kannst du Arbeitsorte speichern und für jeden Standort die aktuelle Hitzelage abrufen. Zusätzlich zeigt dir die App den UV-Index, die gefühlte Temperatur und eine praktische Vorschau für die nächsten vier Tage.

Wenn sich die Warnlage in einer betroffenen Gemeinde verändert, informiert dich Hitze-V auf Wunsch per Push-Benachrichtigung. So musst du nicht ständig selbst nachsehen und bleibst trotzdem aufmerksam informiert.

## Warum Hitze-V hilfreich ist

Gerade bei Arbeiten im Freien kann Hitze schnell zur Belastung werden. Hitze-V unterstützt dich dabei, Entwicklungen früh zu erkennen, Risiken besser einzuschätzen und den Tag vorausschauender zu planen.

Die App macht wichtige Informationen leicht verständlich, klar sichtbar und unkompliziert zugänglich. Statt lange nach Daten zu suchen, bekommst du einen ruhigen, verlässlichen Überblick direkt auf dein Smartphone.

## Für wen die App gedacht ist

Hitze-V ist für Menschen gedacht, die bei ihrer Arbeit mit Sonne, Wärme und hoher Belastung zu tun haben. Dazu gehören zum Beispiel Beschäftigte im Freien, Teams auf wechselnden Arbeitsorten, Verantwortliche in der Planung und alle, die auf einen schnellen Überblick über Hitze und UV-Belastung angewiesen sind.

Kurz gesagt: für alle, die bei warmem Wetter lieber gut vorbereitet sind.

## Jetzt herunterladen

Du kannst Hitze-V direkt für iPhone oder Android herunterladen und sofort nutzen. Verwende einfach die Store-Badges ganz oben in dieser README, um zur passenden Download-Seite zu gelangen.

Bleib aufmerksam, bleib gut vorbereitet und lass dich von Hitze-V zuverlässig durch heiße Tage begleiten.

## Kurz für Entwickler:innen

Dieses Repository enthält die nativen Apps für Android und iOS sowie ein separates Backend für Warnlogik und Push-Benachrichtigungen.

- `Android/`: Android-App mit Kotlin und Jetpack Compose
- `iOS/Hitze-V/`: iOS-App mit SwiftUI
- `backend/`: Node.js-/TypeScript-Service für Warnungsabfrage, Verarbeitung und Push-Versand

Für einen lokalen Start werden je nach Plattform Firebase-Konfigurationen sowie für das Backend zusätzlich Node.js, `npm` und Redis benötigt.

Ausführlichere technische Hinweise findest du in [backend/README.md](/Users/thomasentner/Github/Hitze-V-App/backend/README.md).
