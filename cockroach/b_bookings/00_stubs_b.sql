-- ============================================================================
-- ParkWise DA3 — Work Package B: Solo-Testing Stubs (00_stubs_b.sql)
-- Creates stub parent tables with exact contract IDs & rules for solo testing.
-- Dropped prior to full team merge (A + C + B).
-- ============================================================================

DROP TABLE IF EXISTS parking_slot CASCADE;
DROP TABLE IF EXISTS parking_lot CASCADE;
DROP TABLE IF EXISTS vehicle CASCADE;
DROP TABLE IF EXISTS registered_user CASCADE;
DROP TABLE IF EXISTS user_master CASCADE;

CREATE TABLE user_master (
    user_id INT8 PRIMARY KEY,
    user_type STRING NOT NULL
);

CREATE TABLE registered_user (
    user_id INT8 PRIMARY KEY,
    wallet_balance DECIMAL(10,2) DEFAULT 0.00 CHECK (wallet_balance >= 0.00)
);

CREATE TABLE vehicle (
    vehicle_id INT8 PRIMARY KEY,
    user_id INT8 NOT NULL,
    vehicle_type STRING NOT NULL CHECK (vehicle_type IN ('CAR', 'BIKE', 'TRUCK', 'EV')),
    is_verified INT2 DEFAULT 0 CHECK (is_verified IN (0, 1)),
    UNIQUE (vehicle_id, user_id)
);

CREATE TABLE parking_lot (
    zone_id INT8 NOT NULL,
    lot_id INT8 NOT NULL,
    is_active INT2 DEFAULT 1 CHECK (is_active IN (0, 1)),
    PRIMARY KEY (zone_id, lot_id),
    UNIQUE (lot_id)
);

CREATE TABLE parking_slot (
    zone_id INT8 NOT NULL,
    slot_id INT8 NOT NULL,
    lot_id INT8 NOT NULL,
    slot_type STRING NOT NULL CHECK (slot_type IN ('STANDARD', 'COMPACT', 'LARGE', 'EV')),
    hourly_rate DECIMAL(8,2) NOT NULL CHECK (hourly_rate > 0),
    is_occupied INT2 DEFAULT 0 CHECK (is_occupied IN (0, 1)),
    PRIMARY KEY (zone_id, slot_id),
    UNIQUE (slot_id),
    CONSTRAINT fk_stub_slot_lot FOREIGN KEY (zone_id, lot_id) REFERENCES parking_lot(zone_id, lot_id)
);

-- Seed 1,500 user_master rows per contract
INSERT INTO user_master (user_id, user_type)
SELECT g,
       CASE
           WHEN g <= 1400 THEN 'REGISTERED'
           WHEN g <= 1460 THEN 'ATTENDANT'
           ELSE 'ADMIN'
       END
FROM generate_series(1, 1500) AS g;

-- Seed 1,400 registered_user rows (ids 1-1400)
INSERT INTO registered_user (user_id, wallet_balance)
SELECT g, 500.00
FROM generate_series(1, 1400) AS g;

-- Seed 2,000 vehicle rows (ids 1-2000)
-- Owner of vehicle v is ((v-1) MOD 1400)+1
-- 1-1000 CAR, 1001-1500 BIKE, 1501-1700 TRUCK, 1701-2000 EV
-- Vehicles 1..1950 verified (1), 1951..2000 unverified (0) for edge-case testing
INSERT INTO vehicle (vehicle_id, user_id, vehicle_type, is_verified)
SELECT v,
       ((v - 1) % 1400) + 1,
       CASE
           WHEN v <= 1000 THEN 'CAR'
           WHEN v <= 1500 THEN 'BIKE'
           WHEN v <= 1700 THEN 'TRUCK'
           ELSE 'EV'
       END,
       CASE WHEN v <= 1950 THEN 1 ELSE 0 END
FROM generate_series(1, 2000) AS v;

-- Seed 50 parking_lot rows (ids 1-50)
-- Lot l is in zone ((l-1) DIV 10)+1; lot 50 is inactive (0) for edge-case testing
INSERT INTO parking_lot (zone_id, lot_id, is_active)
SELECT ((l - 1) // 10) + 1,
       l,
       CASE WHEN l < 50 THEN 1 ELSE 0 END
FROM generate_series(1, 50) AS l;

-- Seed 2,500 parking_slot rows (ids 1-2500)
-- Slot s is in lot ((s-1) DIV 50)+1 and zone ((s-1) DIV 500)+1
-- Position p = ((s-1) MOD 50)+1: 1-30 STANDARD, 31-38 COMPACT, 39-46 LARGE, 47-50 EV
INSERT INTO parking_slot (zone_id, slot_id, lot_id, slot_type, hourly_rate, is_occupied)
SELECT ((s - 1) // 500) + 1 AS zone_id,
       s AS slot_id,
       ((s - 1) // 50) + 1 AS lot_id,
       CASE
           WHEN ((s - 1) % 50) + 1 <= 30 THEN 'STANDARD'
           WHEN ((s - 1) % 50) + 1 <= 38 THEN 'COMPACT'
           WHEN ((s - 1) % 50) + 1 <= 46 THEN 'LARGE'
           ELSE 'EV'
       END AS slot_type,
       CASE
           WHEN ((s - 1) % 50) + 1 <= 30 THEN 40.00
           WHEN ((s - 1) % 50) + 1 <= 38 THEN 30.00
           WHEN ((s - 1) % 50) + 1 <= 46 THEN 60.00
           ELSE 80.00
       END AS hourly_rate,
       0 AS is_occupied
FROM generate_series(1, 2500) AS s;

-- Stand-in fn_calc_price (owned by A, stand-in for solo testing in B)
CREATE OR REPLACE FUNCTION fn_calc_price(
    p_slot_id INT8,
    p_vehicle_type STRING,
    p_start TIMESTAMPTZ,
    p_end TIMESTAMPTZ
) RETURNS DECIMAL(10,2)
LANGUAGE SQL
AS $$
    SELECT ROUND(
        s.hourly_rate * GREATEST(1::DECIMAL, CEIL(EXTRACT(EPOCH FROM (p_end - p_start))::DECIMAL / 3600.0)),
        2
    )
    FROM parking_slot s
    WHERE s.slot_id = p_slot_id
    LIMIT 1;
$$;
