"""Reusable CRUD block: table view + insert / update / delete forms. Pages only configure it."""
import streamlit as st
from core import db


def _widget(label, spec, key):
    if isinstance(spec, list):
        return st.selectbox(label, spec, key=key)
    if spec == "int":
        return int(st.number_input(label, step=1, value=0, key=key))
    if spec == "float":
        return float(st.number_input(label, value=0.0, key=key))
    return st.text_input(label, key=key)


def crud(table, pk, cols, allow=("insert", "update", "delete")):
    """cols = {column: 'text' | 'int' | 'float' | [choices]}. Oracle tables need defaults on columns not listed."""
    rows = db.query(f"SELECT * FROM {table} ORDER BY {pk}")
    st.dataframe(rows, width="stretch", hide_index=True)
    tabs = st.tabs([a.title() for a in allow])
    for tab, action in zip(tabs, allow):
        with tab:
            if action == "insert":
                with st.form(f"{table}_ins", clear_on_submit=True):
                    vals = {c: _widget(c, s, f"{table}_i_{c}") for c, s in cols.items()}
                    if st.form_submit_button("Add row"):
                        try:
                            vals[pk] = db.next_id(table, pk)
                            db.execute(f"INSERT INTO {table}({','.join(vals)}) VALUES({','.join(':' + k for k in vals)})", vals)
                            st.success(f"Added {table} {vals[pk]}")
                            st.rerun()
                        except Exception as e:
                            st.error(str(e))
            elif action == "update" and rows:
                rid = st.selectbox(pk, [r[pk] for r in rows], key=f"{table}_u_id")
                col = st.selectbox("Column", list(cols), key=f"{table}_u_col")
                val = _widget("New value", cols[col], f"{table}_u_val")
                if st.button("Save change", key=f"{table}_u_btn"):
                    try:
                        db.execute(f"UPDATE {table} SET {col}=:v WHERE {pk}=:i", {"v": val, "i": rid})
                        st.success("Updated")
                        st.rerun()
                    except Exception as e:
                        st.error(str(e))
            elif action == "delete" and rows:
                rid = st.selectbox(pk, [r[pk] for r in rows], key=f"{table}_d_id")
                ok = st.checkbox("I understand this cannot be undone", key=f"{table}_d_ok")
                if st.button("Delete row", key=f"{table}_d_btn", disabled=not ok):
                    try:
                        db.execute(f"DELETE FROM {table} WHERE {pk}=:i", {"i": rid})
                        st.success("Deleted")
                        st.rerun()
                    except Exception as e:
                        st.error(str(e))
