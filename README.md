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
  supabase/migrations/             Datenbankschema und Seed-Stellplaetze
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

Die App verwendet lokale Beispieldaten als Fallback. Buchungen können bereits
über ein Repository geladen und gespeichert werden; ohne Supabase-Konfiguration
bleiben sie lokal und werden beim Neustart verworfen. Bestellungen, Artikel,
Notizen und Termine werden als nächste Repositories angeschlossen.

Das zentrale Referenzdatum fuer die aktuelle Demo-/Betriebsansicht liegt in
`lib/core/camping_dates.dart`. Dort werden Betriebsdatum, Standard-Anreise,
Standard-Abreise und Kalenderwochenstart verwaltet.

## Gemeinsame Datenbank

Die Zielarchitektur verwendet Supabase als gemeinsame PostgreSQL-Datenbank.
Es gibt keine sichtbare Login-Seite; die App startet direkt im Dashboard.
Die Projekt-URL und der anon key werden zur Laufzeit ueber Dart-Defines
bereitgestellt und nicht im Repository gespeichert.

Beispiel fuer einen lokalen Start mit aktivierter Datenbank:

```text
flutter run --dart-define=SUPABASE_URL=https://<projekt>.supabase.co --dart-define=SUPABASE_ANON_KEY=<anon-key>
```

Ohne diese Defines bleibt die App im lokalen Beispieldatenmodus. Mit den
Defines versucht die App beim Start, Buchungen über Supabase zu laden; bei
fehlender Verbindung bleibt der lokale Fallback aktiv.

Die erste Migration liegt unter
`supabase/migrations/202609110001_initial_schema.sql`. Sie legt Stellplaetze,
Buchungen, Artikel, Bestellungen, Notizen, Termine und Rechnungen an und
aktiviert Row Level Security. Es werden absichtlich noch keine offenen anon-
Schreibrechte vergeben. Fuer den Betrieb ohne sichtbare Anmeldung wird ein
geschuetzter Server- oder Edge-Function-Zugriff benoetigt.

Die Repository-Schicht liegt unter `lib/services/`. Fuer Buchungen gibt es
bereits eine lokale In-Memory-Implementierung und eine Supabase-Implementierung.

Der Lageplan liegt unter `assets/Lageplan.jpg` und ist in `pubspec.yaml` als
Flutter-Asset registriert. Die Stellplatznummern werden als anklickbare
Overlays ueber dem Bild dargestellt.

## Integrationen

Feratel und HelloCash sind über eigene Gateway-Interfaces vorbereitet. Der aktuelle Stand erzeugt Export-Mocks und verändert keine externen Systeme. Für echte Anbindungen werden Anbieter-Dokumentation, Zugangsdaten, Pflichtfeldmapping und eine Testumgebung benötigt.

## QR-Bestellungen

Die Betreiber-App erzeugt pro Stellplatz einen Bestelllink und QR-Code. Die öffentliche Gast-Webansicht und die serverseitige Tokenprüfung sind noch nicht implementiert.

Fuer die QR-Darstellung wird `qr_flutter` verwendet. Nach Aenderungen an den
Abhaengigkeiten muessen die Pakete lokal mit `flutter pub get` aufgeloest
werden.

## Verifikation

Die Funktionalität wird aktuell manuell in der Flutter-App geprüft. Automatisierte Tests und blockierte CLI-Formatierungs-/Analysebefehle sind bewusst nicht Teil dieses Arbeitsablaufs.
