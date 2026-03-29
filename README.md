<table align="center" cellspacing="0" cellpadding="10">
  <tr>
    <td align="center" style="border: 1px solid #ffffff;">
      <a href="https://apps.apple.com/at/app/hitze-v/id6760189444">
        <img src="assets/store-badges/app-store.svg" alt="Laden im App Store" width="190" height="64">
      </a>
    </td>
    <td align="center" style="border: 1px solid #ffffff;">
      <a href="https://play.google.com/store/apps/details?id=org.entner.HitzeV">
        <img src="assets/store-badges/google-play.svg" alt="Jetzt bei Google Play" width="190" height="64">
      </a>
    </td>
  </tr>
</table>

# Hitze-V

Hitze-V ist eine App für die Beobachtung von Hitzebelastung und natürlicher UV-Strahlung bei Arbeiten im Freien in Österreich. Sie greift zentrale Themen der Hitzeschutzverordnung auf und hilft dabei, aktuelle Hitzewarnungen, UV-Belastung und standortbezogene Entwicklungen übersichtlich im Blick zu behalten.

## Was die App macht

Die Hitzeschutzverordnung stellt die Ermittlung und Beurteilung von Gefahren, den Zugang zu aktueller Hitzewarnung und UV-Index sowie die rechtzeitige Planung von Schutzmaßnahmen in den Mittelpunkt. Genau dabei unterstützt Hitze-V im Alltag.

Mit Hitze-V kannst du Arbeitsorte speichern und für jeden Standort die aktuelle Hitzelage abrufen. Zusätzlich zeigt dir die App den UV-Index, die gefühlte Temperatur und eine praktische Vorschau für die nächsten vier Tage.

Wenn sich die Warnlage in einer betroffenen Gemeinde verändert, informiert dich Hitze-V auf Wunsch per Push-Benachrichtigung. So musst du nicht ständig selbst nachsehen und bleibst trotzdem aufmerksam informiert.

## Warum Hitze-V hilfreich ist

Gerade bei Arbeiten im Freien können Hitze und natürliche UV-Strahlung zu einer ernsthaften Belastung werden. Die Arbeitsinspektion weist unter anderem auf Risiken wie Kreislaufprobleme, Kopfschmerzen, Erschöpfung, Sonnenbrand oder Augenschäden hin. Hitze-V unterstützt dabei, Entwicklungen früh zu erkennen, Risiken besser einzuschätzen und Schutzmaßnahmen vorausschauend einzuplanen.

Die App macht wichtige Informationen leicht verständlich, klar sichtbar und unkompliziert zugänglich. Statt lange nach Daten zu suchen, bekommst du einen ruhigen, verlässlichen Überblick direkt auf dein Smartphone.

Hitze-V orientiert sich am Thema Hitzeschutz bei Arbeiten im Freien. Mehr Informationen zur kommentierten Hitzeschutzverordnung findest du auf der Seite der Arbeitsinspektion: [Kommentierte Hitze-V](https://www.arbeitsinspektion.gv.at/Arbeitsstaetten-_Arbeitsplaetze/Arbeitsstaetten-_Arbeitsplaetze/kommentrierte-Hitze-V.html).

Wichtig ist auch: Die Hitzeschutzverordnung betont die Gefahrenbeurteilung, passende Schutzmaßnahmen und gute Vorbereitung im Arbeitsalltag. Wenn GeoSphere Austria eine Hitzewarnung mindestens der Stufe 2, also gelb, ausweist, müssen Maßnahmen zum Hitze- und UV-Schutz umgesetzt werden. Hitze-V unterstützt bei diesem Überblick, ersetzt aber keine betriebliche Evaluierung oder verbindliche Schutzmaßnahmen vor Ort.

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
