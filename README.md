# Peterbauer Camping

Flutter-App fuer den Betreiberalltag am Campingplatz.

## Aktueller Umfang

- Dashboard mit Ankuenften, Abreisen und Auslastung
- Buchungen mit Kalenderwoche, Suche, Bearbeiten und Loeschen
- Gastdaten: Name, Adresse, Geburtsdatum, Telefon, Personen und Hund
- Fahrzeugarten: Wohnmobil, Auto/Van, Zelt und Auto mit Anhaenger
- Interaktiver Platzplan fuer die Stellplaetze 1 bis 26
- Frei waehlbare Stellplatzfarben
- Aufenthalte mit Stromstatus, Notizen und Bestellungen
- Artikelkatalog mit Kategorien, Preisen, Bearbeiten und Loeschen
- Taegliche Bestellliste mit Mengenaggregation
- Abreise mit Rechnungspositionen und Zahlungsarten
- Statistik nach Tag, Monat und Jahr
- Fahrzeugstatistik und CSV-Daten zum Kopieren
- Interner Kalender mit Kategorien, Wiederholungen, Bearbeiten und Loeschen
- QR-Code und kopierbarer Gast-Bestelllink pro Stellplatz

## Projektstruktur

```text
lib/
  app.dart                         App-Shell und Theme
  core/                            Zentrale Betriebsdaten und Konfiguration
  models/                          Fachmodelle
  services/                        Geschaeftslogik, z. B. Rechnungsaufbau
  integrations/                    Feratel- und HelloCash-Adapter
  features/
    shell/                         Navigation und gemeinsamer Zustand
    bookings/                      Buchungen und Gastdaten
    site_map/                      Interaktiver Platzplan
    stays/                         Aufenthalt, Notizen und Bestellungen
    checkout/                      Abreise und Abrechnung
    tasks/                         Aufgaben und Einkauf
    statistics/                     Auswertungen und CSV-Kopie
    calendar/                      Interne Termine
  shared/widgets/                  Wiederverwendbare UI-Bausteine
```

## Aktueller Datenstand

Die App verwendet derzeit lokale Beispieldaten und lokalen Sitzungszustand. Beim Neustart werden die Daten nicht dauerhaft gespeichert. Ein Backend mit Authentifizierung, Persistenz und Synchronisation ist der nächste technische Ausbauschritt.

Das zentrale Referenzdatum fuer die aktuelle Demo-/Betriebsansicht liegt in
`lib/core/camping_dates.dart`. Dort werden Betriebsdatum, Standard-Anreise,
Standard-Abreise und Kalenderwochenstart verwaltet.

## Integrationen

Feratel und HelloCash sind über eigene Gateway-Interfaces vorbereitet. Der aktuelle Stand erzeugt Export-Mocks und verändert keine externen Systeme. Für echte Anbindungen werden Anbieter-Dokumentation, Zugangsdaten, Pflichtfeldmapping und eine Testumgebung benötigt.

## QR-Bestellungen

Die Betreiber-App erzeugt pro Stellplatz einen Bestelllink und QR-Code. Die öffentliche Gast-Webansicht und die serverseitige Tokenprüfung sind noch nicht implementiert.

Fuer die QR-Darstellung wird `qr_flutter` verwendet. Nach Aenderungen an den
Abhaengigkeiten muessen die Pakete lokal mit `flutter pub get` aufgeloest
werden.

## Verifikation

Die Funktionalität wird aktuell manuell in der Flutter-App geprüft. Automatisierte Tests und blockierte CLI-Formatierungs-/Analysebefehle sind bewusst nicht Teil dieses Arbeitsablaufs.
