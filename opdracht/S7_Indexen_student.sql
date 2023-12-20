-- ------------------------------------------------------------------------
-- Data & Persistency
-- Opdracht S7: Indexen
--
-- (c) 2020 Hogeschool Utrecht
-- Tijmen Muller (tijmen.muller@hu.nl)
-- André Donk (andre.donk@hu.nl)
-- ------------------------------------------------------------------------
-- LET OP, zoals in de opdracht op Canvas ook gezegd kun je informatie over
-- het query plan vinden op: https://www.postgresql.org/docs/current/using-explain.html


-- S7.1.
--
-- Je maakt alle opdrachten in de 'sales' database die je hebt aangemaakt en gevuld met
-- de aangeleverde data (zie de opdracht op Canvas).
--
-- Voer het voorbeeld uit wat in de les behandeld is:
-- 1. Voer het volgende EXPLAIN statement uit:
--    EXPLAIN SELECT * FROM order_lines WHERE stock_item_id = 9;
--    Bekijk of je het resultaat begrijpt. Kopieer het explain plan onderaan de opdracht
-- 2. Voeg een index op stock_item_id toe:
--    CREATE INDEX ord_lines_si_id_idx ON order_lines (stock_item_id);
-- 3. Analyseer opnieuw met EXPLAIN hoe de query nu uitgevoerd wordt
--    Kopieer het explain plan onderaan de opdracht
-- 4. Verklaar de verschillen. Schrijf deze hieronder op.
"Seq Scan on order_lines  (cost=0.00..39.61 rows=6 width=97)"
"  Filter: (stock_item_id = 9)"

"Bitmap Heap Scan on order_lines  (cost=4.32..19.21 rows=6 width=97)"
"  Recheck Cond: (stock_item_id = 9)"
"  ->  Bitmap Index Scan on ord_lines_si_id_idx  (cost=0.00..4.32 rows=6 width=0)"
"        Index Cond: (stock_item_id = 9)"

-- de verwachte kosten zijn 0 en de totale zijn 39.61 bij de sequentiele search dus uiteindelijk hoger dan de scan die
-- gebruik maakt van de bitmap index dit is logisch want de database is heel groot en de bitmap index search maakt gebruik van btree zoeken
-- dus er hoeven minder stappen worden gemaakt tijdens en zoeken waardoor hij sneller klaar is


-- S7.2.
--
-- 1. Maak de volgende twee query’s:
-- 	  A. Toon uit de order tabel de order met order_id = 73590
EXPLAIN SELECT * FROM orders WHERE order_id = 73590;
-- 	  B. Toon uit de order tabel de order met customer_id = 1028
EXPLAIN SELECT * FROM orders WHERE customer_id = 1028;
-- 2. Analyseer met EXPLAIN hoe de query’s uitgevoerd worden en kopieer het explain plan onderaan de opdracht
"Index Scan using pk_sales_orders on orders  (cost=0.29..8.31 rows=1 width=155)"
"  Index Cond: (order_id = 73590)"

"Seq Scan on orders  (cost=0.00..1819.94 rows=107 width=155)"
"  Filter: (customer_id = 1028)"
-- 3. Verklaar de verschillen en schrijf deze op

-- voor de eerste is er een index scan gemaakt waardoor er maar een rij is met indexen die doorzocht moet worden en door de btree search methode ben je vrij snel bij de bijpassende create index
-- bij de tweede is geen index tabel toegevoegd dus hier gaat de database alles langs totdat de juiste is gevonden en dit duurt veel langer
-- 4. Voeg een index toe, waarmee query B versneld kan worden
CREATE INDEX orders_idx ON orders (customer_id);
-- 5. Analyseer met EXPLAIN en kopieer het explain plan onder de opdracht
"Bitmap Heap Scan on orders  (cost=5.12..308.96 rows=107 width=155)"
"  Recheck Cond: (customer_id = 1028)"
"  ->  Bitmap Index Scan on orders_idx  (cost=0.00..5.10 rows=107 width=0)"
"        Index Cond: (customer_id = 1028)"
-- 6. Verklaar de verschillen en schrijf hieronder op
-- het kost nu met de bitmap index scan 5.10 inplaats van  1819.94 wat een stuk sneller is

