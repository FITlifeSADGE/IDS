/**
    * IDS projekt 4
    * autor: Lukáš Kaprál(xkapra00), Jakub K?ivánek(xkriva30)
*/

set serveroutput on;

DROP TABLE vehicle_owner CASCADE CONSTRAINTS;
DROP TABLE vehicle CASCADE CONSTRAINTS;
DROP TABLE traffic_police CASCADE CONSTRAINTS;
DROP TABLE vehicle_registration_worker CASCADE CONSTRAINTS;
DROP TABLE vehicle_theft CASCADE CONSTRAINTS;
DROP TABLE licence CASCADE CONSTRAINTS;
DROP TABLE driving_offence CASCADE CONSTRAINTS;
DROP TABLE automobile CASCADE CONSTRAINTS;
DROP TABLE motorcycle CASCADE CONSTRAINTS;
DROP TABLE offence_officer CASCADE CONSTRAINTS;
DROP TABLE theft_officer CASCADE CONSTRAINTS;
DROP TABLE registration_vehicle CASCADE CONSTRAINTS;
DROP SEQUENCE owner_seq;

CREATE TABLE vehicle_owner ( --Majitel vozidla
    id INT GENERATED AS IDENTITY NOT NULL PRIMARY KEY,
    first_name VARCHAR(30) NOT NULL, --Jméno
    last_name VARCHAR(30) NOT NULL, --P?íjmení
    birthday DATE NOT NULL, --Datum narození
    age INT DEFAULT NULL, --V?k
    residence VARCHAR(100) NOT NULL, --Bydlišt?
    sex CHAR(1) NOT NULL --Pohlaví
        CHECK (sex IN ('m', 'f', '')),
    penalty INT DEFAULT 0 NULL --Po?et trestných bod?
);
CREATE TABLE traffic_police ( --Dopravní policista
    badge_number NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY, --?íslo odznaku
    first_name VARCHAR(30) NOT NULL, --Jméno
    last_name VARCHAR(30) NOT NULL, --P?íjmení
    district VARCHAR(30) NOT NULL, --Služební obvod
    email VARCHAR(255) NOT NULL --E-Mail
            CHECK(REGEXP_LIKE(email, '[a-zA-Z0-9_\-]+@([a-zA-Z0-9_\-]+\.)+[a-z]{2,}'))
);
CREATE TABLE vehicle_registration_worker ( --Pracovník registru vozidel
    id INT GENERATED AS IDENTITY NOT NULL PRIMARY KEY, --ID pracovníka
    first_name VARCHAR(30) NOT NULL, --Jméno
    last_name VARCHAR(30) NOT NULL, --P?íjmení
    job_title VARCHAR(30) NOT NULL, --Pracovní pozice
    age INT NOT NULL, --V?k
    office_number VARCHAR(20) NOT NULL --?íslo kancelá?e
);
CREATE TABLE automobile ( --Osobní auto
    id INT GENERATED AS IDENTITY NOT NULL PRIMARY KEY, --ID
    type VARCHAR(50) NOT NULL, --Model auta
    VIN VARCHAR(17) NOT NULL CHECK ( length(VIN) >= 11 ), --VIN
    body_type VARCHAR(50) NOT NULL, --Typ karoserie
    weight INT NOT NULL --Hmotnost
);
CREATE TABLE motorcycle( --Motorka
    id INT GENERATED AS IDENTITY NOT NULL PRIMARY KEY, --ID
    type VARCHAR(50) NOT NULL, --Typ motorky
    horsepower INT NOT NULL --Výkon
);
CREATE TABLE vehicle ( --Vozidlo
    id INT GENERATED AS IDENTITY NOT NULL PRIMARY KEY, --ID vozidla
    licence_plate CHAR(7) NOT NULL, --SPZ
    car_brand VARCHAR(30) NOT NULL, --Zna?ka
    registration_date DATE NOT NULL, --Datum registrace
    color VARCHAR(30) NOT NULL, --Barva
    owner_id INT NOT NULL, --majitel ma prihlaseno
    automobile_id INT DEFAULT NULL, --specializace
    motorcycle_id INT DEFAULT NULL,
    CONSTRAINT vehicle_automobile_id FOREIGN KEY (automobile_id) REFERENCES automobile (id) ON DELETE SET NULL,
    CONSTRAINT vehicle_motorcycle_id FOREIGN KEY (motorcycle_id) REFERENCES motorcycle (id) ON DELETE SET NULL,
    CONSTRAINT vehicle_owner_id FOREIGN KEY (owner_id) REFERENCES vehicle_owner (id) ON DELETE SET NULL
);
CREATE TABLE vehicle_theft ( --Krádež vozidla
    theft_number NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY, --?íslo krádeže
    theft_date DATE NOT NULL, --Datum krádeže
    theft_location VARCHAR(255),  --ulice + mesto treba --Místo krádeže
    owner_id INT DEFAULT NULL, --Majitel vozidla nahlásil
    vehicle_id INT NOT NULL, --Bylo ukradeno
    CONSTRAINT theft_owner_id FOREIGN KEY (owner_id) REFERENCES vehicle_owner (id) ON DELETE SET NULL,
    CONSTRAINT vehicle_theft_vehicle_id FOREIGN KEY (vehicle_id) REFERENCES vehicle (id) ON DELETE SET NULL
);
CREATE TABLE licence ( --?idi?ský pr?kaz
    id INT GENERATED AS IDENTITY NOT NULL PRIMARY KEY, --ID pr?kazu
    type VARCHAR(5) NOT NULL, --Typ oprávn?ní
    validity DATE NOT NULL, --Doba platnosti
    owner_id INT NOT NULL, --Majitel vozidla vlastní
    officer_id INT DEFAULT NULL, --Dopravní policista odebere
    CONSTRAINT licence_owner_id FOREIGN KEY (owner_id) REFERENCES vehicle_owner (id) ON DELETE SET NULL,
    CONSTRAINT licence_officer_id FOREIGN KEY (officer_id) REFERENCES traffic_police (badge_number) ON DELETE SET NULL
);
CREATE TABLE driving_offence ( --P?estupek
    offence_number NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY, --?íslo p?estupku
    reason VARCHAR(255) NOT NULL, --D?vod
    offence_date DATE NOT NULL, --Datum p?estupku
    penalty INT NOT NULL, --Po?et bod? za p?estupek
    fine INT NOT NULL, --Výše pen?žní pokuty
    owner_id INT NOT NULL, --Majitel vozidla spáchal
    CONSTRAINT offence_owner_id FOREIGN KEY (owner_id) REFERENCES vehicle_owner (id) ON DELETE SET NULL
);
CREATE TABLE offence_officer ( --Dopravní policista evidoval a ov??il p?estupek
     officer_id INT NOT NULL,
     offence_id INT NOT NULL,
     CONSTRAINT offence_officer_fk PRIMARY KEY (officer_id, offence_id),
     CONSTRAINT officer_id_fk FOREIGN KEY (officer_id) REFERENCES traffic_police (badge_number) ON DELETE SET NULL,
     CONSTRAINT offence_id_fk FOREIGN KEY (offence_id) REFERENCES driving_offence (offence_number) ON DELETE SET NULL
);
CREATE TABLE theft_officer ( --Dopravní policista evidoval krádež vozidla
    officer_id INT NOT NULL,
    theft_id INT NOT NULL,
    CONSTRAINT theft_officer_fk PRIMARY KEY (officer_id, theft_id),
    CONSTRAINT theft_officer_id FOREIGN KEY (officer_id) REFERENCES traffic_police (badge_number) ON DELETE SET NULL,
    CONSTRAINT theft_officer_theft_id FOREIGN KEY (theft_id) REFERENCES vehicle_theft (theft_number) ON DELETE SET NULL
);
CREATE TABLE registration_vehicle ( --Pracovník registru vozidel p?ihlásil/odhlásil vozidlo
    vehicle_id INT NOT NULL,
    worker_id INT NOT NULL,
    CONSTRAINT registration_vehicle_fk PRIMARY KEY (vehicle_id, worker_id),
    CONSTRAINT registration_vehicle_vehicle FOREIGN KEY (vehicle_id) REFERENCES vehicle (id) ON DELETE SET NULL,
    CONSTRAINT registration_vehicle_worker FOREIGN KEY (worker_id) REFERENCES vehicle_registration_worker (id) ON DELETE SET NULL
);

