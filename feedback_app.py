import os
import streamlit as st
import pandas as pd

st.set_page_config(page_title="Customer Feedback", layout="wide", page_icon="📋")

# ── Local vs Snowflake mode ──────────────────────────────────────────────────
# Set LOCAL_MODE=true to run locally with mock data: streamlit run feedback_app.py
LOCAL_MODE = os.getenv("LOCAL_MODE", "false").lower() == "true"

if LOCAL_MODE:
    MOCK_DATA = pd.DataFrame({
        "FEEDBACK_ID":   [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
        "CUSTOMER_NAME": ["Anna Müller", "Thomas Bauer", "Sofia Klein", "Markus Weber",
                          "Laura Schmidt", "Jan Fischer", "Emma Hoffmann", "Lukas Braun",
                          "Nina Wolf", "Felix Richter"],
        "PRODUCT":       ["AI Dashboard", "Data Pipeline", "AI Dashboard", "Data Pipeline",
                          "Cortex Search", "Cortex Search", "AI Dashboard", "Data Pipeline",
                          "Cortex Search", "AI Dashboard"],
        "FEEDBACK_TEXT": [
            "Absolutely love the new dashboard. Everything is fast, clear, and intuitive.",
            "The pipeline setup was straightforward and the documentation was helpful.",
            "It is okay. Not bad, not great. Some features are missing but it gets the job done.",
            "Very disappointing. The pipeline crashed twice and support took three days to respond.",
            "The semantic search is impressive. Found relevant documents even without exact keywords.",
            "Search results are sometimes irrelevant. We expected better accuracy for the price.",
            "The onboarding experience was smooth. The team was up and running within a day.",
            "Nothing works as advertised. Constant errors, poor logging, extremely frustrated.",
            "Decent product. Some rough edges but the core functionality is solid.",
            "Outstanding support team. They resolved our issue within hours.",
        ],
        "SUBMITTED_AT": pd.to_datetime([
            "2026-05-01", "2026-05-03", "2026-05-05", "2026-05-07", "2026-05-09",
            "2026-05-11", "2026-05-13", "2026-05-15", "2026-05-17", "2026-05-19",
        ]),
    })

    def load_data():
        return MOCK_DATA.copy()
else:
    from snowflake.snowpark.context import get_active_session
    session = get_active_session()

    @st.cache_data(ttl=60)
    def load_data():
        return session.sql("""
            SELECT FEEDBACK_ID, CUSTOMER_NAME, PRODUCT, SUBMITTED_AT, FEEDBACK_TEXT
            FROM ENTERPRISE_DB.AI_SCHEMA.CUSTOMER_FEEDBACK
            ORDER BY SUBMITTED_AT DESC
        """).to_pandas()

# ── Negative keyword flag (replaces AI sentiment on trial account) ────────────
RISK_KEYWORDS = [
    "crashed", "damaged", "disappointed", "frustrated", "never", "worst",
    "terrible", "broken", "error", "poor", "awful", "useless", "slow",
    "delayed", "wrong", "missing", "lost", "failed", "failure", "horrible",
    "unacceptable", "refund", "angry", "ridiculous", "unusable"
]

def is_at_risk(text: str) -> bool:
    t = text.lower()
    return any(kw in t for kw in RISK_KEYWORDS)

# ── Load & enrich ─────────────────────────────────────────────────────────────
df = load_data()
df["AT_RISK"] = df["FEEDBACK_TEXT"].apply(is_at_risk)
df["SUBMITTED_AT"] = pd.to_datetime(df["SUBMITTED_AT"])

# ── Sidebar filters ───────────────────────────────────────────────────────────
with st.sidebar:
    st.title("Filters")
    if LOCAL_MODE:
        st.info("Running in local mode")

    search = st.text_input("Search customer or keyword", placeholder="e.g. Anna, delivery...")

    products = ["All"] + sorted(df["PRODUCT"].unique().tolist())
    selected_product = st.selectbox("Product", products)

    min_date = df["SUBMITTED_AT"].min().date()
    max_date = df["SUBMITTED_AT"].max().date()
    date_range = st.date_input("Date range", value=(min_date, max_date), min_value=min_date, max_value=max_date)

    at_risk_only = st.checkbox("At-risk customers only", value=False)

# ── Apply filters ─────────────────────────────────────────────────────────────
filtered = df.copy()

if search:
    mask = (
        filtered["CUSTOMER_NAME"].str.contains(search, case=False, na=False) |
        filtered["FEEDBACK_TEXT"].str.contains(search, case=False, na=False)
    )
    filtered = filtered[mask]

if selected_product != "All":
    filtered = filtered[filtered["PRODUCT"] == selected_product]

if len(date_range) == 2:
    start = pd.Timestamp(date_range[0])
    end   = pd.Timestamp(date_range[1])
    filtered = filtered[(filtered["SUBMITTED_AT"] >= start) & (filtered["SUBMITTED_AT"] <= end)]

if at_risk_only:
    filtered = filtered[filtered["AT_RISK"]]

# ── KPI cards ─────────────────────────────────────────────────────────────────
st.title("Customer Feedback Dashboard")

col1, col2, col3, col4 = st.columns(4)
col1.metric("Total feedback",     len(filtered))
col2.metric("At-risk customers",  int(filtered["AT_RISK"].sum()))
col3.metric("Products",           filtered["PRODUCT"].nunique())
risk_pct = int(filtered["AT_RISK"].mean() * 100) if len(filtered) > 0 else 0
col4.metric("Risk rate",          f"{risk_pct}%")

st.divider()

# ── Row styling ───────────────────────────────────────────────────────────────
def style_rows(row):
    if row["AT_RISK"]:
        return ["background-color: #fee2e2; color: #7f1d1d"] * len(row)
    return [""] * len(row)

display_cols = ["CUSTOMER_NAME", "PRODUCT", "SUBMITTED_AT", "FEEDBACK_TEXT", "AT_RISK"]

# ── Tabs ──────────────────────────────────────────────────────────────────────
tab1, tab2 = st.tabs(["All Feedback", "At-Risk Only"])

with tab1:
    base = filtered[display_cols].reset_index(drop=True)
    st.dataframe(base.style.apply(style_rows, axis=1).hide(axis="index"), use_container_width=True)

with tab2:
    at_risk_df = filtered[filtered["AT_RISK"]][display_cols].reset_index(drop=True)
    if at_risk_df.empty:
        st.success("No at-risk customers match the current filters.")
    else:
        st.dataframe(at_risk_df.style.apply(style_rows, axis=1).hide(axis="index"), use_container_width=True)
        st.caption(f"{len(at_risk_df)} customers flagged for follow-up")
