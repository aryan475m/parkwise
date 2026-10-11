-- ============================================================================
-- PARKWISW SMART PARKING SYSTEM — SEED DATA SCRIPT
-- Oracle Database 21c Compatible
-- ============================================================================

-- 1. ZONES
INSERT INTO zone_config (zone_id, zone_name, region_code, peak_multiplier, ev_discount) VALUES (1, 'NORTH', 'N01', 1.30, 0.10);
INSERT INTO zone_config (zone_id, zone_name, region_code, peak_multiplier, ev_discount) VALUES (2, 'SOUTH', 'S01', 1.20, 0.10);
INSERT INTO zone_config (zone_id, zone_name, region_code, peak_multiplier, ev_discount) VALUES (3, 'CENTRAL', 'C01', 1.50, 0.15);
INSERT INTO zone_config (zone_id, zone_name, region_code, peak_multiplier, ev_discount) VALUES (4, 'EAST', 'E01', 1.10, 0.10);
INSERT INTO zone_config (zone_id, zone_name, region_code, peak_multiplier, ev_discount) VALUES (5, 'WEST', 'W01', 1.25, 0.10);

-- 2. USERS (Master, Registered, Admin)
INSERT INTO user_master (user_id, phone, email, password_hash, user_type) VALUES (1, '9876500001', 'asha@mail.com', 'hash_asha', 'REGISTERED');
INSERT INTO registered_user (user_id, kyc_status, wallet_balance, default_payment_method) VALUES (1, 'VERIFIED', 500.00, 'UPI');

INSERT INTO user_master (user_id, phone, email, password_hash, user_type) VALUES (2, '9876500002', 'ravi@mail.com', 'hash_ravi', 'REGISTERED');
INSERT INTO registered_user (user_id, kyc_status, wallet_balance, default_payment_method) VALUES (2, 'PENDING', 120.00, 'CARD');

INSERT INTO user_master (user_id, phone, email, password_hash, user_type) VALUES (3, '9876500003', 'meena@mail.com', 'hash_meena', 'REGISTERED');
INSERT INTO registered_user (user_id, kyc_status, wallet_balance, default_payment_method) VALUES (3, 'VERIFIED', 750.00, 'WALLET');

INSERT INTO user_master (user_id, phone, email, password_hash, user_type) VALUES (4, '9876500004', 'vikram@mail.com', 'hash_vikram', 'REGISTERED');
INSERT INTO registered_user (user_id, kyc_status, wallet_balance, default_payment_method) VALUES (4, 'VERIFIED', 300.00, 'UPI');

INSERT INTO user_master (user_id, phone, email, password_hash, user_type) VALUES (5, '9876500099', 'admin@parkwise.city', 'hash_admin', 'ADMIN');
INSERT INTO admin_user (user_id, department, access_level, last_login) VALUES (5, 'MUNICIPAL_TRANSPORT', 'SUPERADMIN', SYSDATE);

-- 3. PARKING LOTS
INSERT INTO parking_lot (lot_id, zone_id, manager_id, lot_name, address, latitude, longitude, total_slots, is_active)
VALUES (1, 1, 5, 'Anna Nagar Plaza', '2nd Avenue, Anna Nagar', 13.0827, 80.2107, 4, 1);

INSERT INTO parking_lot (lot_id, zone_id, manager_id, lot_name, address, latitude, longitude, total_slots, is_active)
VALUES (2, 2, 5, 'Adyar Hub', 'L.B. Road, Adyar', 13.0012, 80.2565, 4, 1);

INSERT INTO parking_lot (lot_id, zone_id, manager_id, lot_name, address, latitude, longitude, total_slots, is_active)
VALUES (3, 3, 5, 'T Nagar Deck', 'Usman Road, T Nagar', 13.0418, 80.2341, 4, 1);

INSERT INTO parking_lot (lot_id, zone_id, manager_id, lot_name, address, latitude, longitude, total_slots, is_active)
VALUES (4, 4, 5, 'Marina Promenade Lot', 'Kamarajar Salai, Marina', 13.0500, 80.2824, 4, 0);

-- 4. PARKING SLOTS
-- Lot 1 (Anna Nagar)
INSERT INTO parking_slot (slot_id, lot_id, slot_number, slot_type, floor_level, hourly_rate, is_occupied) VALUES (1, 1, 1, 'STANDARD', 0, 40.00, 0);
INSERT INTO parking_slot (slot_id, lot_id, slot_number, slot_type, floor_level, hourly_rate, is_occupied) VALUES (2, 1, 2, 'COMPACT', 0, 30.00, 0);
INSERT INTO parking_slot (slot_id, lot_id, slot_number, slot_type, floor_level, hourly_rate, is_occupied) VALUES (3, 1, 3, 'LARGE', 1, 55.00, 0);
INSERT INTO parking_slot (slot_id, lot_id, slot_number, slot_type, floor_level, hourly_rate, is_occupied) VALUES (4, 1, 4, 'EV', 1, 80.00, 0);

-- Lot 2 (Adyar)
INSERT INTO parking_slot (slot_id, lot_id, slot_number, slot_type, floor_level, hourly_rate, is_occupied) VALUES (5, 2, 1, 'STANDARD', 0, 35.00, 0);
INSERT INTO parking_slot (slot_id, lot_id, slot_number, slot_type, floor_level, hourly_rate, is_occupied) VALUES (6, 2, 2, 'COMPACT', 0, 28.00, 0);
INSERT INTO parking_slot (slot_id, lot_id, slot_number, slot_type, floor_level, hourly_rate, is_occupied) VALUES (7, 2, 3, 'LARGE', 0, 50.00, 0);
INSERT INTO parking_slot (slot_id, lot_id, slot_number, slot_type, floor_level, hourly_rate, is_occupied) VALUES (8, 2, 4, 'EV', 0, 75.00, 0);