--TRIGGER
CREATE SEQUENCE owner_seq;
--automaticky pøipoèítá body za pøestupek k bodùm majitele vozidla
CREATE OR REPLACE TRIGGER owner_seq_id
	BEFORE INSERT ON driving_offence
	FOR EACH ROW
DECLARE owner_points INT;
BEGIN
    SELECT penalty INTO owner_points
    FROM vehicle_owner
    WHERE id = :NEW.owner_id;
    
    UPDATE vehicle_owner SET penalty = (:new.penalty + owner_points) WHERE vehicle_owner.id = :new.owner_id;
END;
/

--automaticky doplní vìk majitele vozidel podle data narození
CREATE OR REPLACE TRIGGER owner_age
	BEFORE INSERT OR UPDATE ON vehicle_owner
	FOR EACH ROW
BEGIN
	IF :new.age IS NULL THEN
		SELECT floor( months_between( sysdate, :new.birthday ) / 12 )
        INTO :new.age
        FROM dual;
	END IF;
END;
/
--

INSERT INTO vehicle_owner (first_name, last_name, birthday, residence, sex)
VALUES ('Peter', 'Polóni', DATE '2001-02-20', 'Slovensko', 'm');
INSERT INTO vehicle_owner (first_name, last_name, birthday, age, residence, sex, penalty)
VALUES ('Šimon', 'Kadnár', DATE '2001-03-01', 21, 'Bratislava', 'm', 7);

