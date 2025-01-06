--- 4x select
-- select vypočítání průměrných záznamů na tabulku

-- 2.způsob
SELECT ROUND(AVG(pocet_zaznamu),0) AS "Průměrný počet záznamů na jednu tabulku"
FROM (
    SELECT COUNT(*) AS pocet_zaznamu FROM public."Objev"
    UNION ALL
    SELECT COUNT(*) AS pocet_zaznamu FROM public."Objevitel"
    UNION ALL
    SELECT COUNT(*) AS pocet_zaznamu FROM public."Prvky"
    UNION ALL
    SELECT COUNT(*) AS pocet_zaznamu FROM public."Slouceniny"
    UNION ALL
    SELECT COUNT(*) AS pocet_zaznamu FROM public."Slozeni"
    UNION ALL
    SELECT COUNT(*) AS pocet_zaznamu FROM public."Teleso"
    UNION ALL
    SELECT COUNT(*) AS pocet_zaznamu FROM public."Typ_telesa"
    UNION ALL
    SELECT COUNT(*) AS pocet_zaznamu FROM public."Typy_hvezd"
    UNION ALL
    SELECT COUNT(*) AS pocet_zaznamu FROM public."Typy_planet"
    UNION ALL
    SELECT COUNT(*) AS pocet_zaznamu FROM public."Vzdalenost"
) 

--select s vnořených selectem
select nazev as "Název tělesa", 1 + (select count(*) from "Teleso" where "hmotnost_(kg)" > t."hmotnost_(kg)") as "Pořadí největší hmotnost" 
from "Teleso" t
order by "Pořadí největší hmotnost";

--select s analytickou funkcí
select t3.typ AS "Druh tělesa", CONCAT(ROUND(AVG(t1."prumer_(km)")::numeric,0),' ','km') AS "Průměrný průměr těles"
FROM ("Teleso" t1 JOIN "Typ_telesa" t2 ON t1.id_typ_tel = t2.id_typ) 
LEFT JOIN "Typy_planet" t3 ON t2.id_pla = t3.id_pla
WHERE t2.id_pla IS NOT NULL
group by t3.typ 
order by AVG(t1."prumer_(km)") desc
limit 4

--select s hiearchií SELF_join
SELECT t3.typ AS "typ planety",
t3.id_pla as "ID typu planety",
t1.nazev AS "název", 
t1.id_tel as "ID planety"
FROM ("Teleso" t1 JOIN "Typ_telesa" t2 ON t1.id_typ_tel = t2.id_typ) 
LEFT JOIN "Typy_planet" t3 ON t2.id_pla = t3.id_pla
WHERE t3.id_pla IS NOT NULL
ORDER BY t3.id_pla asc

--view
CREATE OR REPLACE VIEW Telesa_view AS
SELECT t1.nazev AS "název tělesa", t1.symbol AS "symbol tělesa", 
CONCAT(t1."hmotnost_(kg)",' kg') AS "hmotnost tělesa", 
CONCAT(ROUND(t1."prumer_(km)"::numeric,0),' km') AS "průměr tělesa",  
t2.objevitel AS "Kdo objevil", t3.nazev AS "typ tělesa", 
CONCAT_WS(' ',t5.typ,t4.typ) AS "druh" 
FROM ("Teleso" t1 JOIN "Objev" t2 ON t1.id_tel = t2.id_pla JOIN "Typ_telesa" t3 ON t1.id_typ_tel = t3.id_typ) 
LEFT JOIN "Typy_planet" t4 ON t3.id_pla = t4.id_pla
LEFT JOIN "Typy_hvezd" t5 ON t3.id_hve = t5.id_hve
ORDER BY id_tel;

---index
explain analyse SELECT t3.typ AS "typ planety",
t3.id_pla as "ID typu planety",
t1.nazev AS "název", 
t1.id_tel as "ID planety"
FROM ("Teleso" t1 JOIN "Typ_telesa" t2 ON t1.id_typ_tel = t2.id_typ) 
LEFT JOIN "Typy_planet" t3 ON t2.id_pla = t3.id_pla
WHERE t3.id_pla IS NOT NULL
ORDER BY t3.id_pla asc

