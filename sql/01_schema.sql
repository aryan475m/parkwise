-- ============================================================================
-- PARKWISW SMART PARKING SYSTEM — DDL SCHEMA SCRIPT
-- Oracle Database 21c Compatible
-- ============================================================================

-- Clean up existing tables and sequences safely
BEGIN
    FOR t IN (SELECT table_name FROM user_tables) LOOP
        EXECUTE IMMEDIATE 'DROP TABLE ' || t.table_name || ' CASCADE CONSTRAINTS';
    END LOOP;
    FOR s IN (SELECT sequence_name FROM user_sequences) LOOP
        EXECUTE IMMEDIATE 'DROP SEQUENCE ' || s.sequence_name;
    END LOOP;
END;
/

-- ---------------------------------------------------------------------------
-- 1. SEQUENCES (Contract for next_id() in UI and backend automation)
-- ---------------------------------------------------------------------------
CREATE SEQUENCE seq_zone_config      START WITH 100 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_parking_lot      START WITH 100 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_parking_slot     START WITH 100 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_user_master      START WITH 100 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_vehicle          START WITH 100 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_booking          START WITH 100 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_payment          START WITH 100 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_entry_exit_log   START WITH 100 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_dispute          START WITH 100 INCREMENT BY 1 NOCACHE;

-- ---------------------------------------------------------------------------
-- 2. ZONE CONFIGURATION
-- ---------------------------------------------------------------------------
CREATE TABLE zone_config (
    zone_id          NUMBER(10) PRIMARY KEY,
    zone_name        VARCHAR2(50) NOT NULL UNIQUE,
    region_code      VARCHAR2(20) NOT NULL,
    peak_multiplier  NUMBER(4,2) DEFAULT 1.00 CHECK (peak_multiplier >= 1.00),
    ev_discount      NUMBER(4,2) DEFAULT 0.10 CHECK (ev_discount >= 0.00)
);

-- ---------------------------------------------------------------------------
-- 3. USER MANAGEMENT (EER Specialization Hierarchy)
-- ---------------------------------------------------------------------------
CREATE TABLE user_master (
    user_id          NUMBER(10) PRIMARY KEY,
    phone            VARCHAR2(20) NOT NULL UNIQUE,
    email            VARCHAR2(100) NOT NULL UNIQUE,
    password_hash    VARCHAR2(255) DEFAULT 'default_hash',
    created_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    user_type        VARCHAR2(30) DEFAULT 'REGISTERED' CHECK (user_type IN ('REGISTERED', 'ATTENDANT', 'ADMIN'))
);

CREATE TABLE registered_user (
    user_id                NUMBER(10) PRIMARY KEY,
    kyc_status             VARCHAR2(20) DEFAULT 'PENDING' CHECK (kyc_status IN ('PENDING', 'VERIFIED', 'REJECTED')),
    wallet_balance         NUMBER(10,2) DEFAULT 0.00 CHECK (wallet_balance >= 0.00),
    default_payment_method VARCHAR2(20) DEFAULT 'UPI' CHECK (default_payment_method IN ('UPI', 'CARD', 'WALLET', 'CASH')),
    CONSTRAINT fk_reg_user FOREIGN KEY (user_id) REFERENCES user_master(user_id) ON DELETE CASCADE
);

CREATE TABLE admin_user (
    user_id          NUMBER(10) PRIMARY KEY,
    department       VARCHAR2(50) NOT NULL,
    access_level     VARCHAR2(20) DEFAULT 'LEVEL_1',
    last_login       TIMESTAMP,
    CONSTRAINT fk_admin_user FOREIGN KEY (user_id) REFERENCES user_master(user_id) ON DELETE CASCADE
);