INSERT INTO traffic_police (first_name, last_name, district, email)
VALUES ('Brano', 'Mojsej', 'Cernov', 'branomojsej@cernov.sk');
INSERT INTO traffic_police (first_name, last_name, district, email)
VALUES ('Josef', 'Šlota', 'Lunik', 'gabor@stednadbodrogom.sk');

INSERT INTO vehicle_registration_worker (first_name, last_name, job_title, age, office_number)
VALUES ('Dano', 'Drevo', 'receptionist', 32, 'A204');
INSERT INTO vehicle_registration_worker (first_name, last_name, job_title, age, office_number)
VALUES ('Jana', 'Novotná', 'office worker', 28, 'D105');

INSERT INTO automobile (type, VIN, body_type, weight)
VALUES ('pickup truck', '51498465165115', 'raketa', 512);
INSERT INTO vehicle (licence_plate, car_brand, registration_date, color, owner_id, automobile_id)
VALUES ('PR0MILE', 'Lambo', DATE '2020-05-07', 'red-yellow', (SELECT id FROM vehicle_owner WHERE first_name='Peter'), (SELECT id FROM automobile WHERE body_type='raketa'));

INSERT INTO vehicle (licence_plate, car_brand, registration_date, color, owner_id)
VALUES ('JOEMAMA', 'Skoda', DATE '2018-11-25', 'white', (SELECT id FROM vehicle_owner WHERE first_name='Peter'));

INSERT INTO vehicle (licence_plate, car_brand, registration_date, color, owner_id)
VALUES ('NO_BODY', 'Volvo', DATE '2018-11-25', 'black', (SELECT id FROM vehicle_owner WHERE first_name='Peter'));

INSERT INTO motorcycle (type, horsepower)
VALUES ('dirt bike', 60);
INSERT INTO vehicle (licence_plate, car_brand, registration_date, color, owner_id, motorcycle_id)
VALUES ('PEPELAF', 'suzuki', DATE '2018-02-24', 'pink', (SELECT id FROM vehicle_owner WHERE residence='Bratislava'), (SELECT id FROM motorcycle WHERE horsepower=60));