-- Lot 3 (T Nagar)
INSERT INTO parking_slot (slot_id, lot_id, slot_number, slot_type, floor_level, hourly_rate, is_occupied) VALUES (9, 3, 1, 'STANDARD', 0, 45.00, 0);
INSERT INTO parking_slot (slot_id, lot_id, slot_number, slot_type, floor_level, hourly_rate, is_occupied) VALUES (10, 3, 2, 'COMPACT', 0, 35.00, 0);
INSERT INTO parking_slot (slot_id, lot_id, slot_number, slot_type, floor_level, hourly_rate, is_occupied) VALUES (11, 3, 3, 'LARGE', 0, 60.00, 0);
INSERT INTO parking_slot (slot_id, lot_id, slot_number, slot_type, floor_level, hourly_rate, is_occupied) VALUES (12, 3, 4, 'EV', 0, 85.00, 0);

-- 5. VEHICLES & SPECIALIZATIONS
INSERT INTO vehicle (vehicle_id, user_id, license_plate, registration_date, is_verified, vehicle_type) VALUES (1, 1, 'TN 22 AB 1234', DATE '2026-08-02', 1, 'CAR');
INSERT INTO vehicle_car (vehicle_id, length_m, width_m, needs_ev_charging) VALUES (1, 4.20, 1.75, 0);

INSERT INTO vehicle (vehicle_id, user_id, license_plate, registration_date, is_verified, vehicle_type) VALUES (2, 2, 'TN 10 CD 5678', DATE '2026-08-04', 1, 'BIKE');
INSERT INTO vehicle_bike (vehicle_id, engine_cc, is_electric) VALUES (2, 150, 0);

INSERT INTO vehicle (vehicle_id, user_id, license_plate, registration_date, is_verified, vehicle_type) VALUES (3, 3, 'TN 01 EF 9012', DATE '2026-08-06', 1, 'EV');
INSERT INTO vehicle_ev (vehicle_id, battery_capacity_kwh, connector_type, charging_speed_kw) VALUES (3, 60.5, 'CCS2', 50.0);

INSERT INTO vehicle (vehicle_id, user_id, license_plate, registration_date, is_verified, vehicle_type) VALUES (4, 4, 'TN 07 GH 3456', DATE '2026-08-10', 1, 'TRUCK');
INSERT INTO vehicle_truck (vehicle_id, max_weight_tons, height_m, axle_count) VALUES (4, 12.50, 3.80, 3);

-- 6. BOOKINGS, PAYMENTS & LOGS
INSERT INTO booking (booking_id, user_id, vehicle_id, slot_id, start_time, end_time, status, total_amount)
VALUES (1, 1, 1, 1, TIMESTAMP '2026-10-12 09:00:00', TIMESTAMP '2026-10-12 11:00:00', 'CONFIRMED', 80.00);

INSERT INTO payment (payment_id, booking_id, amount, payment_method, status, transaction_ref, payment_timestamp)
VALUES (1, 1, 80.00, 'UPI', 'SUCCESS', 'TXN_9876501', TIMESTAMP '2026-10-11 14:00:00');

INSERT INTO entry_exit_log (log_id, booking_id, entry_time, exit_time, actual_duration_min, overstay_min, penalty_amount)
VALUES (1, 1, TIMESTAMP '2026-10-12 09:05:00', TIMESTAMP '2026-10-12 11:00:00', 115, 0, 0.00);

INSERT INTO booking (booking_id, user_id, vehicle_id, slot_id, start_time, end_time, status, total_amount)
VALUES (2, 2, 2, 6, TIMESTAMP '2026-10-12 10:00:00', TIMESTAMP '2026-10-12 12:00:00', 'ACTIVE', 56.00);

INSERT INTO payment (payment_id, booking_id, amount, payment_method, status, transaction_ref, payment_timestamp)
VALUES (2, 2, 56.00, 'CARD', 'SUCCESS', 'TXN_9876502', TIMESTAMP '2026-10-11 15:30:00');

INSERT INTO entry_exit_log (log_id, booking_id, entry_time, exit_time, actual_duration_min, overstay_min, penalty_amount)
VALUES (2, 2, TIMESTAMP '2026-10-12 10:00:00', NULL, NULL, 0, 0.00);

-- Past completed booking with overstay
INSERT INTO booking (booking_id, user_id, vehicle_id, slot_id, start_time, end_time, status, total_amount)
VALUES (3, 3, 3, 4, TIMESTAMP '2026-10-10 14:00:00', TIMESTAMP '2026-10-10 16:00:00', 'COMPLETED', 160.00);

INSERT INTO payment (payment_id, booking_id, amount, payment_method, status, transaction_ref, payment_timestamp)
VALUES (3, 3, 160.00, 'WALLET', 'SUCCESS', 'TXN_9876503', TIMESTAMP '2026-10-10 13:45:00');

INSERT INTO entry_exit_log (log_id, booking_id, entry_time, exit_time, actual_duration_min, overstay_min, penalty_amount)
VALUES (3, 3, TIMESTAMP '2026-10-10 14:02:00', TIMESTAMP '2026-10-10 16:45:00', 163, 45, 120.00);

-- 7. DISPUTE
INSERT INTO dispute (dispute_id, booking_id, raised_by, status, resolution_notes, created_at)
VALUES (1, 1, 1, 'OPEN', 'Slot sensor did not open boom barrier automatically on entry.', TIMESTAMP '2026-10-11 16:00:00');

COMMIT;
