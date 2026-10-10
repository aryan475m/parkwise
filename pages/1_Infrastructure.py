import streamlit as st
from datetime import datetime, timedelta
from core import db, theme
from core.ui import crud

theme.header()
st.title("Parking infrastructure")
lots, slots, search = st.tabs(["Lots", "Slots", "Find a slot"])
with lots:
    crud("parking_lot", "lot_id", {"zone_id": "int", "lot_name": "text", "address": "text", "is_active": [1, 0]})
with slots:
    crud("parking_slot", "slot_id", {"lot_id": "int", "slot_number": "int", "slot_type": ["STANDARD", "COMPACT", "LARGE", "EV"],
                                      "floor_level": "int", "hourly_rate": "float"})
with search:
    c1, c2, c3 = st.columns(3)
    zone = c1.selectbox("Zone", ["NORTH", "SOUTH", "EAST", "WEST", "CENTRAL"])
    vtype = c2.selectbox("Vehicle type", ["CAR", "BIKE", "TRUCK", "EV"])
    day = c3.date_input("Date", datetime.now())
    t1, t2 = st.columns(2)
    start = datetime.combine(day, t1.time_input("From", datetime.now().replace(minute=0).time()))
    end = datetime.combine(day, t2.time_input("To", (datetime.now() + timedelta(hours=2)).replace(minute=0).time()))
    if st.button("Search"):
        try:
            res = db.find_slots(zone, vtype, start, end)
            if res:
                st.dataframe(res, width="stretch", hide_index=True)
            else:
                st.info("No free slots for that window.")
        except Exception as e:
            st.error(str(e))
