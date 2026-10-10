import streamlit as st
from core import db, theme

st.set_page_config(page_title="ParkWise", page_icon="🅿️", layout="wide")
theme.header()

if db.MOCK:
    st.warning("Sample-data mode: set ORA_USER, ORA_PASSWORD and ORA_DSN to use the Oracle database.")
else:
    st.success("Connected to Oracle.")

st.subheader("Overview")
counts = {"Parking lots": "parking_lot", "Parking slots": "parking_slot", "Users": "user_master",
          "Vehicles": "vehicle", "Bookings": "booking", "Open disputes": "dispute"}
cols = st.columns(len(counts))
for col, (label, table) in zip(cols, counts.items()):
    try:
        extra = " WHERE status='OPEN'" if table == "dispute" else ""
        col.metric(label, db.query(f"SELECT COUNT(*) AS n FROM {table}{extra}")[0]["n"])
    except Exception as e:
        col.metric(label, "n/a"); col.caption(str(e)[:60])
st.info("Use the sidebar: Infrastructure, Bookings, Users & Vehicles.")
