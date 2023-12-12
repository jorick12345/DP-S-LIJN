-- ------------------------------------------------------------------------
-- Data & Persistency
-- Opdracht S4: Advanced SQL
--
-- (c) 2020 Hogeschool Utrecht
-- Tijmen Muller (tijmen.muller@hu.nl)
-- André Donk (andre.donk@hu.nl)
-- 
--
-- Opdracht: schrijf SQL-queries om onderstaande resultaten op te vragen,
-- aan te maken, verwijderen of aan te passen in de database van de
-- bedrijfscasus.
--
-- Codeer je uitwerking onder de regel 'DROP VIEW ...' (bij een SELECT)
-- of boven de regel 'ON CONFLICT DO NOTHING;' (bij een INSERT)
-- Je kunt deze eigen query selecteren en los uitvoeren, en wijzigen tot
-- je tevreden bent.

-- Vervolgens kun je je uitwerkingen testen door de testregels
-- (met [TEST] erachter) te activeren (haal hiervoor de commentaartekens
-- weg) en vervolgens het hele bestand uit te voeren. Hiervoor moet je de
-- testsuite in de database hebben geladen (bedrijf_postgresql_test.sql).
-- NB: niet alle opdrachten hebben testregels.
--
-- Lever je werk pas in op Canvas als alle tests slagen.
-- ------------------------------------------------------------------------


-- S4.1. 
-- Geef nummer, functie en geboortedatum van alle medewerkers die vóór 1980
-- geboren zijn, en trainer of verkoper zijn.
DROP VIEW IF EXISTS s4_1; CREATE OR REPLACE VIEW s4_1 AS                                                     -- [TEST]
select mnr, functie, gbdatum from medewerkers where (functie = 'TRAINER' or functie = 'VERKOPER') and gbdatum < '1980-01-01';

-- S4.2. 
-- Geef de naam van de medewerkers met een tussenvoegsel (b.v. 'van der').
DROP VIEW IF EXISTS s4_2; CREATE OR REPLACE VIEW s4_2 AS                                                     -- [TEST]
select naam from medewerkers where naam like '% %';

-- S4.3. 
-- Geef nu code, begindatum en aantal inschrijvingen (`aantal_inschrijvingen`) van alle
-- cursusuitvoeringen in 2019 met minstens drie inschrijvingen.
DROP VIEW IF EXISTS s4_3; CREATE OR REPLACE VIEW s4_3 AS                                                     -- [TEST]
select cursus, begindatum, COUNT(cursus) AS aantal_inschrijvingen
from inschrijvingen
WHERE begindatum BETWEEN '2019-01-01' AND '2019-12-31'
GROUP BY cursus, begindatum
HAVING COUNT(cursus) >= 3;


-- S4.4. 
-- Welke medewerkers hebben een bepaalde cursus meer dan één keer gevolgd?
-- Geef medewerkernummer en cursuscode.
DROP VIEW IF EXISTS s4_4; CREATE OR REPLACE VIEW s4_4 AS                                                     -- [TEST]
select mnr,cursus from medewerkers join inschrijvingen ON inschrijvingen.cursist = medewerkers.mnr
group by mnr,cursus having count(cursus) > 1;

-- S4.5. 
-- Hoeveel uitvoeringen (`aantal`) zijn er gepland per cursus?
-- Een voorbeeld van het mogelijke resultaat staat hieronder.
--
--   cursus | aantal   
--  --------+-----------
--   ERM    | 1 
--   JAV    | 4 
--   OAG    | 2 
DROP VIEW IF EXISTS s4_5; CREATE OR REPLACE VIEW s4_5 AS                                                     -- [TEST]
select c.code as cursus,count(u.cursus) as aantal from cursussen c join uitvoeringen u ON u.cursus = c.code
group by c.code,u.cursus having count(u.cursus)>0;

-- S4.6. 
-- Bepaal hoeveel jaar leeftijdsverschil er zit tussen de oudste en de 
-- jongste medewerker (`verschil`) en bepaal de gemiddelde leeftijd van
-- de medewerkers (`gemiddeld`).
-- Je mag hierbij aannemen dat elk jaar 365 dagen heeft.
DROP VIEW IF EXISTS s4_6; CREATE OR REPLACE VIEW s4_6 AS                                                     -- [TEST]
select extract(year from current_date) - avg(extract(year from gbdatum)) as gemiddeld,
       (max(gbdatum)::date-min(gbdatum)::date)/365 as verschil from medewerkers;

-- S4.7. 
-- Geef van het hele bedrijf een overzicht van het aantal medewerkers dat
-- er werkt (`aantal_medewerkers`), de gemiddelde commissie die ze
-- krijgen (`commissie_medewerkers`), en hoeveel dat gemiddeld
-- per verkoper is (`commissie_verkopers`).
DROP VIEW IF EXISTS s4_7; CREATE OR REPLACE VIEW s4_7 AS                                                     -- [TEST]
select count(mnr) as aantal_medewerkers, sum(m.comm)/count(mnr)
                  as commissie_medewerkers, avg(m.comm) as commissie_verkopers from medewerkers m;


-- -------------------------[ HU TESTRAAMWERK ]--------------------------------
-- Met onderstaande query kun je je code testen. Zie bovenaan dit bestand
-- voor uitleg.

SELECT * FROM test_select('S4.1') AS resultaat
UNION
SELECT * FROM test_select('S4.2') AS resultaat
UNION
SELECT * FROM test_select('S4.3') AS resultaat
UNION
SELECT * FROM test_select('S4.4') AS resultaat
UNION
SELECT * FROM test_select('S4.5') AS resultaat
UNION
SELECT 'S4.6 wordt niet getest: geen test mogelijk.' AS resultaat
UNION
SELECT * FROM test_select('S4.7') AS resultaat
ORDER BY resultaat;


