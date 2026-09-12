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
Es gibt keine sichtbare Login-Seite; die App startet direkt im Dashboard und
erzeugt intern eine Supabase-Anonymous-Session.
Die Projekt-URL und der anon key werden zur Laufzeit ueber Dart-Defines
bereitgestellt und nicht im Repository gespeichert.

Beispiel fuer einen lokalen Start mit aktivierter Datenbank:

```text
flutter run --dart-define=SUPABASE_URL=https://<projekt>.supabase.co --dart-define=SUPABASE_ANON_KEY=<anon-key>
```

### Supabase-Ersteinrichtung

1. Neues Supabase-Projekt erstellen.
2. Unter Authentication den Provider `Anonymous Sign-Ins` aktivieren.
3. Den kompletten Inhalt von `supabase/schema.sql` im SQL Editor ausfuehren.
4. Projekt-URL und anon key aus den Supabase Project Settings verwenden.
5. App mit den beiden Dart-Defines starten.
6. Eine Buchung anlegen und anschliessend auf einem zweiten Geraet pruefen,
   ob dieselbe Buchung geladen wird.

Der Service Role Key darf niemals in die Flutter-App oder in ein Repository
eingecheckt werden. In der App wird nur der oeffentliche anon key verwendet;
der Zugriff wird ueber Anonymous Auth und Row-Level Security begrenzt.

Ohne diese Defines bleibt die App im lokalen Beispieldatenmodus. Mit den
Defines versucht die App beim Start, Buchungen über Supabase zu laden; bei
fehlender Verbindung bleibt der lokale Fallback aktiv.

Die Repository-Schicht liegt unter `lib/services/`. Fuer Buchungen, Artikel,
Bestellungen, Aufenthaltsnotizen, Stellplaetze, Kalendertermine und Aufgaben
gibt es lokale In-Memory-Fallbacks sowie Supabase-Implementierungen.

Sammelbestellungen werden im UI als `OrderBatch` mit mehreren Positionen
modelliert. Die aktuelle Repository-Kompatibilität speichert die Positionen
noch als einzelne `orders`-Zeilen; die Tabellen `order_groups` und
`order_items` sind fuer die naechste Supabase-Migrationsstufe vorbereitet.

Fuer ein neues Supabase-Projekt wird nur die zusammengefuehrte Datei
`supabase/schema.sql` im SQL Editor ausgefuehrt. Sie enthaelt Tabellen,
Stellplatz-Seed, Trigger, Doppelbuchungsschutz, Row-Level-Security und Policies
fuer Anonymous-Sessions.

Die Dateien unter `supabase/migrations/` bleiben als Entwicklungshistorie
erhalten. Sie muessen bei einer komplett neuen Datenbank nicht zusaetzlich
ausgefuehrt werden. Im Supabase-Dashboard muss Anonymous Sign-In aktiviert
werden; die App zeigt dabei keine Anmeldung an.

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