INSERT INTO vehicle_theft (theft_date, theft_location, owner_id, vehicle_id)
VALUES (DATE '2002-04-17', 'Brno', (SELECT id FROM vehicle_owner WHERE first_name='Peter'), (SELECT id FROM vehicle WHERE color='red-yellow'));
INSERT INTO vehicle_theft (theft_date, theft_location, owner_id, vehicle_id)
VALUES (DATE '2012-11-08', 'Bratislava', (SELECT id FROM vehicle_owner WHERE first_name='Šimon'), (SELECT id FROM vehicle WHERE color='pink'));

INSERT INTO licence (type, validity, owner_id, officer_id)
VALUES ('A2', DATE '2023-08-24', (SELECT id FROM vehicle_owner WHERE last_name='Kadnár'), (SELECT badge_number FROM traffic_police WHERE last_name='Mojsej'));

INSERT INTO driving_offence (reason, offence_date, penalty, fine, owner_id)
VALUES ('Speeding', DATE '2022-01-01', 2, 2000, (SELECT id FROM vehicle_owner WHERE last_name='Kadnár'));

INSERT INTO driving_offence (reason, offence_date, penalty, fine, owner_id)
VALUES ('Drunk driving', DATE '2022-04-22', 5, 3000, (SELECT id FROM vehicle_owner WHERE last_name='Polóni'));

INSERT INTO offence_officer(officer_id, offence_id)
VALUES ((SELECT badge_number FROM traffic_police WHERE first_name='Brano'), (SELECT offence_number FROM driving_offence WHERE reason='Speeding'));

INSERT INTO theft_officer(officer_id, theft_id)
VALUES ((SELECT badge_number FROM traffic_police WHERE first_name='Josef'), (SELECT theft_number FROM vehicle_theft WHERE theft_location='Brno'));

INSERT INTO theft_officer(officer_id, theft_id)
VALUES ((SELECT badge_number FROM traffic_police WHERE first_name='Brano'), (SELECT theft_number FROM vehicle_theft WHERE theft_location='Brno'));

INSERT INTO theft_officer(officer_id, theft_id)
VALUES ((SELECT badge_number FROM traffic_police WHERE last_name='Mojsej'), (SELECT theft_number FROM vehicle_theft WHERE theft_location='Bratislava'));

INSERT INTO registration_vehicle(vehicle_id, worker_id)
VALUES ((SELECT id FROM vehicle WHERE car_brand='Lambo'), (SELECT id FROM vehicle_registration_worker WHERE last_name='Drevo'));

-- Napise pocet vozidel vlastnenych majitelem s prijmenim Kadnar
SELECT Count(*) pocet_vozidel FROM vehicle_owner NATURAL JOIN vehicle WHERE last_name='Kadnár';

-- Vypise pocet prestupku, ktere spachal jednotlivy ridic s duvodum Speeding nebo Drunk driving
SELECT first_name, last_name, Count(*) pocet_prestupku FROM driving_offence do,vehicle_owner vo WHERE do.offence_number = vo.id AND (reason = 'Speeding' OR reason = 'Drunk driving') GROUP BY first_name, last_name;

-- Vypise pocet kradezi v jednotlivych mestech, ktere zaevidoval Brano
SELECT theft_location, Count(*) FROM vehicle_theft vt, theft_officer t_o, traffic_police tp WHERE vt.theft_number = t_o.theft_id AND t_o.officer_id = tp.badge_number AND tp.first_name='Brano' GROUP BY theft_location;

-- Vypise auta, ktere nebyly ukradeny
SELECT licence_plate FROM vehicle WHERE NOT EXISTS(SELECT * FROM vehicle_theft WHERE vehicle_id = vehicle.id);

-- Vypise auta, ktere nebyly ukradeny
SELECT * FROM vehicle WHERE id NOT IN (SELECT vehicle_id FROM vehicle_theft);

--
GRANT ALL ON vehicle TO xkriva30;
GRANT SELECT ON vehicle_theft TO xkriva30;

GRANT ALL ON vehicle TO xkapra00;
GRANT SELECT ON vehicle_theft TO xkapra00;
-- GRANT EXECUTE ON vehicle TO xkriva30;

-- VIEW
DROP MATERIALIZED VIEW v_vt;
CREATE MATERIALIZED VIEW v_vt AS SELECT * FROM xkapra00.vehicle;