--index1
explain analyse SELECT t3.typ AS "typ planety",
t3.id_pla as "ID typu planety",
t1.nazev AS "název", 
t1.id_tel as "ID planety"
FROM ("Teleso" t1 JOIN "Typ_telesa" t2 ON t1.id_typ_tel = t2.id_typ) 
LEFT JOIN "Typy_planet" t3 ON t2.id_pla = t3.id_pla
WHERE t3.id_pla IS NOT NULL
ORDER BY t3.id_pla asc

CREATE index index1 ON "Teleso"("id_typ_tel");

explain analyse SELECT t3.typ AS "typ planety",
t3.id_pla as "ID typu planety",
t1.nazev AS "název", 
t1.id_tel as "ID planety"
FROM ("Teleso" t1 JOIN "Typ_telesa" t2 ON t1.id_typ_tel = t2.id_typ) 
LEFT JOIN "Typy_planet" t3 ON t2.id_pla = t3.id_pla
WHERE t3.id_pla IS NOT NULL
ORDER BY t3.id_pla asc

-- vytvořím si ještě index2
create index index2 ON "Typ_telesa"("id_typ","id_pla");

explain analyse SELECT t3.typ AS "typ planety",
t3.id_pla as "ID typu planety",
t1.nazev AS "název", 
t1.id_tel as "ID planety"
FROM ("Teleso" t1 JOIN "Typ_telesa" t2 ON t1.id_typ_tel = t2.id_typ) 
LEFT JOIN "Typy_planet" t3 ON t2.id_pla = t3.id_pla
WHERE t3.id_pla IS NOT NULL
ORDER BY t3.id_pla asc

--další index
CREATE index index1 ON "Teleso"("id_typ_tel");

explain SELECT t1.nazev, to_char(t2."datum_objevu"::date ,'dd.mm.YYYY') AS "datum objevu", 
concat(t3."jmeno",t3."prijmeni") AS "Jméno objevitele", 
t3.puvod as "Původ objevitele"
FROM ("Teleso" t1 JOIN "Objev" t2 ON t1.id_tel = t2.id_pla) 
JOIN "Objevitel" t3 ON t2.id_jme = t3.id_jme
WHERE t1.id_typ_tel = 12
ORDER BY t2.datum_objevu ASC;

CREATE INDEX index2 ON "Objev"("id_pla","id_jme")

explain SELECT t1.nazev, to_char(t2."datum_objevu"::date ,'dd.mm.YYYY') AS "datum objevu", 
concat(t3."jmeno",t3."prijmeni") AS "Jméno objevitele", 
t3.puvod as "Původ objevitele"
FROM ("Teleso" t1 JOIN "Objev" t2 ON t1.id_tel = t2.id_pla) 
JOIN "Objevitel" t3 ON t2.id_jme = t3.id_jme
WHERE t1.id_typ_tel = 12
ORDER BY t2.datum_objevu ASC;



--funkce, vrací hmotnost tělesa
create or replace function Vrat_prumernou_hmotnost(druh_telesa text)
  returns Table(hmotnost text) AS $$
    select concat(AVG(t1."hmotnost_(kg)"::real),' kg') as "Průměrná hmotnost" 
    from "Teleso" t1 join "Typ_telesa" t2 ON t1.id_typ_tel = t2.id_typ 
    where t2.nazev = druh_telesa
$$ language sql;

select Vrat_prumernou_hmotnost('měsíc');
select Vrat_prumernou_hmotnost('planeta');

