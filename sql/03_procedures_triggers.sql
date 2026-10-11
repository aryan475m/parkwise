-- ============================================================================
-- PARKWISW SMART PARKING SYSTEM — PL/SQL PROCEDURES, FUNCTIONS & TRIGGERS
-- Oracle Database 21c Compatible
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. PROCEDURE: BookParkingSlot
-- Invoked by Streamlit UI to reserve a slot and record payment atomically.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE BookParkingSlot (
    p_user_id      IN  NUMBER,
    p_vehicle_id   IN  NUMBER,
    p_slot_id      IN  NUMBER,
    p_start        IN  TIMESTAMP,
    p_end          IN  TIMESTAMP,
    p_method       IN  VARCHAR2,
    p_booking_id   OUT NUMBER,
    p_total        OUT NUMBER
) AS
    v_clash_count  NUMBER;
    v_rate         NUMBER(8,2);
    v_mult         NUMBER(4,2);
    v_ev_disc      NUMBER(4,2);
    v_vtype        VARCHAR2(20);
    v_hours        NUMBER;
    v_pay_id       NUMBER;
    v_diff_days    NUMBER;
BEGIN
    -- Check for overlapping bookings
    SELECT COUNT(*)
      INTO v_clash_count
      FROM booking
     WHERE slot_id = p_slot_id
       AND status NOT IN ('CANCELLED', 'COMPLETED')
       AND start_time < p_end
       AND end_time > p_start;

    IF v_clash_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'slot already booked for that time window');
    END IF;

    -- Fetch slot rate and zone multiplier
    SELECT s.hourly_rate, z.peak_multiplier, z.ev_discount
      INTO v_rate, v_mult, v_ev_disc
      FROM parking_slot s
      JOIN parking_lot l ON s.lot_id = l.lot_id
      JOIN zone_config z ON l.zone_id = z.zone_id
     WHERE s.slot_id = p_slot_id;

    -- Compute duration in hours (minimum 1 hour ceiling)
    v_diff_days := CAST(p_end AS DATE) - CAST(p_start AS DATE);
    v_hours     := CEIL(v_diff_days * 24);
    IF v_hours < 1 THEN
        v_hours := 1;
    END IF;

    -- Check vehicle type for EV discount
    SELECT vehicle_type INTO v_vtype FROM vehicle WHERE vehicle_id = p_vehicle_id;
    IF v_vtype = 'EV' THEN
        p_total := ROUND(v_rate * v_hours * v_mult * (1.00 - v_ev_disc), 2);
    ELSE
        p_total := ROUND(v_rate * v_hours * v_mult, 2);
    END IF;

    -- Generate Booking ID
    SELECT seq_booking.NEXTVAL INTO p_booking_id FROM dual;

    -- Insert Booking
    INSERT INTO booking (
        booking_id, user_id, vehicle_id, slot_id, start_time, end_time, status, total_amount
    ) VALUES (
        p_booking_id, p_user_id, p_vehicle_id, p_slot_id, p_start, p_end, 'CONFIRMED', p_total
    );

    -- Insert Payment
    SELECT seq_payment.NEXTVAL INTO v_pay_id FROM dual;
    INSERT INTO payment (
        payment_id, booking_id, amount, payment_method, status, transaction_ref, payment_timestamp
    ) VALUES (
        v_pay_id, p_booking_id, p_total, p_method, 'SUCCESS',
        'TXN_' || p_booking_id || '_' || TO_CHAR(SYSDATE, 'HH24MISS'), SYSDATE
    );

    -- Mark slot occupied
    UPDATE parking_slot SET is_occupied = 1 WHERE slot_id = p_slot_id;

    COMMIT;
END BookParkingSlot;
/

-- ---------------------------------------------------------------------------
-- 2. PROCEDURE: ProcessVehicleExit
-- Invoked by Streamlit UI when vehicle departs, calculating overstay penalties.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE ProcessVehicleExit (
    p_booking_id IN NUMBER,
    p_exit_time  IN TIMESTAMP
) AS
    v_slot_id    NUMBER;
    v_start_time TIMESTAMP;
    v_end_time   TIMESTAMP;
    v_duration   NUMBER;
    v_overstay   NUMBER := 0;
    v_penalty    NUMBER(10,2) := 0.00;
    v_status     VARCHAR2(20);
