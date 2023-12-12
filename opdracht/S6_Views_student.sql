-- ------------------------------------------------------------------------
-- Data & Persistency
-- Opdracht S6: Views
--
-- (c) 2020 Hogeschool Utrecht
-- Tijmen Muller (tijmen.muller@hu.nl)
-- André Donk (andre.donk@hu.nl)
-- ------------------------------------------------------------------------


-- S6.1.
--
-- 1. Maak een view met de naam "deelnemers" waarmee je de volgende gegevens uit de tabellen inschrijvingen en uitvoering combineert:
--    inschrijvingen.cursist, inschrijvingen.cursus, inschrijvingen.begindatum, uitvoeringen.docent, uitvoeringen.locatie
CREATE VIEW deelnemers AS
SELECT inschrijvingen.cursist, inschrijvingen.cursus, inschrijvingen.begindatum, uitvoeringen.docent, uitvoeringen.locatie
FROM inschrijvingen JOIN uitvoeringen on inschrijvingen.cursus = uitvoeringen.cursus;
-- 2. Gebruik de view in een query waarbij je de "deelnemers" view combineert met de "personeels" view (behandeld in de les):
--     CREATE OR REPLACE VIEW personeel AS
-- 	     SELECT mnr, voorl, naam as medewerker, afd, functie
--       FROM medewerkers;
SELECT p.mnr, p.voorl, p.medewerker, p.afd, p.functie, d.cursus, d.begindatum, d.docent, d.locatie
FROM personeel p
         JOIN deelnemers d ON p.mnr = d.cursist;

-- 3. Is de view "deelnemers" updatable ? Waarom ?
-- nee omdat de view een combinatie is van twee kolommen (door de join) word het een stuk complexer om hem te updaten


-- S6.2.
--
-- 1. Maak een view met de naam "dagcursussen". Deze view dient de gegevens op te halen: 
--      code, omschrijving en type uit de tabel curssussen met als voorwaarde dat de lengte = 1. Toon aan dat de view werkt.
create view dagcursussen as select code, omschrijving from cursussen where lengte = 1;
-- 2. Maak een tweede view met de naam "daguitvoeringen". 
--    Deze view dient de uitvoeringsgegevens op te halen voor de "dagcurssussen" (gebruik ook de view "dagcursussen"). Toon aan dat de view werkt\
CREATE OR REPLACE VIEW daguitvoeringen as select u.begindatum, u.docent ,u.locatie, dc.code, dc.omschrijving from uitvoeringen u join dagcursussen dc on u.cursus = dc.code;


-- 3. Verwijder de views en laat zien wat de verschillen zijn bij DROP view <viewnaam> CASCADE en bij DROP view <viewnaam> RESTRICT
-- drop view restrict verwijderd alleen de view als er niks aan afhankelijk is
-- en de drop view cascade verwijderd de view en ook alle andere objecten die afhankelijk zijn zoals een andere view