--- procedura
-- prodecedura, která nám crací tabulku s gravitací jednotlivých těles
create or replace function Vrat_gravitaci(min_gravitace numeric, max_gravitace numeric) 
RETURNS void AS $$
DECLARE
  p_cursor CURSOR FOR SELECT t2.nazev AS typ_planety, t1.nazev, t1."gravitace_(m/s^(2))" AS gravitace 
      FROM "Teleso" t1 LEFT join "Typ_telesa" t2 ON t1.id_typ_tel = t2.id_typ 
      WHERE t1."gravitace_(m/s^(2))" IS NOT NULL
      ORDER BY t1."gravitace_(m/s^(2))" DESC; 
  p_record RECORD;
BEGIN
  DROP TABLE IF EXISTS "gravitace_planet";
    CREATE TABLE IF NOT EXISTS "gravitace_planet" (
    nazev TEXT,        
    typ_planety TEXT,
        gravitace TEXT
    );

  OPEN p_cursor;
  LOOP
    FETCH p_cursor INTO p_record;
    EXIT WHEN NOT FOUND;
    BEGIN
    IF p_record.gravitace >= min_gravitace AND p_record.gravitace <= max_gravitace THEN
          INSERT INTO gravitace_planet(nazev, typ_planety, gravitace)
          VALUES (p_record.nazev, p_record.typ_planety, concat(p_record.gravitace, ' m/s'));
  ELSE
    END IF;
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'Error: %: %',p_record.nazev, SQLERRM;
    END;
  END LOOP;
  CLOSE p_cursor;
  RAISE NOTICE 'Procedure completed successfully.';
END;
$$ language plpgsql;


select Vrat_gravitaci(0,2); --nejdřív tělesa, která mají gravitaci od 0 do 2 m/S
select Vrat_gravitaci(20,1000); -- potom tělesa, která mají vyšší gravitaci než 20 m/s



---trigger
--vytvořím tabulku pro vkládání triggerů
DROP TABLE IF EXISTS teleso_action;
CREATE TABLE teleso_action(
    id SERIAL NOT NULL,
    id_tel INT, 
    nazev CHAR(50),
    datum  TIMESTAMP,
    akce CHAR(6),
    user_ VARCHAR(30),
    CONSTRAINT "Teleso_action_pkey" PRIMARY KEY (id)
);

-- funkce kterou použije trigger pro vložení
CREATE OR REPLACE FUNCTION teleso_insert()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO Teleso_action(id_tel,nazev,datum,akce,user_) VALUES (NEW.id_tel,NEW.nazev,CURRENT_TIMESTAMP,'INSERT',SESSION_USER);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

--nakonec vkládací trigger, který použije funkci pro vložení a bude zaznamenát když někdo vloží novou planetu do DB
CREATE TRIGGER teleso_insert_after
AFTER INSERT ON "Teleso"
FOR EACH ROW
EXECUTE FUNCTION teleso_insert()

-- zkusím přidat nějaké těleso
INSERT INTO "Teleso" VALUES (36,'Alpha Centauri A',Null, 3, 1.2175*695700, 1.078*2*POWER(10,30), 1.51 , 42.17, NULL,5.804,NULL,9720, 28.3,NULL,NULL);
DELETE FROM "Teleso" WHERE id_tel = 36;

--- transakce
CREATE OR REPLACE PROCEDURE zmen_prumer_planety(nazev1 VARCHAR, nazev2 VARCHAR, o_kolik NUMERIC)
AS $$
DECLARE
  aktualni_prumer NUMERIC; --uložím si průměr tělesa do proměnné
BEGIN -- začnu transakci
  -- vezmu si průměr tělesa  z kterýho ho budu brát
    SELECT "prumer_(km)" INTO aktualni_prumer 
  FROM "Teleso" 
  WHERE nazev = nazev1;
    
  -- vyvolám výjimku, když těleso bude mít menší průměr než hodnota, kterou odečítám
  IF aktualni_prumer < o_kolik THEN 
    RAISE EXCEPTION 'Těleso % má malý průměr.', nazev1;
  ELSE
    END IF;
  
  --odečteme prumer
    UPDATE "Teleso"
    SET "prumer_(km)" = "prumer_(km)" - o_kolik
    WHERE nazev = nazev1;
  
    --přičteme prumer
    UPDATE "Teleso"
    SET "prumer_(km)" = "prumer_(km)" + o_kolik
    WHERE nazev = nazev2;
  

  -- vypíšu poznámku, že transakce byla dokonřená
  RAISE NOTICE 'Převod průměru byl dokončen.';
