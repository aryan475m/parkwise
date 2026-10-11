# ParkWise

Streamlit front end for the ParkWise Smart Parking & Reservation System (DBMS DA2).
Shows insert, update and delete against the database, plus the stored procedures and functions.

## Run it

```bash
python -m venv .venv && source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install -r requirements.txt
streamlit run app.py
```

With no database settings it runs on built-in sample data (mock mode), so the UI works on any laptop.

## Connect to Oracle (backend)

1. Set up the schema, seed data, and stored procedures in your Oracle database using the provided scripts:
   ```sql
   -- In SQL*Plus connected as your user:
   @sql/run_setup.sql
   ```
2. Copy `.env.example` to `.env` and fill in your Oracle credentials:
   ```bash
   cp .env.example .env        # fill ORA_USER, ORA_PASSWORD, ORA_DSN
   ```
   *(The application automatically detects and loads `.env` across Windows, macOS, and Linux).*

3. Start the application:
   ```bash
   streamlit run app.py
   ```

When `ORA_DSN` is set, every page connects live to Oracle. Nothing else changes.

## What the backend must provide (all database access is in `core/db.py`)

Tables and columns named exactly as in the TRD. For inserts from the UI, each table needs a sequence `seq_<table>`
and defaults on columns the form does not send (for example `total_slots` DEFAULT 0, `is_occupied` DEFAULT 0).

| UI action | Oracle object |
|---|---|
| New booking | `BookParkingSlot(p_user_id, p_vehicle_id, p_slot_id, p_start, p_end, p_method, OUT p_booking_id, OUT p_total)` |
| Vehicle exit | `ProcessVehicleExit(p_booking_id, p_exit_time)` |
| Register vehicle | `sp_register_vehicle(p_user_id, p_plate, p_type, p_attr1, p_attr2, p_attr3, OUT p_vehicle_id)` |
| Find a slot | `FindAvailableSlots(p_zone, p_vehicle_type, p_start, p_end) RETURN SYS_REFCURSOR` |

If a signature differs, change only the matching function in `core/db.py`. Oracle errors (ORA-xxxxx, -200xx)
are shown in the UI as messages.

## Layout

```
app.py                 overview
pages/                 Infrastructure, Bookings, Users & Vehicles
core/db.py             the only file that touches the database (Oracle or mock)
core/ui.py             reusable table + insert/update/delete block
```

## Put it on GitHub

```bash
git init && git add . && git commit -m "ParkWise front end"
git branch -M main
git remote add origin https://github.com/<your-username>/parkwise.git
git push -u origin main
```

Create the empty `parkwise` repository on github.com first. `.env` is git-ignored, so passwords are never pushed.