-- ---------------------------------------------------------------------------
-- 4. PARKING INFRASTRUCTURE
-- ---------------------------------------------------------------------------
CREATE TABLE parking_lot (
    lot_id           NUMBER(10) PRIMARY KEY,
    zone_id          NUMBER(10) NOT NULL,
    manager_id       NUMBER(10),
    lot_name         VARCHAR2(100) NOT NULL,
    address          VARCHAR2(255) NOT NULL,
    latitude         NUMBER(10,6),
    longitude        NUMBER(10,6),
    total_slots      NUMBER(6) DEFAULT 0,
    is_active        NUMBER(1) DEFAULT 1 CHECK (is_active IN (0, 1)),
    CONSTRAINT fk_lot_zone FOREIGN KEY (zone_id) REFERENCES zone_config(zone_id),
    CONSTRAINT fk_lot_manager FOREIGN KEY (manager_id) REFERENCES admin_user(user_id) ON DELETE SET NULL
);

CREATE TABLE parking_attendant (
    user_id          NUMBER(10) PRIMARY KEY,
    lot_id           NUMBER(10),
    shift_start      VARCHAR2(10),
    shift_end        VARCHAR2(10),
    is_active        NUMBER(1) DEFAULT 1 CHECK (is_active IN (0, 1)),
    CONSTRAINT fk_attendant_user FOREIGN KEY (user_id) REFERENCES user_master(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_attendant_lot FOREIGN KEY (lot_id) REFERENCES parking_lot(lot_id) ON DELETE SET NULL
);

CREATE TABLE parking_slot (
    slot_id          NUMBER(10) PRIMARY KEY,
    lot_id           NUMBER(10) NOT NULL,
    slot_number      NUMBER(6) NOT NULL,
    slot_type        VARCHAR2(20) DEFAULT 'STANDARD' CHECK (slot_type IN ('STANDARD', 'COMPACT', 'LARGE', 'EV')),
    floor_level      NUMBER(3) DEFAULT 0,
    hourly_rate      NUMBER(8,2) NOT NULL CHECK (hourly_rate > 0),
    is_occupied      NUMBER(1) DEFAULT 0 CHECK (is_occupied IN (0, 1)),
    CONSTRAINT fk_slot_lot FOREIGN KEY (lot_id) REFERENCES parking_lot(lot_id) ON DELETE CASCADE,
    CONSTRAINT unq_lot_slot UNIQUE (lot_id, slot_number)
);

-- ---------------------------------------------------------------------------
-- 5. VEHICLE MANAGEMENT (EER Hierarchy)
-- ---------------------------------------------------------------------------
CREATE TABLE vehicle (
    vehicle_id       NUMBER(10) PRIMARY KEY,
    user_id          NUMBER(10) NOT NULL,
    license_plate    VARCHAR2(30) NOT NULL UNIQUE,
    registration_date DATE DEFAULT SYSDATE,
    is_verified      NUMBER(1) DEFAULT 0 CHECK (is_verified IN (0, 1)),
    vehicle_type     VARCHAR2(20) DEFAULT 'CAR' CHECK (vehicle_type IN ('CAR', 'BIKE', 'TRUCK', 'EV')),
    CONSTRAINT fk_vehicle_user FOREIGN KEY (user_id) REFERENCES registered_user(user_id) ON DELETE CASCADE
);

CREATE TABLE vehicle_car (
    vehicle_id         NUMBER(10) PRIMARY KEY,
    length_m           NUMBER(4,2),
    width_m            NUMBER(4,2),
    needs_ev_charging  NUMBER(1) DEFAULT 0,
    CONSTRAINT fk_car_vehicle FOREIGN KEY (vehicle_id) REFERENCES vehicle(vehicle_id) ON DELETE CASCADE
);

CREATE TABLE vehicle_bike (
    vehicle_id         NUMBER(10) PRIMARY KEY,
    engine_cc          NUMBER(5),
    is_electric        NUMBER(1) DEFAULT 0,
    CONSTRAINT fk_bike_vehicle FOREIGN KEY (vehicle_id) REFERENCES vehicle(vehicle_id) ON DELETE CASCADE
);

CREATE TABLE vehicle_truck (
    vehicle_id         NUMBER(10) PRIMARY KEY,
    max_weight_tons    NUMBER(6,2),
    height_m           NUMBER(4,2),
    axle_count         NUMBER(2),
    CONSTRAINT fk_truck_vehicle FOREIGN KEY (vehicle_id) REFERENCES vehicle(vehicle_id) ON DELETE CASCADE
);

CREATE TABLE vehicle_ev (
    vehicle_id           NUMBER(10) PRIMARY KEY,
    battery_capacity_kwh NUMBER(5,1),
    connector_type       VARCHAR2(30),
    charging_speed_kw    NUMBER(5,1),
    CONSTRAINT fk_ev_vehicle FOREIGN KEY (vehicle_id) REFERENCES vehicle(vehicle_id) ON DELETE CASCADE
);

-- ---------------------------------------------------------------------------
-- 6. TRANSACTIONS, LOGS & DISPUTES
-- ---------------------------------------------------------------------------
CREATE TABLE booking (
    booking_id       NUMBER(10) PRIMARY KEY,
    user_id          NUMBER(10) NOT NULL,
    vehicle_id       NUMBER(10) NOT NULL,
    slot_id          NUMBER(10) NOT NULL,
    start_time       TIMESTAMP NOT NULL,
    end_time         TIMESTAMP NOT NULL,
    status           VARCHAR2(20) DEFAULT 'CONFIRMED' CHECK (status IN ('PENDING', 'CONFIRMED', 'ACTIVE', 'COMPLETED', 'CANCELLED')),
    total_amount     NUMBER(10,2) NOT NULL,
    CONSTRAINT fk_book_user FOREIGN KEY (user_id) REFERENCES registered_user(user_id),
    CONSTRAINT fk_book_veh FOREIGN KEY (vehicle_id) REFERENCES vehicle(vehicle_id),
    CONSTRAINT fk_book_slot FOREIGN KEY (slot_id) REFERENCES parking_slot(slot_id),
    CONSTRAINT chk_book_time CHECK (end_time > start_time)
);

CREATE TABLE payment (
    payment_id          NUMBER(10) PRIMARY KEY,
    booking_id          NUMBER(10) NOT NULL,
    amount              NUMBER(10,2) NOT NULL CHECK (amount >= 0),
    payment_method      VARCHAR2(30) DEFAULT 'UPI' CHECK (payment_method IN ('UPI', 'CARD', 'WALLET', 'CASH')),
    status              VARCHAR2(20) DEFAULT 'SUCCESS' CHECK (status IN ('PENDING', 'SUCCESS', 'FAILED', 'REFUNDED')),
    transaction_ref     VARCHAR2(100),
    payment_timestamp   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_pay_booking FOREIGN KEY (booking_id) REFERENCES booking(booking_id) ON DELETE CASCADE
);

CREATE TABLE entry_exit_log (
    log_id              NUMBER(10) PRIMARY KEY,
    booking_id          NUMBER(10) NOT NULL UNIQUE,
    entry_time          TIMESTAMP,
    exit_time           TIMESTAMP,
    actual_duration_min NUMBER(8),
    overstay_min        NUMBER(8) DEFAULT 0,
    penalty_amount      NUMBER(10,2) DEFAULT 0.00,
    CONSTRAINT fk_log_booking FOREIGN KEY (booking_id) REFERENCES booking(booking_id) ON DELETE CASCADE
);

CREATE TABLE dispute (
    dispute_id          NUMBER(10) PRIMARY KEY,
    booking_id          NUMBER(10) NOT NULL,
    raised_by           NUMBER(10) NOT NULL,
    status              VARCHAR2(20) DEFAULT 'OPEN' CHECK (status IN ('OPEN', 'UNDER_REVIEW', 'RESOLVED', 'REJECTED')),
    resolution_notes    VARCHAR2(500),
    created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_disp_booking FOREIGN KEY (booking_id) REFERENCES booking(booking_id),
    CONSTRAINT fk_disp_user FOREIGN KEY (raised_by) REFERENCES registered_user(user_id)
);

COMMIT;
