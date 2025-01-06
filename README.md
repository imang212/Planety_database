## Kosmická databáze

__Model databáze__

![planety_navrh](https://github.com/user-attachments/assets/2ae8bc05-f7a2-4de1-8096-5cc0ec586f2b)

__Načtení databáze__

Databázi si můžeme načíst pomocí nahraného souboru "planety_postgre.sql". Stačí zkopírovat kód do Postgresql databáze, spustit ho jako celek a potom by se měla objevit ve Vaší databázi. Tento kód funguje pouze pro postgresql databázi.   

### Příkazy
A teď se pojďme podívat na příkazy, které jsem udělal v rámci seminární práce na RDBS(Relační databázové systémy).

__SELECT pro výpočet průměrné počtu záznamů na tabulku__
```sql
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
```
__SELECT s vnořeným selectem__
```sql
select nazev as "Název tělesa", 1 + (select count(*) from "Teleso" where "hmotnost_(kg)" > t."hmotnost_(kg)") as "Pořadí největší hmotnost" 
from "Teleso" t
order by "Pořadí největší hmotnost";
```
__SELECT s analytickou funkcí__
```sql
select t3.typ AS "Druh tělesa", CONCAT(ROUND(AVG(t1."prumer_(km)")::numeric,0),' ','km') AS "Průměrný průměr těles"
FROM ("Teleso" t1 JOIN "Typ_telesa" t2 ON t1.id_typ_tel = t2.id_typ) 
LEFT JOIN "Typy_planet" t3 ON t2.id_pla = t3.id_pla
WHERE t2.id_pla IS NOT NULL
group by t3.typ 
order by AVG(t1."prumer_(km)") desc
limit 4
```
__SELECT s hiearchií SELF_JOIN__
```sql
SELECT t3.typ AS "typ planety",
t3.id_pla as "ID typu planety",
t1.nazev AS "název", 
t1.id_tel as "ID planety"
FROM ("Teleso" t1 JOIN "Typ_telesa" t2 ON t1.id_typ_tel = t2.id_typ) 
LEFT JOIN "Typy_planet" t3 ON t2.id_pla = t3.id_pla
WHERE t3.id_pla IS NOT NULL
ORDER BY t3.id_pla asc
```
__View__
```sql
SELECT t3.typ AS "typ planety",
t3.id_pla as "ID typu planety",
t1.nazev AS "název", 
t1.id_tel as "ID planety"
FROM ("Teleso" t1 JOIN "Typ_telesa" t2 ON t1.id_typ_tel = t2.id_typ) 
LEFT JOIN "Typy_planet" t3 ON t2.id_pla = t3.id_pla
WHERE t3.id_pla IS NOT NULL
ORDER BY t3.id_pla asc
```
__INDEX__

Nejdříve změřím normální čas potřebný pro daný select pomocí příkazu explain analyse.
```sql
explain analyse SELECT t3.typ AS "typ planety",
t3.id_pla as "ID typu planety",
t1.nazev AS "název", 
t1.id_tel as "ID planety"
FROM ("Teleso" t1 JOIN "Typ_telesa" t2 ON t1.id_typ_tel = t2.id_typ) 
LEFT JOIN "Typy_planet" t3 ON t2.id_pla = t3.id_pla
WHERE t3.id_pla IS NOT NULL
ORDER BY t3.id_pla asc
```
Vytvořím si první index na id typu tělesa v tabulce Teleso, aby se mezi nimi dalo ryhleji prohledávat.
```sql
CREATE index index1 ON "Teleso"("id_typ_tel");
```
Potom zase zkontroluji čas příkazu a můžu vidět, že příkaz se provedl rychleji.
```sql
explain analyse SELECT t3.typ AS "typ planety",
t3.id_pla as "ID typu planety",
t1.nazev AS "název", 
t1.id_tel as "ID planety"
FROM ("Teleso" t1 JOIN "Typ_telesa" t2 ON t1.id_typ_tel = t2.id_typ) 
LEFT JOIN "Typy_planet" t3 ON t2.id_pla = t3.id_pla
WHERE t3.id_pla IS NOT NULL
ORDER BY t3.id_pla asc
```
Dalá si udělám index na dva sloupce u tabulky Typ_telesa
```sql
create index index2 ON "Typ_telesa"("id_typ","id_pla");
```
A zase se nám příkaz o něco zrychlil.

__Funkce vracející průměrnou hmotnost těles podle jejich druhu(skupiny)__
```sql
create or replace function Vrat_prumernou_hmotnost(druh_telesa text)
  returns Table(hmotnost text) AS $$
    select concat(AVG(t1."hmotnost_(kg)"::real),' kg') as "Průměrná hmotnost" 
    from "Teleso" t1 join "Typ_telesa" t2 ON t1.id_typ_tel = t2.id_typ 
    where t2.nazev = druh_telesa
$$ language sql;
```
Nyní si funkci vyzkouším měsíce
```sql
select Vrat_prumernou_hmotnost('měsíc');
```
A ještě na normální planety
```sql
select Vrat_prumernou_hmotnost('planeta');
```

__Procedura__

Zde mám proceduru, která nám vrátí tabulku s typy, názvy a gravitací jednotlivých těles.
```sql
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
```
```sql
select Vrat_gravitaci(0,2); --nejdřív tělesa, která mají gravitaci od 0 do 2 m/S
```
```sql
select Vrat_gravitaci(20,1000); -- potom tělesa, která mají vyšší gravitaci než 20 m/s
```
__Trigger__

Abych mohl udělat trigger, tak nejsříve musím mít tabulku pro ukládání záznamů.
```sql
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
```
Teďka si nadefinuji funkci, kterou bude používat trigger.
```sql
-- funkce kterou použije trigger pro vložení
CREATE OR REPLACE FUNCTION teleso_insert()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO Teleso_action(id_tel,nazev,datum,akce,user_) VALUES (NEW.id_tel,NEW.nazev,CURRENT_TIMESTAMP,'INSERT',SESSION_USER);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```
Nakonec si vytvořím trigger, který použije funkci teleso_insert().
```sql
CREATE TRIGGER teleso_insert_after
AFTER INSERT ON "Teleso"
FOR EACH ROW
EXECUTE FUNCTION teleso_insert()
```
Vyzkouším, jestli to funguje.
```sql
INSERT INTO "Teleso" VALUES (36,'Alpha Centauri A',Null, 3, 1.2175*695700, 1.078*2*POWER(10,30), 1.51 , 42.17, NULL,5.804,NULL,9720, 28.3,NULL,NULL);
```
```sql
DELETE FROM "Teleso" WHERE id_tel = 36;
```
__Transakce__

Transakce, která změní odečte průměr z jedné planety a přičte ho ke druhé
```sql
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
```
Teď to vyzkouším.
```sql
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

```
__User__

Zde mám píklad vytvoření uživatele.
```sql
CREATE USER patricek WITH PASSWORD 'patrik123456';
```
Přidělení práva uživateli, aby se mohl pžipojit.
```sql
GRANT CONNECT ON DATABASE postgres TO patricek;
```
Vytvoření role.
```sql
CREATE ROLE selecting_role WITH LOGIN PASSWORD 'heslo';

GRANT USAGE, CREATE ON SCHEMA public TO selecting_role;
--GRANT SELECT ON TABLE "Planety" TO Patricek;
GRANT SELECT ON TABLE "Teleso" TO selecting_role;
```
Přidělení role uživateli.
```sql
GRANT selecting_role TO patricek;
```
Přidělování práv.
```sql
GRANT ALL PRIVILEGES ON TABLE "Teleso","teleso_action" TO selecting_role;
GRANT USAGE, SELECT ON SEQUENCE teleso_action_id_seq TO selecting_role;
```
Odebírání práv.
```sql
REVOKE ALL PRIVILEGES ON TABLE "Teleso","teleso_action" FROM selecting_role;
REVOKE ALL PRIVILEGES ON DATABASE postgres FROM patricek;
REVOKE USAGE, CREATE ON SCHEMA public FROM selecting_role;
```
Smazání uživatele a role.
```sql
DROP user patricek;
DROP ROLE selecting_role;
```
__Lock__
Zamknu si tabulku při třeba nějaké práci, aby s ní nikdo nemohl vykonávat další věci. Například do share módu.
```sql
BEGIN WORK;
LOCK TABLE "Teleso" IN SHARE MODE; --zamknu tabulku, když jdu dělat konkrétní operaci
SELECT * FROM "Teleso" WHERE id_tel = 1 FOR SHARE;
SELECT * FROM "Teleso" WHERE id_tel = 1 for update;
ROLLBACK;
COMMIT WORK;
UPDATE "Teleso" SET "prumer_(km)" = "prumer_(km)" - 100000 WHERE id_tel = 1;
```
Zamknu tabulku do exclusive access modu
```sql
BEGIN WORK;
LOCK TABLE "Teleso" in ACCESS EXCLUSIVE MODE;
SELECT * FROM "Teleso" WHERE id_tel = 1 FOR SHARE;
SELECT * FROM "Teleso" WHERE id_tel = 1 for update;
UPDATE "Teleso" SET "prumer_(km)" = "prumer_(km)" + 100000 WHERE id_tel = 1;
ROLLBACK;
COMMIT WORK;
```
Odebrání připojení k databázi z veřejného serveru.
```sql
-- odeberu
REVOKE CONNECT ON DATABASE postgres FROM PUBLIC;
-- znovu přidělím
GRANT CONNECT ON DATABASE postgres TO PUBLIC;
```
__ORM(Object relation mapping)__

Nakonec mám object relation mapping. Kde jsem k připojení využil sqlalchemy a psycopg2 knihovnu. Kód je v souboru "orm.py"
