-- ═══════════════════════════════════════════════════════════════
-- BESTELLSYSTEM — Supabase SQL Migration
-- Ausführen in: Supabase Dashboard → SQL Editor
-- ═══════════════════════════════════════════════════════════════

-- 1. ARTIKEL-TABELLE
CREATE TABLE IF NOT EXISTS bestell_artikel (
  id            uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  kategorie     text NOT NULL CHECK (kategorie IN ('labor', 'praxis', 'sprechstunde')),
  gruppe        text NOT NULL,
  name          text NOT NULL,
  artikelnummer text DEFAULT '',
  einheit       text DEFAULT 'Stück',
  farbe         text DEFAULT '',
  aktiv         boolean DEFAULT true,
  sort_order    int DEFAULT 0,
  erstellt_am   timestamptz DEFAULT now()
);

-- 2. BESTELLUNGEN
CREATE TABLE IF NOT EXISTS bestell_auftraege (
  id               uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  status           text NOT NULL DEFAULT 'aktuell'
                   CHECK (status IN ('aktuell', 'bestellt', 'abgeschlossen')),
  erstellt_von     text NOT NULL,
  erstellt_am      timestamptz DEFAULT now(),
  bestellt_von     text,
  bestellt_am      timestamptz,
  abgeschlossen_von text,
  abgeschlossen_am  timestamptz,
  notiz            text DEFAULT ''
);

-- 3. POSITIONEN
CREATE TABLE IF NOT EXISTS bestell_positionen (
  id            uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  auftrag_id    uuid NOT NULL REFERENCES bestell_auftraege(id) ON DELETE CASCADE,
  artikel_id    uuid REFERENCES bestell_artikel(id) ON DELETE SET NULL,
  kategorie     text NOT NULL,
  gruppe        text NOT NULL,
  name          text NOT NULL,
  artikelnummer text DEFAULT '',
  einheit       text DEFAULT 'Stück',
  menge         int NOT NULL DEFAULT 1 CHECK (menge > 0),
  erhalten      boolean DEFAULT false,
  erhalten_von  text,
  erhalten_am   timestamptz
);

-- 4. ZUGANG (wer darf das Bestellsystem nutzen)
CREATE TABLE IF NOT EXISTS bestell_zugang (
  email       text PRIMARY KEY,
  anzeigename text NOT NULL,
  kuerzel     text NOT NULL,
  aktiv       boolean DEFAULT true
);

-- ── RLS ─────────────────────────────────────────────────────────
ALTER TABLE bestell_artikel    ENABLE ROW LEVEL SECURITY;
ALTER TABLE bestell_auftraege  ENABLE ROW LEVEL SECURITY;
ALTER TABLE bestell_positionen ENABLE ROW LEVEL SECURITY;
ALTER TABLE bestell_zugang     ENABLE ROW LEVEL SECURITY;

-- Nur eingeloggte User dürfen zugreifen
CREATE POLICY "bestell_artikel_auth"    ON bestell_artikel    FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "bestell_auftraege_auth"  ON bestell_auftraege  FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "bestell_positionen_auth" ON bestell_positionen FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "bestell_zugang_auth"     ON bestell_zugang     FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- ── ZUGANG-DATEN ─────────────────────────────────────────────────
INSERT INTO bestell_zugang (email, anzeigename, kuerzel) VALUES
  ('nele@praxis.intern',  'Nele',  'NH'),
  ('lisa@praxis.intern',  'Lisa',  'LK'),
  ('silke@praxis.intern', 'Silke', 'SK'),
  ('edda@praxis.intern',  'Edda',  'ED')
ON CONFLICT (email) DO NOTHING;

-- ── NEUE USER ANLEGEN (Supabase Auth) ────────────────────────────
-- Für Silke und Edda müssen neue Auth-User angelegt werden:
-- Dashboard → Authentication → Users → „Add user"
--   silke@praxis.intern   PIN (6-stellig) als Passwort setzen
--   edda@praxis.intern    PIN (6-stellig) als Passwort setzen
-- Nele (nele@praxis.intern) und Lisa (lisa@praxis.intern) existieren bereits.

-- ── BEISPIEL-ARTIKEL (Labor — Sarstedt MLR) ──────────────────────
-- Wird nach Erhalt der markierten Bestellscheine vervollständigt.

