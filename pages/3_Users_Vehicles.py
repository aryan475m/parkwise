import streamlit as st
from core import db, theme
from core.ui import crud

theme.header()
st.title("Users and vehicles")
users, vehicles = st.tabs(["Users", "Vehicles"])
with users:
    with st.expander("Register a new user"):
        with st.form("newuser", clear_on_submit=True):
            phone, email = st.text_input("Phone"), st.text_input("Email")
            if st.form_submit_button("Register"):
                try:
                    uid = db.next_id("user_master", "user_id")
                    db.execute("INSERT INTO user_master(user_id,phone,email,password_hash,user_type) VALUES(:i,:p,:e,'x','REGISTERED')",
                               {"i": uid, "p": phone, "e": email})
                    db.execute("INSERT INTO registered_user(user_id,kyc_status,wallet_balance) VALUES(:i,'PENDING',0)", {"i": uid})
                    st.success(f"User {uid} registered")
                    st.rerun()
                except Exception as e:
                    st.error(str(e))
    crud("registered_user", "user_id", {"kyc_status": ["PENDING", "VERIFIED", "REJECTED"], "wallet_balance": "float",
                                         "default_payment_method": ["UPI", "CARD", "WALLET", "CASH"]}, allow=("update", "delete"))
with vehicles:
    with st.expander("Register a vehicle"):
        with st.form("newveh", clear_on_submit=True):
            uid = int(st.number_input("Owner user id", step=1, value=1))
            plate = st.text_input("Plate (TN 22 AB 1234)")
            vtype = st.selectbox("Type", ["CAR", "BIKE", "TRUCK", "EV"])
            if st.form_submit_button("Register vehicle"):
                try:
                    db.register_vehicle(uid, plate, vtype)
                    st.success("Vehicle registered")
                    st.rerun()
                except Exception as e:
                    st.error(str(e))
    crud("vehicle", "vehicle_id", {"is_verified": [1, 0], "vehicle_type": ["CAR", "BIKE", "TRUCK", "EV"]}, allow=("update", "delete"))