-- S7.3.A
--
-- Het blijkt dat customers regelmatig klagen over trage bezorging van hun bestelling.
-- Het idee is dat verkopers misschien te lang wachten met het invoeren van de bestelling in het systeem.
-- Daar willen we meer inzicht in krijgen.
-- We willen alle orders (order_id, order_date, salesperson_person_id (als verkoper),
--    het verschil tussen expected_delivery_date en order_date (als levertijd),  
--    en de bestelde hoeveelheid van een product zien (quantity uit order_lines).
-- Dit willen we alleen zien voor een bestelde hoeveelheid van een product > 250
--   (we zijn nl. als eerste geïnteresseerd in grote aantallen want daar lijkt het vaker mis te gaan)
-- En verder willen we ons focussen op verkopers wiens bestellingen er gemiddeld langer over doen.
-- De meeste bestellingen kunnen binnen een dag bezorgd worden, sommige binnen 2-3 dagen.
-- Het hele bestelproces is er op gericht dat de gemiddelde bestelling binnen 1.45 dagen kan worden bezorgd.
-- We willen in onze query dan ook alleen de verkopers zien wiens gemiddelde levertijd 
--  (expected_delivery_date - order_date) over al zijn/haar bestellingen groter is dan 1.45 dagen.
-- Maak om dit te bereiken een subquery in je WHERE clause.
-- Sorteer het resultaat van de hele geheel op levertijd (desc) en verkoper.
-- 1. Maak hieronder deze query (als je het goed doet zouden er 377 rijen uit moeten komen, en het kan best even duren...)



SELECT o.order_id, o.order_date, salesperson_person_id AS verkoper ,(o.expected_delivery_date - o.order_date) AS levertijd,
       ol.quantity
FROM
    orders o
        JOIN
    order_lines ol ON o.order_id = ol.order_id
WHERE (SELECT avg(o2.expected_delivery_date-o2.order_date)
       FROM orders o2 WHERE o2.salesperson_person_id = o.salesperson_person_id)>1.45
AND ol.quantity >250 ORDER BY levertijd DESC, salesperson_person_id;


-- dit zou de goede moeten zijn maar ik krijg maar 4 rijen terug (er zijn sowiezo geen 377 rijen met quantity van hoger dan 250)

-- S7.3.B
--
-- 1. Vraag het EXPLAIN plan op van je query (kopieer hier, onder de opdracht)
"Sort  (cost=14960.30..14960.30 rows=3 width=20)"
"  Sort Key: ((o.expected_delivery_date - o.order_date)) DESC, o.salesperson_person_id"
"  ->  Nested Loop  (cost=0.29..14960.27 rows=3 width=20)"
"        ->  Seq Scan on order_lines ol  (cost=0.00..39.61 rows=8 width=8)"
"              Filter: (quantity > 250)"
"        ->  Index Scan using pk_sales_orders on orders o  (cost=0.29..1865.06 rows=1 width=16)"
"              Index Cond: (order_id = ol.order_id)"
"              Filter: ((SubPlan 1) > 1.45)"
"              SubPlan 1"
"                ->  Aggregate  (cost=1856.74..1856.75 rows=1 width=32)"
"                      ->  Seq Scan on orders o2  (cost=0.00..1819.94 rows=7360 width=8)"
"                            Filter: (salesperson_person_id = o.salesperson_person_id)"
-- 2. Kijk of je met 1 of meer indexen de query zou kunnen versnellen
CREATE INDEX idx_salesperson_person_id ON orders (salesperson_person_id);

-- 3. Maak de index(en) aan en run nogmaals het EXPLAIN plan (kopieer weer onder de opdracht)
"Sort  (cost=9019.40..9019.40 rows=3 width=20)"
"  Sort Key: ((o.expected_delivery_date - o.order_date)) DESC, o.salesperson_person_id"
"  ->  Nested Loop  (cost=0.29..9019.37 rows=3 width=20)"
"        ->  Seq Scan on order_lines ol  (cost=0.00..39.61 rows=8 width=8)"
"              Filter: (quantity > 250)"
"        ->  Index Scan using orders_idx2 on orders o  (cost=0.29..1122.46 rows=1 width=16)"
"              Index Cond: (order_id = ol.order_id)"
"              Filter: ((SubPlan 1) > 1.45)"
"              SubPlan 1"
"                ->  Aggregate  (cost=1114.13..1114.14 rows=1 width=32)"
"                      ->  Bitmap Heap Scan on orders o2  (cost=85.33..1077.33 rows=7360 width=8)"
"                            Recheck Cond: (salesperson_person_id = o.salesperson_person_id)"
"                            ->  Bitmap Index Scan on idx_salesperson_person_id  (cost=0.00..83.49 rows=7360 width=0)"
"                                  Index Cond: (salesperson_person_id = o.salesperson_person_id)"
-- 4. Wat voor verschillen zie je? Verklaar hieronder.
-- nu doet hij in de sub query ook een index search dus het is nu wel wat sneller



-- S7.3.C
--
-- Zou je de query ook heel anders kunnen schrijven om hem te versnellen?
WITH SalespersonAverageDelivery AS (
    SELECT salesperson_person_id, AVG(expected_delivery_date - order_date) AS avg_delivery_time
    FROM orders
    GROUP BY salesperson_person_id
)
SELECT
    o.order_id,
    o.order_date,
    o.salesperson_person_id AS verkoper,
    (o.expected_delivery_date - o.order_date) AS levertijd,
    ol.quantity
FROM
    orders o
        JOIN
    order_lines ol ON o.order_id = ol.order_id
        JOIN
    SalespersonAverageDelivery sad ON o.salesperson_person_id = sad.salesperson_person_id
WHERE
        sad.avg_delivery_time > 1.45
  AND ol.quantity > 250
ORDER BY
    levertijd DESC,
    o.salesperson_person_id;