-- když nastane nějaká chyba vyvolám výjimku a transakci vrátím nazpátek
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Transakce selhala: %', SQLERRM;
  RAISE;
END;
$$ LANGUAGE plpgsql;

SELECT id_tel, nazev, concat(ROUND("prumer_(km)"::numeric,0),' km') FROM "Teleso" WHERE nazev IN ('Jupiter','Merkur');

BEGIN;
CALL zmen_prumer_planety('Jupiter','Merkur',100000);
ROLLBACK; -- při chybě zavolám rollback
COMMIT; 

SELECT id_tel, nazev, concat(ROUND("prumer_(km)"::numeric,0),' km') FROM "Teleso" WHERE nazev IN ('Jupiter','Merkur');

BEGIN;
CALL zmen_prumer_planety('Merkur','Jupiter',100000);
ROLLBACK;
COMMIT;

SELECT id_tel, nazev, concat(ROUND("prumer_(km)"::numeric,0),' km') FROM "Teleso" WHERE nazev IN ('Jupiter','Merkur');

    
---user
CREATE USER patricek WITH PASSWORD 'patrik123456';
GRANT CONNECT ON DATABASE postgres TO patricek;

CREATE ROLE selecting_role WITH LOGIN PASSWORD 'heslo';

GRANT USAGE, CREATE ON SCHEMA public TO selecting_role;

--GRANT SELECT ON TABLE "Planety" TO Patricek;
GRANT SELECT ON TABLE "Teleso" TO selecting_role;

GRANT selecting_role TO patricek;

-- select * from "Teleso"; DELETE FROM "Teleso" WHERE id_tel = 36; INSERT INTO "Teleso" VALUES (36,'Alpha Centauri A',Null, 3, 1.2175*695.700, 1.078*2*POWER(10,30), 1.51 , 42.17, NULL,5.804,NULL,9720, 28.3,NULL,NULL);
-- psql -U patricek -d postgres

GRANT ALL PRIVILEGES ON TABLE "Teleso","teleso_action" TO selecting_role;
GRANT USAGE, SELECT ON SEQUENCE teleso_action_id_seq TO selecting_role;

REVOKE ALL PRIVILEGES ON TABLE "Teleso","teleso_action" FROM selecting_role;
REVOKE ALL PRIVILEGES ON DATABASE postgres FROM patricek;
REVOKE USAGE, CREATE ON SCHEMA public FROM selecting_role;

DROP user patricek;
DROP ROLE selecting_role;

--lock
BEGIN WORK;
LOCK TABLE "Teleso" IN SHARE MODE; --zamknu tabulku, když jdu dělat konkrétní operaci
SELECT * FROM "Teleso" WHERE id_tel = 1 FOR SHARE;
SELECT * FROM "Teleso" WHERE id_tel = 1 for update;
ROLLBACK;
COMMIT WORK;
UPDATE "Teleso" SET "prumer_(km)" = "prumer_(km)" - 100000 WHERE id_tel = 1;

BEGIN WORK;
LOCK TABLE "Teleso" in ACCESS EXCLUSIVE MODE;
SELECT * FROM "Teleso" WHERE id_tel = 1 FOR SHARE;
SELECT * FROM "Teleso" WHERE id_tel = 1 for update;
UPDATE "Teleso" SET "prumer_(km)" = "prumer_(km)" + 100000 WHERE id_tel = 1;
ROLLBACK;
COMMIT WORK;

REVOKE CONNECT ON DATABASE postgres FROM PUBLIC;

GRANT CONNECT ON DATABASE postgres TO PUBLIC;

--orm