INSERT INTO bestell_artikel (kategorie, gruppe, name, artikelnummer, einheit, farbe, sort_order) VALUES
  -- Sarstedt Monovetten
  ('labor', 'Blutentnahmeröhrchen Sarstedt', 'Serum 2,7ml',          '05.1557.001', '50 Stück',  'weiß',     10),
  ('labor', 'Blutentnahmeröhrchen Sarstedt', 'Serum 5,5ml',          '03.1397',     '50 Stück',  'weiß',     11),
  ('labor', 'Blutentnahmeröhrchen Sarstedt', 'Serum 7,5ml',          '01.1601',     '50 Stück',  'weiß',     12),
  ('labor', 'Blutentnahmeröhrchen Sarstedt', 'Edta 1,6ml',           '05.1081.001', '50 Stück',  'rot',      13),
  ('labor', 'Blutentnahmeröhrchen Sarstedt', 'Edta 2,7ml',           '05.1167',     '50 Stück',  'rot',      14),
  ('labor', 'Blutentnahmeröhrchen Sarstedt', 'Edta 4,9ml',           '04.1931',     '50 Stück',  'rot',      15),
  ('labor', 'Blutentnahmeröhrchen Sarstedt', 'Citrat 3ml',           '05.1165',     '50 Stück',  'grün',     16),
  ('labor', 'Blutentnahmeröhrchen Sarstedt', 'Fluorid 2,7ml',        '05.1073',     '50 Stück',  'gelb',     17),
  ('labor', 'Blutentnahmeröhrchen Sarstedt', 'Serum-Gel 7,5ml',      '01.1602',     '50 Stück',  'braun',    18),
  ('labor', 'Blutentnahmeröhrchen Sarstedt', 'Glucoexact 3,1ml',     '05.1074.001', '50 Stück',  'grau',     19),
  ('labor', 'Blutentnahmeröhrchen Sarstedt', 'Lithium-Heparin 9ml',  '02.1065',     '5 Stück',   'orange',   20),
  -- Kapillarblutentnahme
  ('labor', 'Kapillarblutentnahme', 'Microvette Edta 200μl',         '18.1321',     '100 Stück', 'rot',      30),
  ('labor', 'Kapillarblutentnahme', 'Microvette Edta 100μl',         '20.1278',     '100 Stück', 'malve',    31),
  ('labor', 'Kapillarblutentnahme', 'Microvette Serum 200μl',        '20.1290',     '100 Stück', 'weiß',     32),
  ('labor', 'Kapillarblutentnahme', 'Hämolysatgefäße HbA1C',         '0968780',     '100 Stück', 'weiß',     33),
  -- Kanülen Sarstedt
  ('labor', 'Kanülen Sarstedt', 'Kanüle gelb 20G 0,9x38mm',          '85.1160',     '100 Stück', 'gelb',     40),
  ('labor', 'Kanülen Sarstedt', 'Kanüle schwarz 22G 0,7x38mm',       '85.1440',     '100 Stück', 'schwarz',  41),
  ('labor', 'Kanülen Sarstedt', 'Kanüle grün 21G 0,8x38mm',          '85.1162',     '100 Stück', 'grün',     42),
  -- Kanülen Safety Sarstedt
  ('labor', 'Kanülen Safety Sarstedt', 'Safety gelb 20G 0,9x38mm',   '85.1160.200', '50 Stück',  'gelb',     50),
  ('labor', 'Kanülen Safety Sarstedt', 'Safety schwarz 22G 0,7x38mm','85.1440.200', '50 Stück',  'schwarz',  51),
  ('labor', 'Kanülen Safety Sarstedt', 'Safety grün 21G 0,8x38mm',   '85.1162.200', '50 Stück',  'grün',     52),
  -- Adapter
  ('labor', 'Adapter Sarstedt', 'Membran-Adapter',                    '14.1112',     '100 Stück', '',         60),
  ('labor', 'Adapter Sarstedt', 'Multi-Adapter',                      '14.1205',     '100 Stück', 'weiß',     61),
  -- Bakteriologie
  ('labor', 'Bakteriologie', 'Urinmonovette gelb 10ml',               '10.252',      '10 Stück',  'gelb',     70),
  ('labor', 'Bakteriologie', 'Urinröhrchen',                          'HB4502',      '20 Stück',  'gelb',     71),
  ('labor', 'Bakteriologie', 'Stuhlröhrchen',                         'HT8551',      '7 Stück',   'braun',    72),
  ('labor', 'Bakteriologie', 'Sputumröhrchen',                        'HT8104',      '7 Stück',   'transparent',73),
  ('labor', 'Bakteriologie', 'OC-Sensor/IFOBT',                       '28PZ26P1',    '20 Stück',  'weiß',     74),
  -- Kombibelege
  ('labor', 'Kombibelege', 'Hausärzte/Internisten',                   '',            '1 Packung', '',         80),
  ('labor', 'Kombibelege', 'Gynäkologie',                             '',            '1 Packung', '',         81),
  ('labor', 'Kombibelege', 'Mikrobiologie',                           '',            '1 Packung', '',         82),
  ('labor', 'Kombibelege', 'Pädiatrie',                               '',            '1 Packung', '',         83),
  -- Versand
  ('labor', 'Versandmaterial', 'Versandbeutel Probenmaterial',        '',            '1 Rolle',   '',         90),
  ('labor', 'Versandmaterial', 'Versandbeutel Mikrobiologie',         '',            '1 Rolle',   '',         91),
  ('labor', 'Versandmaterial', 'Versandbeutel Eilproben',             '',            '1 Rolle',   '',         92),
  ('labor', 'Versandmaterial', 'Befundportalkarten',                  '',            '1 Packung', '',         93)
ON CONFLICT DO NOTHING;

-- Praxisbedarf und Sprechstundenbedarf: nach Erhalt der markierten Listen befüllen
-- Beispiel-Struktur (jetzt noch leer):
-- INSERT INTO bestell_artikel (kategorie, gruppe, name, artikelnummer, einheit, sort_order) VALUES
--   ('praxis', 'Handschuhe', 'Latex-Handschuhe S', 'PZN-XXXXX', '100 Stück', 10),
--   ('sprechstunde', 'Verbandsmaterial', 'Pflaster 6x10cm', 'PZN-XXXXX', '50 Stück', 10);