BEGIN
    SELECT slot_id, start_time, end_time, status
      INTO v_slot_id, v_start_time, v_end_time, v_status
      FROM booking
     WHERE booking_id = p_booking_id;

    IF v_status = 'COMPLETED' THEN
        RAISE_APPLICATION_ERROR(-20002, 'Vehicle exit has already been processed for this booking.');
    END IF;

    -- Compute duration and overstay minutes
    v_duration := ROUND((CAST(p_exit_time AS DATE) - CAST(v_start_time AS DATE)) * 24 * 60);

    IF p_exit_time > v_end_time THEN
        v_overstay := ROUND((CAST(p_exit_time AS DATE) - CAST(v_end_time AS DATE)) * 24 * 60);
        -- 50 Rs per hour of overstay penalty rate
        v_penalty  := ROUND((v_overstay / 60) * 50.00, 2);
    END IF;

    -- Mark booking completed
    UPDATE booking
       SET status = 'COMPLETED'
     WHERE booking_id = p_booking_id;

    -- Upsert Entry/Exit log
    MERGE INTO entry_exit_log l
    USING (SELECT p_booking_id AS bid FROM dual) d
    ON (l.booking_id = d.bid)
    WHEN MATCHED THEN
        UPDATE SET exit_time = p_exit_time,
                   actual_duration_min = v_duration,
                   overstay_min = v_overstay,
                   penalty_amount = v_penalty
    WHEN NOT MATCHED THEN
        INSERT (log_id, booking_id, entry_time, exit_time, actual_duration_min, overstay_min, penalty_amount)
        VALUES (seq_entry_exit_log.NEXTVAL, p_booking_id, v_start_time, p_exit_time, v_duration, v_overstay, v_penalty);

    -- Free up parking slot
    UPDATE parking_slot
       SET is_occupied = 0
     WHERE slot_id = v_slot_id;

    COMMIT;
END ProcessVehicleExit;
/

-- ---------------------------------------------------------------------------
-- 3. PROCEDURE: sp_register_vehicle
-- Invoked by Streamlit UI to register a vehicle with verification.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_register_vehicle (
    p_user_id    IN  NUMBER,
    p_plate      IN  VARCHAR2,
    p_type       IN  VARCHAR2,
    p_attr1      IN  VARCHAR2,
    p_attr2      IN  VARCHAR2,
    p_attr3      IN  VARCHAR2,
    p_vehicle_id OUT NUMBER
) AS
BEGIN
    SELECT seq_vehicle.NEXTVAL INTO p_vehicle_id FROM dual;

    INSERT INTO vehicle (
        vehicle_id, user_id, license_plate, registration_date, is_verified, vehicle_type
    ) VALUES (
        p_vehicle_id, p_user_id, UPPER(TRIM(p_plate)), SYSDATE, 1, UPPER(TRIM(p_type))
    );

    -- Insert default subclass details based on vehicle category
    IF UPPER(TRIM(p_type)) = 'CAR' THEN
        INSERT INTO vehicle_car (vehicle_id, length_m, width_m, needs_ev_charging)
        VALUES (p_vehicle_id, 4.2, 1.8, 0);
    ELSIF UPPER(TRIM(p_type)) = 'BIKE' THEN
        INSERT INTO vehicle_bike (vehicle_id, engine_cc, is_electric)
        VALUES (p_vehicle_id, 150, 0);
    ELSIF UPPER(TRIM(p_type)) = 'EV' THEN
        INSERT INTO vehicle_ev (vehicle_id, battery_capacity_kwh, connector_type, charging_speed_kw)
        VALUES (p_vehicle_id, 50.0, 'CCS2', 30.0);
    ELSIF UPPER(TRIM(p_type)) = 'TRUCK' THEN
        INSERT INTO vehicle_truck (vehicle_id, max_weight_tons, height_m, axle_count)
        VALUES (p_vehicle_id, 10.0, 3.5, 2);
    END IF;

    COMMIT;
END sp_register_vehicle;
/

-- ---------------------------------------------------------------------------
-- 4. FUNCTION: FindAvailableSlots
-- Returns a SYS_REFCURSOR to the Streamlit UI matching zone & vehicle type.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION FindAvailableSlots (
    p_zone         IN VARCHAR2,
    p_vehicle_type IN VARCHAR2,
    p_start        IN TIMESTAMP,
    p_end          IN TIMESTAMP
) RETURN SYS_REFCURSOR AS
    rc SYS_REFCURSOR;
BEGIN
    OPEN rc FOR
        SELECT s.slot_id,
               l.lot_name,
               s.slot_number,
               s.slot_type,
               s.hourly_rate
          FROM parking_slot s
          JOIN parking_lot l ON l.lot_id = s.lot_id
          JOIN zone_config z ON z.zone_id = l.zone_id
         WHERE UPPER(z.zone_name) = UPPER(TRIM(p_zone))
           AND l.is_active = 1
           AND NOT (UPPER(TRIM(p_vehicle_type)) <> 'EV' AND s.slot_type = 'EV')
           AND NOT EXISTS (
               SELECT 1
                 FROM booking b
                WHERE b.slot_id = s.slot_id
                  AND b.status NOT IN ('CANCELLED', 'COMPLETED')
                  AND b.start_time < p_end
                  AND b.end_time > p_start
           )
         ORDER BY s.hourly_rate ASC, s.slot_number ASC;

    RETURN rc;
END FindAvailableSlots;
/

-- ---------------------------------------------------------------------------
-- 5. TRIGGER: Maintain Lot Slot Count
-- Automatically updates total_slots in parking_lot when slots are added/deleted.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_maintain_lot_slot_count
AFTER INSERT OR DELETE ON parking_slot
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        UPDATE parking_lot
           SET total_slots = total_slots + 1
         WHERE lot_id = :NEW.lot_id;
    ELSIF DELETING THEN
        UPDATE parking_lot
           SET total_slots = total_slots - 1
         WHERE lot_id = :OLD.lot_id;
    END IF;
END;
/

COMMIT;
