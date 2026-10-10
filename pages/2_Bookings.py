import streamlit as st
from datetime import datetime, timedelta
from core import db, theme
from core.ui import crud

theme.header()
st.title("Bookings")
view, new, status, pay, exit_, disp = st.tabs(["All bookings", "New booking", "Change status", "Payments", "Vehicle exit", "Disputes"])
with view:
    st.dataframe(db.query("SELECT * FROM booking ORDER BY booking_id"), width="stretch", hide_index=True)
with new:
    with st.form("book"):
        a, b, c = st.columns(3)
        uid = int(a.number_input("User id", step=1, value=1))
        vid = int(b.number_input("Vehicle id", step=1, value=1))
        sid = int(c.number_input("Slot id", step=1, value=1))
        d1, d2, d3 = st.columns(3)
        day = d1.date_input("Date", datetime.now())
        t1 = d2.time_input("From", datetime.now().replace(minute=0).time())
        t2 = d3.time_input("To", (datetime.now() + timedelta(hours=2)).replace(minute=0).time())
        method = st.selectbox("Payment method", ["UPI", "CARD", "WALLET", "CASH"])
        if st.form_submit_button("Book slot"):
            try:
                bid, total = db.book_slot(uid, vid, sid, datetime.combine(day, t1), datetime.combine(day, t2), method)
                st.success(f"Booking {bid} confirmed. Total ₹{total:.2f}")
            except Exception as e:
                st.error(str(e))
with status:
    crud("booking", "booking_id", {"status": ["PENDING", "CONFIRMED", "ACTIVE", "COMPLETED", "CANCELLED"]}, allow=("update",))
with pay:
    crud("payment", "payment_id", {"status": ["PENDING", "SUCCESS", "FAILED", "REFUNDED"]}, allow=("update",))
with exit_:
    bid = int(st.number_input("Booking id", step=1, value=1, key="exit_bid"))
    when = st.time_input("Exit time", datetime.now().time())
    if st.button("Record exit"):
        try:
            db.process_exit(bid, datetime.combine(datetime.now().date(), when))
            st.success("Exit recorded; booking completed.")
        except Exception as e:
            st.error(str(e))
with disp:
    crud("dispute", "dispute_id", {"booking_id": "int", "raised_by": "int",
                                    "status": ["OPEN", "UNDER_REVIEW", "RESOLVED", "REJECTED"], "resolution_notes": "text"})