GRANT ALL ON v_vt TO xkriva30;

-- INSERT
INSERT INTO xkapra00.vehicle (licence_plate, car_brand, registration_date, color, owner_id)
VALUES ('BRS4SD4', 'Opl', DATE '2018-04-01', 'blue',(SELECT id FROM vehicle_owner WHERE first_name='Peter'));

-- VIEW DEMONSTRATION
SELECT licence_plate FROM v_vt;
SELECT licence_plate FROM xkapra00.vehicle;

--PROCEDURE

CREATE OR REPLACE PROCEDURE percent_stolen IS

    pocet_kradezi   NUMBER;
    pocet_vozidel   NUMBER;
    pocet_aut       NUMBER;
    pocet_motorek   NUMBER;
    
BEGIN
    pocet_motorek := 0;
    pocet_aut := 0;
    SELECT DISTINCT
        COUNT(*)
    INTO
        pocet_kradezi
    FROM
        vehicle_theft;
    SELECT DISTINCT
        COUNT(*)
    INTO
        pocet_vozidel
    FROM
        vehicle;
    SELECT 
        COUNT(*)
    INTO
        pocet_motorek
    FROM
        vehicle_theft v_t, vehicle v WHERE v_t.vehicle_id = v.id AND v.motorcycle_id IS NOT NULL;
    SELECT 
        COUNT(*)
    INTO
        pocet_aut
    FROM
        vehicle_theft v_t, vehicle v WHERE v_t.vehicle_id = v.id AND v.automobile_id IS NOT NULL;
        
    dbms_output.put_line(pocet_kradezi / pocet_vozidel * 100
    || '% vozidel bylo ukradeno, '
    || 'dohromady '
    || pocet_kradezi
    || ' kradezi ,celkem '
    || pocet_motorek
    || ' motorek'
    || ' a '
    || pocet_aut
    || ' aut ');

EXCEPTION
    WHEN zero_divide THEN
        dbms_output.put_line('Nebylo ukradeno žádné auto');
END;
/
EXECUTE percent_stolen();


CREATE OR REPLACE PROCEDURE brand_owners
	(brand IN VARCHAR)
AS
	cars NUMBER;
	target_cars NUMBER;
	brand_name vehicle.car_brand%TYPE;
	CURSOR v_owner IS SELECT car_brand FROM vehicle;
BEGIN
	SELECT COUNT(*) INTO cars FROM vehicle;

	target_cars := 0;

	OPEN v_owner;
	LOOP
		FETCH v_owner INTO brand_name;
		EXIT WHEN v_owner%NOTFOUND;

		IF brand_name = brand THEN
			target_cars := target_cars + 1;
		END IF;
	END LOOP;
	CLOSE v_owner;

	DBMS_OUTPUT.put_line(
		'Znaèka ' || brand || ' je registrována ' || target_cars
		|| ' krát z celkových ' || cars || ' vozidel'
	);

	EXCEPTION WHEN NO_DATA_FOUND THEN
	BEGIN
		DBMS_OUTPUT.put_line(
			'Znaèka auta ' || brand || ' není registrována'
		);
	END;
END;
/
EXECUTE brand_owners('suzuki');

--EXPLAIN PLAN

--Kteøí øidièi, narozeni po roce 2000, vlastní více jak 1 vozidlo 
--a kolik jich vlastní
EXPLAIN PLAN FOR
SELECT
	COUNT(v.id) AS "count"
FROM vehicle v
JOIN vehicle_owner v_o ON v_o.id = v.owner_id
WHERE v_o.birthday > DATE '1999-12-31'
GROUP BY v_o.id
HAVING COUNT(v.id) > 1;
-- výpis
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

CREATE INDEX owner_bday ON vehicle_owner (birthday);

EXPLAIN PLAN FOR
SELECT
	COUNT(v.id) AS "count"
FROM vehicle v
JOIN vehicle_owner v_o ON v_o.id = v.owner_id
WHERE v_o.birthday > DATE '1999-12-31'
GROUP BY v_o.id
HAVING COUNT(v.id) > 1;
-- výpis
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);
