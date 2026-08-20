"""
ImportFlow ERP — Operations & Lifecycle Board (Streamlit Dashboard)
لوحة متابعة وتتبع مراحل الشحنات الاستيرادية (5 مستويات كبرى - 21 خطوة تشغيلية)
"""

import streamlit as st
import sqlite3
import pandas as pd
from datetime import datetime, date
import json
import os

# ==============================================================================
# 1. PAGE CONFIGURATION & CUSTOM ENTERPRISE CSS
# ==============================================================================
st.set_page_config(
    page_title="ImportFlow ERP — Shipment Lifecycle Board",
    page_icon="🚢",
    layout="wide",
    initial_sidebar_state="expanded",
)

DB_PATH = os.path.join(os.path.dirname(__file__), "sorour_logistics.db")

# Custom CSS for the 5-Column Shipment Lifecycle Board (Matching the visual screenshot)
st.markdown("""
<style>
    @import url('https://fonts.googleapis.com/css2?family=Cairo:wght@400;600;700;800&family=Inter:wght@400;500;600;700;800&display=swap');
    
    html, body, [class*="css"] {
        font-family: 'Inter', 'Cairo', sans-serif;
    }
    
    .main-title-container {
        background: linear-gradient(135deg, #1e293b 0%, #0f172a 100%);
        padding: 18px 24px;
        border-radius: 10px;
        color: white;
        margin-bottom: 20px;
        box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
        display: flex;
        justify-content: space-between;
        align-items: center;
    }
    
    .main-title-text {
        font-size: 22px;
        font-weight: 800;
        letter-spacing: 0.3px;
    }
    
    .main-sub-text {
        font-size: 13px;
        color: #94a3b8;
        margin-top: 4px;
    }
    
    /* 6-Column Header Colors matching the 6 phases */
    .col-header-amber {
        background: #D35400;
        color: white;
        padding: 10px 10px;
        border-radius: 8px 8px 0 0;
        font-weight: 700;
        font-size: 13px;
        text-align: center;
        box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }

    .col-header-cobalt {
        background: #2980B9;
        color: white;
        padding: 10px 10px;
        border-radius: 8px 8px 0 0;
        font-weight: 700;
        font-size: 13px;
        text-align: center;
        box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }
    
    .col-header-emerald {
        background: #16A085;
        color: white;
        padding: 10px 10px;
        border-radius: 8px 8px 0 0;
        font-weight: 700;
        font-size: 13px;
        text-align: center;
        box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }
    
    .col-header-red {
        background: #C0392B;
        color: white;
        padding: 10px 10px;
        border-radius: 8px 8px 0 0;
        font-weight: 700;
        font-size: 13px;
        text-align: center;
        box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }
    
    .col-header-purple {
        background: #8E44AD;
        color: white;
        padding: 10px 10px;
        border-radius: 8px 8px 0 0;
        font-weight: 700;
        font-size: 13px;
        text-align: center;
        box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }
    
    .col-header-green {
        background: #27AE60;
        color: white;
        padding: 10px 10px;
        border-radius: 8px 8px 0 0;
        font-weight: 700;
        font-size: 13px;
        text-align: center;
        box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }

    .phase-body-amber   { background: rgba(211, 84, 0, 0.04);   border: 1px solid #D35400; border-top: none; border-radius: 0 0 8px 8px; padding: 6px; min-height: 480px; }
    .phase-body-cobalt  { background: rgba(41, 128, 185, 0.04); border: 1px solid #2980B9; border-top: none; border-radius: 0 0 8px 8px; padding: 6px; min-height: 480px; }
    .phase-body-emerald { background: rgba(22, 160, 133, 0.04); border: 1px solid #16A085; border-top: none; border-radius: 0 0 8px 8px; padding: 6px; min-height: 480px; }
    .phase-body-red     { background: rgba(192, 57, 43, 0.04);  border: 1px solid #C0392B; border-top: none; border-radius: 0 0 8px 8px; padding: 6px; min-height: 480px; }
    .phase-body-purple  { background: rgba(142, 68, 173, 0.04); border: 1px solid #8E44AD; border-top: none; border-radius: 0 0 8px 8px; padding: 6px; min-height: 480px; }
    .phase-body-green   { background: rgba(39, 174, 96, 0.04);  border: 1px solid #27AE60; border-top: none; border-radius: 0 0 8px 8px; padding: 6px; min-height: 480px; }

    .step-btn-container {
        margin-bottom: 8px;
    }
    
    .badge-count {
        background: #1e293b;
        color: white;
        font-weight: 700;
        font-size: 11px;
        padding: 2px 7px;
        border-radius: 12px;
        margin-right: 6px;
    }
    
    .workspace-card {
        background: #ffffff;
        border: 1px solid #e2e8f0;
        border-radius: 10px;
        padding: 20px;
        box-shadow: 0 4px 15px rgba(0,0,0,0.05);
        margin-top: 20px;
    }
    
    .step-title-active {
        font-size: 18px;
        font-weight: 700;
        color: #1e293b;
    }
</style>
""", unsafe_allow_html=True)


# ==============================================================================
# 2. DEFINITION OF THE 6 PHASES & 21 OPERATIONAL STEPS
# ==============================================================================
WORKFLOW_PHASES = [
    {
        "phase_id": 1,
        "title_en": "Pre-Planning & Studies",
        "title_ar": "التخطيط والدراسات المسبقة",
        "color_class": "col-header-amber",
        "body_class": "phase-body-amber",
        "theme_color": "#D35400",
        "steps": [
            {
                "code": "STEP_01",
                "title_en": "Freight Studies",
                "title_ar": "دراسات ومفاضلة نولون الشحن",
                "desc": "مقارنة عروض أسعار النولون البحري/الجوي واختيار أفضل خط ملاحي ومقدم خدمة.",
            },
            {
                "code": "STEP_02",
                "title_en": "Customs Studies",
                "title_ar": "الدراسات والاستشارات الجمركية",
                "desc": "تحديد بنود التعريفة HS Codes، الرسوم الجمركية، وضريبة القيمة المضافة ومطابقتها.",
            },
            {
                "code": "STEP_03",
                "title_en": "Regulatory Requirements",
                "title_ar": "متطلبات واشتراطات الاستيراد للشحنة",
                "desc": "فحص جهات العرض (سلامة الغذاء، الرقابة على الصادرات والواردات، المواصفات القياسية والموافقات المسبقة).",
            },
        ],
    },
    {
        "phase_id": 2,
        "title_en": "Shipment Initiation",
        "title_ar": "بداية الشحنة والتسجيل",
        "color_class": "col-header-cobalt",
        "body_class": "phase-body-cobalt",
        "theme_color": "#2980B9",
        "steps": [
            {
                "code": "STEP_04",
                "title_en": "Finance Approvals & Budget",
                "title_ar": "اعتمادات الميزانية وسداد الموردين",
                "desc": "اعتماد ميزانية الشحنة ودفعة مقدم المورد والتحويلات البنكية ومطابقة السيولة.",
            },
            {
                "code": "STEP_05",
                "title_en": "ACID Operations",
                "title_ar": "الرقم التعريفي المبدئي ACID",
                "desc": "إصدار ومتابعة الرقم المبدئي عبر منصة نافذة ومطابقة صلاحية الـ 180 يوماً.",
            },
        ],
    },
    {
        "phase_id": 3,
        "title_en": "Booking & Doc Prep",
        "title_ar": "حجز الشحن والتدقيق المستندي",
        "color_class": "col-header-emerald",
        "body_class": "phase-body-emerald",
        "theme_color": "#16A085",
        "steps": [
            {
                "code": "STEP_06",
                "title_en": "Freight Booking",
                "title_ar": "حجز النولون وتأكيد الخط الملاحي",
                "desc": "تأكيد الحجز الملاحي (Booking Confirmation) وتحديد مواعيد الإبحار والوصول المتوقعة.",
            },
            {
                "code": "STEP_07",
                "title_en": "Freight Allocations",
                "title_ar": "تخصيص وتوزيع الحاويات والبضائع",
                "desc": "توزيع البضائع وأحجام الحاويات (FCL / LCL) ومطابقة الأوزان والأحجام الإجمالية.",
            },
            {
                "code": "STEP_08",
                "title_en": "Draft Docs Review",
                "title_ar": "مراجعة وتدقيق مسودات الشحن",
                "desc": "تدقيق مسودات بوليصة الشحن (Draft B/L)، الفاتورة المبدئية، وقائمة التعبئة قبل الإصدار النهائي.",
            },
            {
                "code": "STEP_09",
                "title_en": "Docs Customs Approval",
                "title_ar": "الاعتماد الجمركي النهائي للمستندات",
                "desc": "مراجعة المخلص الجمركي والتأكد من مطابقة المستندات لقوانين وقواعد الجمارك المصرية.",
            },
        ],
    },
    {
        "phase_id": 4,
        "title_en": "Digital & Banking",
        "title_ar": "التوثيق الرقمي والاعتماد البنكي",
        "color_class": "col-header-red",
        "body_class": "phase-body-red",
        "theme_color": "#C0392B",
        "steps": [
            {
                "code": "STEP_10",
                "title_en": "CargoX Follow-up / Upload",
                "title_ar": "متابعة ورفع المستندات عبر CargoX",
                "desc": "متابعة قيام المورد الأجنبي برفع الفواتير والبوليصة وشهادة المنشأ مشفرة عبر منصة CargoX.",
            },
            {
                "code": "STEP_11",
                "title_en": "Original Docs Collection",
                "title_ar": "استلام وتدقيق أصول مستندات الشحن",
                "desc": "استلام أصول المستندات عبر البريد السريع الدولي (DHL/FedEx) والتحقق من الأختام والتصديقات.",
            },
            {
                "code": "STEP_12",
                "title_en": "Bank Form 4",
                "title_ar": "نموذج 4 والمطابقة والتوثيق البنكي",
                "desc": "تقديم مستندات الشحن للبنك واستخراج نموذج 4 وإشعار التحويل البنكي المصرفي المعتمد.",
            },
        ],
    },
    {
        "phase_id": 5,
        "title_en": "Port Operations & Clearance",
        "title_ar": "التخليص الجمركي وإدارة الميناء",
        "color_class": "col-header-purple",
        "body_class": "phase-body-purple",
        "theme_color": "#8E44AD",
        "steps": [
            {
                "code": "STEP_13",
                "title_en": "Customs Declaration 46",
                "title_ar": "قيد شهادة الإجراءات إقرار 46",
                "desc": "فتح وقيد الإقرار الجمركي الموحد (شهادة 46 ك.م) بساحة الجمرك بالميناء.",
            },
            {
                "code": "STEP_14",
                "title_en": "Clearance Follow-up",
                "title_ar": "متابعة الكشف والتثمين والتخليص",
                "desc": "متابعة أعمال الكشف والمعاينة، لجان الفحص المشترك، وتثمين البضائع وسحب إذن التسليم.",
            },
            {
                "code": "STEP_15",
                "title_en": "Drawing Samples / Shortage",
                "title_ar": "سحب العينات وإثبات الفاقد الجمركي",
                "desc": "سحب عينات الفحص المعملي لجهات العرض وإثبات أي فاقد أو عجز جمركي إن وجد.",
            },
            {
                "code": "STEP_16",
                "title_en": "Cargo Discrepancy / Damage",
                "title_ar": "محضر إثبات العجز والتلف بالمعاينة",
                "desc": "تحرير محاضر إثبات الحالة والعجز والتلف والتنسيق مع شركة التأمين والمعاينة.",
            },
            {
                "code": "STEP_17",
                "title_en": "Final Customs Calculation",
                "title_ar": "المطالبة وسداد الرسوم والضرائب",
                "desc": "استخراج كشف حساب المطالبة الجمركية وسداد الرسوم والضرائب واستلام إفراج الجمارك الأخضر.",
            },
            {
                "code": "STEP_18",
                "title_en": "Demurrage & Detention",
                "title_ar": "فترات السماح وغرامات الأرضيات",
                "desc": "مراقبة فترات السماح المجانية للخط الملاحي (Free Time) وتجنب غرامات الأرضيات والتأخير.",
            },
        ],
    },
    {
        "phase_id": 6,
        "title_en": "Inbound & Final Closure",
        "title_ar": "الاستلام والتسوية والإغلاق",
        "color_class": "col-header-green",
        "body_class": "phase-body-green",
        "theme_color": "#27AE60",
        "steps": [
            {
                "code": "STEP_19",
                "title_en": "Warehouse Receiving (GRN)",
                "title_ar": "إشعار المخازن وإذن الإضافة GRN",
                "desc": "نقل البضائع للمستودع وإجراء الفحص المخزني وإصدار إذن الإضافة المخزني (GRN).",
            },
            {
                "code": "STEP_20",
                "title_en": "Landed Cost Settlement",
                "title_ar": "تسوية التكلفة الاستيرادية الشاملة",
                "desc": "حساب التكلفة الإجمالية للوصول وتوزيع مصاريف النولون والجمارك والتخليص على الأصناف.",
            },
            {
                "code": "STEP_21",
                "title_en": "Import File Final Closure",
                "title_ar": "المراجعة الختامية وإغلاق الملف",
                "desc": "المطابقة المحاسبية الشاملة، ترحيل القيود لـ ERP وإغلاق الملف الاستيرادي نهائياً.",
            },
        ],
    },
]

# Map step codes to step details
ALL_STEPS_MAP = {}
for phase in WORKFLOW_PHASES:
    for s in phase["steps"]:
        ALL_STEPS_MAP[s["code"]] = s


# ==============================================================================
# 3. DATABASE INITIALIZATION & PIPELINE STAGE TRACKING
# ==============================================================================
def get_db_connection():
    conn = sqlite3.connect(DB_PATH, check_same_thread=False)
    conn.row_factory = sqlite3.Row
    return conn


def init_pipeline_db():
    conn = get_db_connection()
    c = conn.cursor()
    
    # Create shipment_stage_activity table to support multiple active stages per shipment
    c.execute("""
    CREATE TABLE IF NOT EXISTS shipment_stage_activity (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        import_file_code TEXT NOT NULL,
        step_code TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'In-Progress', -- In-Progress, Completed, On-Hold
        started_at TEXT,
        completed_at TEXT,
        assigned_user TEXT,
        action_data TEXT, -- JSON payload for step specific data
        notes TEXT,
        UNIQUE(import_file_code, step_code)
    )
    """)
    conn.commit()

    # Seed sample active stages if table is empty
    count = c.execute("SELECT COUNT(*) FROM shipment_stage_activity").fetchone()[0]
    if count == 0:
        # Check if we have files in import_files
        files = c.execute("SELECT import_file_code FROM import_files").fetchall()
        file_codes = [f["import_file_code"] for f in files]
        
        # If no files in DB, create initial demo shipment files
        if not file_codes:
            demo_files = [
                ("IMP-2026-0001", "ECO ASSOCIATES for Trading", "G.I. Industrial Holding S.p.A.", "PO-1001", "Sea FCL", "FOB", 145000.0, "EUR", "Open"),
                ("IMP-2026-0002", "Alexandria Pharma Import", "Bayer AG Germany", "PO-1002", "Air", "CIF", 89000.0, "EUR", "Open"),
                ("IMP-2026-0003", "Cairo Steel & Metal Works", "Baosteel Group China", "PO-1003", "Sea FCL", "CFR", 320000.0, "USD", "Open"),
                ("IMP-2026-0004", "Delta Food Industries", "Cargill International", "PO-1004", "Sea LCL", "FOB", 64000.0, "USD", "Open"),
                ("IMP-2026-0005", "Nile Medical Supplies", "Siemens Healthineers", "PO-1005", "Air", "CIP", 210000.0, "EUR", "Open"),
            ]
            for f in demo_files:
                c.execute("""
                INSERT OR IGNORE INTO import_files (import_file_code, company_name, supplier_name, po_number, shipment_mode, incoterm_code, estimated_cost, estimated_cost_currency, status, is_active)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 1)
                """, f)
            conn.commit()
            file_codes = ["IMP-2026-0001", "IMP-2026-0002", "IMP-2026-0003", "IMP-2026-0004", "IMP-2026-0005"]
        
        # Multi-stage demo assignments (e.g. IMP-2026-0001 is active in 3 stages simultaneously!)
        sample_activities = [
            ("IMP-2026-0001", "STEP_01", "In-Progress", "مفاضلة 3 عروض نولون بحري مع MSC وMaersk"),
            ("IMP-2026-0001", "STEP_02", "In-Progress", "فحص بند التعريفة 841869 ومطابقة ضريبة الجدول"),
            ("IMP-2026-0001", "STEP_03", "In-Progress", "مراجعة موافقة هيئة الرقابة على الصادرات والواردات GOEIC"),
            ("IMP-2026-0002", "STEP_04", "In-Progress", "سداد دفعة المورد 30% والاعتماد المالي"),
            ("IMP-2026-0002", "STEP_05", "In-Progress", "طلب إصدار رقم ACID المبدئي عبر نافذة"),
            ("IMP-2026-0003", "STEP_06", "In-Progress", "تأكيد حجز 4 حاويات 40 قدم مع الخط الملاحي"),
            ("IMP-2026-0003", "STEP_08", "In-Progress", "مراجعة مسودة البوليصة والتأكد من تطابق بيانات الشاحن"),
            ("IMP-2026-0004", "STEP_10", "In-Progress", "متابعة قيام المورد برفع الفاتورة والبوليصة على CargoX"),
            ("IMP-2026-0004", "STEP_12", "In-Progress", "استخراج نموذج 4 من البنك الأهلي المصري"),
            ("IMP-2026-0005", "STEP_13", "In-Progress", "قيد الإقرار الجمركي رقم 46 بمطار القاهرة"),
            ("IMP-2026-0005", "STEP_14", "In-Progress", "متابعة لجنة المعاينة والكشف الفني"),
            ("IMP-2026-0005", "STEP_17", "In-Progress", "سداد الرسوم والضرائب الجمركية بموجب أمر الدفع"),
        ]
        
        for code, step, st_val, note in sample_activities:
            c.execute("""
            INSERT OR IGNORE INTO shipment_stage_activity (import_file_code, step_code, status, started_at, notes)
            VALUES (?, ?, ?, ?, ?)
            """, (code, step, st_val, datetime.now().strftime("%Y-%m-%d %H:%M"), note))
        conn.commit()
        
    conn.close()


init_pipeline_db()


# ==============================================================================
# 4. LIVE DATA RETRIEVAL & STEP COUNTS
# ==============================================================================
def get_live_step_counts():
    conn = get_db_connection()
    c = conn.cursor()
    rows = c.execute("""
    SELECT step_code, COUNT(*) as count 
    FROM shipment_stage_activity 
    WHERE status = 'In-Progress' 
    GROUP BY step_code
    """).fetchall()
    conn.close()
    
    counts = {r["step_code"]: r["count"] for r in rows}
    return counts


def get_active_files_in_step(step_code):
    conn = get_db_connection()
    c = conn.cursor()
    query = """
    SELECT 
        a.id as activity_id,
        a.import_file_code,
        a.step_code,
        a.status as stage_status,
        a.started_at,
        a.notes as activity_notes,
        a.action_data,
        f.company_name,
        f.supplier_name,
        f.po_number,
        f.shipment_mode,
        f.incoterm_code,
        f.estimated_cost,
        f.estimated_cost_currency,
        f.acid_number,
        f.acid_expiry_date,
        f.form4_no,
        f.form46_no
    FROM shipment_stage_activity a
    LEFT JOIN import_files f ON a.import_file_code = f.import_file_code
    WHERE a.step_code = ? AND a.status = 'In-Progress'
    ORDER BY a.started_at DESC
    """
    rows = c.execute(query, (step_code,)).fetchall()
    conn.close()
    return [dict(r) for r in rows]


def get_all_active_stages_for_file(import_file_code):
    conn = get_db_connection()
    c = conn.cursor()
    rows = c.execute("""
    SELECT step_code, status, started_at, notes 
    FROM shipment_stage_activity 
    WHERE import_file_code = ? AND status = 'In-Progress'
    """, (import_file_code,)).fetchall()
    conn.close()
    return [r["step_code"] for r in rows]


def update_file_stage_activity(import_file_code, current_step_code, mark_completed=False, next_step_code=None, additional_active_steps=None, notes=""):
    conn = get_db_connection()
    c = conn.cursor()
    now_str = datetime.now().strftime("%Y-%m-%d %H:%M")
    
    if mark_completed:
        # Mark current step completed
        c.execute("""
        UPDATE shipment_stage_activity 
        SET status = 'Completed', completed_at = ?, notes = ?
        WHERE import_file_code = ? AND step_code = ?
        """, (now_str, notes, import_file_code, current_step_code))
    else:
        # Update notes/status
        c.execute("""
        UPDATE shipment_stage_activity 
        SET notes = ?
        WHERE import_file_code = ? AND step_code = ?
        """, (notes, import_file_code, current_step_code))
        
    # If next step code is requested to be activated
    if next_step_code and next_step_code != "NONE":
        c.execute("""
        INSERT OR REPLACE INTO shipment_stage_activity (import_file_code, step_code, status, started_at, notes)
        VALUES (?, ?, 'In-Progress', ?, 'تم النقل آلياً من الخطوة السابقة')
        """, (import_file_code, next_step_code, now_str))

    # Sync multi-stage checkboxes if provided
    if additional_active_steps is not None:
        for st_code in additional_active_steps:
            c.execute("""
            INSERT OR IGNORE INTO shipment_stage_activity (import_file_code, step_code, status, started_at, notes)
            VALUES (?, ?, 'In-Progress', ?, 'مرحلة نشطة متزامنة')
            """, (import_file_code, st_code, now_str))
            
    conn.commit()
    conn.close()


def get_all_import_files():
    conn = get_db_connection()
    c = conn.cursor()
    rows = c.execute("SELECT * FROM import_files ORDER BY import_file_id DESC").fetchall()
    conn.close()
    return [dict(r) for r in rows]


# ==============================================================================
# 5. SESSION STATE MANAGEMENT
# ==============================================================================
if "selected_step" not in st.session_state:
    st.session_state.selected_step = "STEP_01"

if "selected_file_code" not in st.session_state:
    st.session_state.selected_file_code = None

step_counts = get_live_step_counts()


# ==============================================================================
# 6. HEADER & TOP STATS
# ==============================================================================
st.markdown("""
<div class="main-title-container">
    <div>
        <div class="main-title-text">🚢 ImportFlow ERP — Operations & Lifecycle Board</div>
        <div class="main-sub-text">لوحة التحكم ومتابعة حركة الشحنات الاستيرادية (المستويات الـ 6 الكبرى — 21 خطوة تشغيلية)</div>
    </div>
    <div style="text-align: right;">
        <span style="background: rgba(255,255,255,0.1); padding: 6px 14px; border-radius: 6px; font-size: 13px; font-weight: 600;">
            🟢 النظام متصل بقاعدة البيانات الحية (importflow.db)
        </span>
    </div>
</div>
""", unsafe_allow_html=True)


# ==============================================================================
# 7. THE 6-COLUMN SHIPMENT LIFECYCLE BOARD (EXACT VISUAL REPLICA)
# ==============================================================================
cols = st.columns(6)

for i, phase in enumerate(WORKFLOW_PHASES):
    with cols[i]:
        # Header banner with phase name
        st.markdown(f"""
        <div class="{phase['color_class']}">
            <div style="font-size: 13px; letter-spacing: 0.2px;">{phase['title_en']}</div>
            <div style="font-size: 11px; opacity: 0.9; font-weight: 600;">{phase['title_ar']}</div>
        </div>
        """, unsafe_allow_html=True)
        
        # Column Body Container
        st.markdown(f'<div class="{phase["body_class"]}">', unsafe_allow_html=True)
        
        for step in phase["steps"]:
            count = step_counts.get(step["code"], 0)
            is_active = (st.session_state.selected_step == step["code"])
            
            # Interactive button for each step
            btn_label = f"[{count}] {step['title_en']}"
            btn_type = "primary" if is_active else "secondary"
            
            if st.button(btn_label, key=f"btn_{step['code']}", use_container_width=True, type=btn_type):
                st.session_state.selected_step = step["code"]
                st.session_state.selected_file_code = None
                st.rerun()
                
            # Arabic subtitle underneath button
            st.markdown(f"""
            <div style="font-size: 10.5px; color: #475569; margin-top: -6px; margin-bottom: 8px; text-align: center;">
                {step['title_ar']}
            </div>
            """, unsafe_allow_html=True)
            
        st.markdown('</div>', unsafe_allow_html=True)

st.markdown("<div style='height: 15px;'></div>", unsafe_allow_html=True)


# ==============================================================================
# 8. INTERACTIVE WORKSPACE PANEL (شاشة العمليات والملفات التفاعلية)
# ==============================================================================
selected_step_info = ALL_STEPS_MAP.get(st.session_state.selected_step, ALL_STEPS_MAP["STEP_01"])
active_files = get_active_files_in_step(st.session_state.selected_step)

st.markdown(f"""
<div class="workspace-card">
    <div style="display: flex; justify-content: space-between; align-items: center; border-bottom: 2px solid #f1f5f9; padding-bottom: 12px; margin-bottom: 16px;">
        <div>
            <span style="background: #1e293b; color: white; padding: 4px 10px; border-radius: 6px; font-weight: 700; font-size: 12px;">
                {selected_step_info['code']}
            </span>
            <span style="font-size: 20px; font-weight: 800; color: #1e293b; margin-left: 8px;">
                {selected_step_info['title_en']} — {selected_step_info['title_ar']}
            </span>
            <div style="font-size: 13px; color: #64748b; margin-top: 4px;">
                💡 {selected_step_info['desc']}
            </div>
        </div>
        <div>
            <span style="background: #f8fafc; border: 1px solid #cbd5e1; padding: 6px 14px; border-radius: 8px; font-weight: 700; color: #0f172a; font-size: 14px;">
                📁 الشحنات الحالية في هذه الخطوة: {len(active_files)}
            </span>
        </div>
    </div>
</div>
""", unsafe_allow_html=True)

# Main 2-column workspace: Left = Active Files List, Right = File Workstation & Actions
ws_col1, ws_col2 = st.columns([1, 1.4])

with ws_col1:
    st.subheader(f"📋 قائمة الشحنات النشطة ({len(active_files)})")
    
    if not active_files:
        st.info("لا توجد شحنات نشطة حالياً في هذه الخطوة. يمكنك نقل أي شحنة إليها أو إنشاء شحنة جديدة من القائمة الجانبية.")
    else:
        for file in active_files:
            is_file_selected = (st.session_state.selected_file_code == file["import_file_code"])
            border_style = "2px solid #2563eb" if is_file_selected else "1px solid #e2e8f0"
            bg_style = "#eff6ff" if is_file_selected else "#ffffff"
            
            with st.container():
                st.markdown(f"""
                <div style="background: {bg_style}; border: {border_style}; border-radius: 8px; padding: 12px; margin-bottom: 10px;">
                    <div style="display: flex; justify-content: space-between; align-items: center;">
                        <span style="font-weight: 800; color: #1e3a8a; font-size: 15px;">📦 {file['import_file_code']}</span>
                        <span style="background: #dbeafe; color: #1e40af; font-size: 11px; font-weight: 700; padding: 2px 8px; border-radius: 10px;">
                            {file.get('shipment_mode', 'Sea FCL')} | {file.get('incoterm_code', 'FOB')}
                        </span>
                    </div>
                    <div style="font-size: 13px; font-weight: 600; color: #334155; margin-top: 4px;">
                        🏢 {file.get('company_name', 'N/A')}
                    </div>
                    <div style="font-size: 12px; color: #64748b;">
                        🌍 المورد: {file.get('supplier_name', 'N/A')} | أمر الشراء: {file.get('po_number', 'N/A')}
                    </div>
                    <div style="font-size: 12px; color: #059669; font-weight: 700; margin-top: 2px;">
                        💰 القيمة: {(file.get('estimated_cost') or 0.0):,.2f} {file.get('estimated_cost_currency') or 'USD'}
                    </div>
                    <div style="font-size: 11.5px; color: #475569; margin-top: 4px; background: #f8fafc; padding: 4px 6px; border-radius: 4px;">
                        📝 الملاحظة: {file.get('activity_notes') or 'قيد المتابعة التشغيلية'}
                    </div>
                </div>
                """, unsafe_allow_html=True)
                
                if st.button(f"🔍 فتح ملف العمل ({file['import_file_code']})", key=f"select_{file['import_file_code']}", use_container_width=True):
                    st.session_state.selected_file_code = file["import_file_code"]
                    st.rerun()

with ws_col2:
    st.subheader("⚙️ بطاقة العمل التشغيلي والإجراءات")
    
    selected_code = st.session_state.selected_file_code
    if not selected_code and active_files:
        selected_code = active_files[0]["import_file_code"]
        st.session_state.selected_file_code = selected_code

    if selected_code:
        # Fetch full details
        file_matches = [f for f in active_files if f["import_file_code"] == selected_code]
        file_data = file_matches[0] if file_matches else None
        
        if file_data:
            # Active Multi-Stages overview for this file
            current_active_stages = get_all_active_stages_for_file(selected_code)
            stage_tags = " ".join([f"<span style='background:#fef3c7; color:#92400e; font-weight:700; padding:2px 8px; border-radius:4px; font-size:11px; margin-right:4px;'>{ALL_STEPS_MAP.get(st_c, {}).get('title_en', st_c)}</span>" for st_c in current_active_stages])
            
            st.markdown(f"""
            <div style="background: #f8fafc; border: 1px solid #cbd5e1; border-radius: 8px; padding: 14px; margin-bottom: 16px;">
                <div style="font-size: 16px; font-weight: 800; color: #0f172a;">
                    الملف المحدد: {selected_code} ({file_data.get('company_name', '')})
                </div>
                <div style="margin-top: 6px; font-size: 12px; color: #475569;">
                    📍 المراحل النشطة حالياً لهذا الملف: {stage_tags}
                </div>
            </div>
            """, unsafe_allow_html=True)
            
            # Step specific operational form
            with st.form(key=f"form_action_{selected_code}_{selected_step_info['code']}"):
                st.markdown(f"##### 🛠️ تنفيذ مهام: {selected_step_info['title_en']} ({selected_step_info['title_ar']})")
                
                # Dynamic fields based on current step
                if selected_step_info["code"] == "STEP_01":  # Freight Studies
                    col_a, col_b = st.columns(2)
                    with col_a:
                        st.selectbox("الخط الملاحي الأنسب / وكيل الشحن", ["MSC Mediterranean Shipping", "Maersk Line", "CMA CGM", "Hapag-Lloyd", "Cosco Shipping"], index=0)
                        st.number_input("نولون الشحن المعتمد ($)", value=2400.0, step=100.0)
                    with col_b:
                        st.selectbox("مدة الإبحار المتوقعة (Transit Time)", ["14 يوم", "21 يوم", "28 يوم", "35 يوم"])
                        st.text_input("رقم عرض السعر (Quotation Ref)", value="QT-2026-889")
                        
                elif selected_step_info["code"] == "STEP_02":  # Customs Studies
                    col_a, col_b = st.columns(2)
                    with col_a:
                        st.text_input("بند التعريفة المعتمد (HS Code)", value="8418.69.00.00")
                        st.number_input("ضريبة الوارد المطبقة %", value=10.0, step=1.0)
                    with col_b:
                        st.number_input("ضريبة القيمة المضافة %", value=14.0, step=1.0)
                        st.selectbox("الاتفاقية التفضيلية للإعفاء", ["بدون إعفاء (عام)", "الاتحاد الأوروبي (EUR.1)", "اتفاقية أغادير", "الكوميسا COMESA"])
                        
                elif selected_step_info["code"] == "STEP_03":  # Regulatory Requirements
                    col_a, col_b = st.columns(2)
                    with col_a:
                        st.multiselect("جهات العرض والرقابة المطلوبة", ["هيئة الرقابة على الصادرات والواردات (GOEIC)", "سلامة الغذاء (NFSA)", "الحجر الزراعي", "الحجر البيطري", "هيئة الدواء المصرية (EDA)"], default=["هيئة الرقابة على الصادرات والواردات (GOEIC)"])
                    with col_b:
                        st.text_input("رقم الموافقة المسبقة / التسجيل", value="REG-GOEIC-2026-991")
                        
                elif selected_step_info["code"] == "STEP_04":  # Finance Approvals
                    col_a, col_b = st.columns(2)
                    with col_a:
                        st.number_input("مبلغ الدفعة المعتمدة للمورد", value=float(file_data.get("estimated_cost") or 50000.0), step=1000.0)
                        st.selectbox("طريقة السداد", ["تحويل بنكي مقدم (Advance TT)", "اعتماد مستندي (L/C)", "مستندات برسم التحصيل (CAD)"])
                    with col_b:
                        st.selectbox("البنك المعتمد للتحويل", ["البنك الأهلي المصري", "بنك مصر", "البنك التجاري الدولي CIB", "بنك QNB الأهلي"])
                        st.text_input("رقم مرجع السويفت SWIFT Ref", value="SWIFT-NBE-887123")
                        
                elif selected_step_info["code"] == "STEP_05":  # ACID
                    col_a, col_b = st.columns(2)
                    with col_a:
                        st.text_input("الرقم التعريفي المبدئي للشحنة (ACID)", value=file_data.get("acid_number") or "2026081700981234567")
                        st.date_input("تاريخ إصدار ACID", value=date.today())
                    with col_b:
                        st.date_input("تاريخ انتهاء الصلاحية (180 يوم)", value=date(2026, 12, 31))
                        st.text_input("رقم تسجيل المصنع الأجنبي", value="MFG-IT-88412")

                elif selected_step_info["code"] == "STEP_12":  # Bank Form 4
                    col_a, col_b = st.columns(2)
                    with col_a:
                        st.text_input("رقم نموذج 4 المعتمد", value=file_data.get("form4_no") or "F4-2026-88192")
                        st.date_input("تاريخ إصدار النموذج", value=date.today())
                    with col_b:
                        st.selectbox("البنك المصدر", ["البنك الأهلي المصري", "بنك مصر", "CIB", "QNB"])
                        st.number_input("القيمة المعتمدة بالنموذج ($)", value=float(file_data.get("estimated_cost") or 25000.0))

                elif selected_step_info["code"] == "STEP_13":  # Customs Declaration 46
                    col_a, col_b = st.columns(2)
                    with col_a:
                        st.text_input("رقم شهادة الإجراءات (إقرار 46)", value=file_data.get("form46_no") or "46-ALX-2026-7781")
                        st.date_input("تاريخ قيد الشهادة", value=date.today())
                    with col_b:
                        st.selectbox("جمرك الإفراج", ["ميناء الإسكندرية البحري", "ميناء الدخيلة", "ميناء العين السخنة", "ميناء بورسعيد", "قرية البضائع بمطار القاهرة"])
                        st.text_input("اسم المخلص الجمركي المعتمد", value="الأهرام للتخليص والخدمات اللوجستية")

                else:
                    st.text_input("المرجع التشغيلي للخطوة (Reference No)", value="REF-2026-AUTO")
                    
                # Action Notes
                notes_val = st.text_area("ملاحظات وتحديثات هذه الخطوة", value=file_data.get("activity_notes") or "", height=70)
                
                st.markdown("---")
                
                # Support for multi-stage simultaneous active steps
                st.markdown("##### 🔀 تعدد المراحل النشطة (Multi-Stage Work):")
                st.caption("يمكنك تفعيل وجود نفس ملف الشحنة في أكثر من مرحلة بالتوازي (مثلاً: دراسة نولون + دراسة جمركية + اشتراطات استيراد في نفس الوقت):")
                
                multi_step_options = [s["code"] for s in ALL_STEPS_MAP.values() if s["code"] != selected_step_info["code"]]
                multi_step_labels = {s["code"]: f"{s['code']} — {s['title_en']} ({s['title_ar']})" for s in ALL_STEPS_MAP.values()}
                
                selected_extra_stages = st.multiselect(
                    "المراحل الأخرى المتزامنة النشطة لهذا الملف:",
                    options=multi_step_options,
                    default=[s for s in current_active_stages if s != selected_step_info["code"]],
                    format_func=lambda x: multi_step_labels.get(x, x),
                )
                
                st.markdown("---")
                
                # Next Step Action Selection
                col_act1, col_act2 = st.columns(2)
                with col_act1:
                    all_step_codes = [s["code"] for s in ALL_STEPS_MAP.values()]
                    current_idx = all_step_codes.index(selected_step_info["code"])
                    default_next = all_step_codes[current_idx + 1] if current_idx + 1 < len(all_step_codes) else "NONE"
                    
                    next_step_choice = st.selectbox(
                        "نقل الشحنة تلقائياً إلى المرحلة التالية:",
                        options=["NONE"] + all_step_codes,
                        index=(all_step_codes.index(default_next) + 1) if default_next != "NONE" else 0,
                        format_func=lambda x: "لا تنقل لمرحلة جديدة (إبقاء الملف)" if x == "NONE" else multi_step_labels.get(x, x)
                    )
                    
                with col_act2:
                    action_type = st.radio(
                        "نوع الحفظ والإجراء:",
                        ["حفظ التحديثات فقط (إبقاء الخطوة الحالية نشطة)", "اكتمال الخطوة الحالية ونقل الشحنة (Mark Completed)"],
                        index=0
                    )

                save_btn = st.form_submit_button("💾 تنفيذ وحفظ إجراءات الشحنة", type="primary", use_container_width=True)
                
                if save_btn:
                    is_completed = ("اكتمال" in action_type)
                    target_next = next_step_choice if is_completed else None
                    
                    update_file_stage_activity(
                        import_file_code=selected_code,
                        current_step_code=selected_step_info["code"],
                        mark_completed=is_completed,
                        next_step_code=target_next,
                        additional_active_steps=selected_extra_stages,
                        notes=notes_val
                    )
                    st.success(f"✅ تم حفظ وتحديث بيانات الشحنة {selected_code} بنجاح!")
                    st.rerun()

        else:
            st.info("اختر شحنة من القائمة على اليمين للبدء في تنفيذ مهام هذه الخطوة.")


# ==============================================================================
# 9. SIDEBAR: QUICK NEW SHIPMENT CREATION & MASTER DATA OVERVIEW
# ==============================================================================
with st.sidebar:
    st.header("⚡ إنشاء شحنة استيرادية جديدة")
    
    with st.form("new_shipment_quick_form"):
        new_code = st.text_input("كود ملف الشحنة", value=f"IMP-2026-{datetime.now().strftime('%M%S')}")
        new_importer = st.selectbox("الشركة المستوردة", ["ECO ASSOCIATES for Trading and Contracting", "Alexandria Pharma Import", "Cairo Steel & Metal Works", "Delta Food Industries", "Nile Medical Supplies"])
        new_supplier = st.selectbox("المورد الأجنبي", ["G.I. Industrial Holding S.p.A.", "Bayer AG Germany", "Baosteel Group China", "Cargill International", "Siemens Healthineers"])
        new_po = st.text_input("رقم أمر الشراء (PO)", value=f"PO-{datetime.now().strftime('%M%S')}")
        new_val = st.number_input("القيمة التقديرية للفاتورة", value=50000.0, step=5000.0)
        new_curr = st.selectbox("العملة", ["USD", "EUR", "GBP", "CNY"])
        new_mode = st.selectbox("وسيلة الشحن", ["Sea FCL", "Sea LCL", "Air", "Land"])
        new_incoterm = st.selectbox("شرط الشحن (Incoterm)", ["FOB", "CIF", "CFR", "EXW", "DAP"])
        
        st.markdown("---")
        st.markdown("**المراحل المبدئية النشطة لهذه الشحنة:**")
        initial_stages = st.multiselect(
            "اختر مرحلة أو أكثر للبدء فيها بالتوازي:",
            options=[s["code"] for s in ALL_STEPS_MAP.values()],
            default=["STEP_01", "STEP_02", "STEP_03"],
            format_func=lambda x: f"{x} — {ALL_STEPS_MAP[x]['title_en']} ({ALL_STEPS_MAP[x]['title_ar']})"
        )
        
        create_btn = st.form_submit_button("➕ إنشاء الملف وتفعيل المراحل", type="primary", use_container_width=True)
        
        if create_btn:
            conn = get_db_connection()
            c = conn.cursor()
            now_str = datetime.now().strftime("%Y-%m-%d %H:%M")
            
            # Insert into import_files
            c.execute("""
            INSERT OR REPLACE INTO import_files (
                import_file_code, company_name, supplier_name, po_number, 
                shipment_mode, incoterm_code, estimated_cost, estimated_cost_currency, 
                status, is_active, created_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'Open', 1, ?)
            """, (new_code, new_importer, new_supplier, new_po, new_mode, new_incoterm, new_val, new_curr, now_str))
            
            # Activate initial stages
            for st_c in initial_stages:
                c.execute("""
                INSERT OR REPLACE INTO shipment_stage_activity (import_file_code, step_code, status, started_at, notes)
                VALUES (?, ?, 'In-Progress', ?, 'تم فتح الملف وتفعيل المرحلة')
                """, (new_code, st_c, now_str))
                
            conn.commit()
            conn.close()
            
            st.success(f"🎉 تم إنشاء الشحنة {new_code} وتفعيل المراحل بنجاح!")
            st.rerun()

    st.markdown("---")
    st.markdown("### 📊 إحصائيات النظام الشاملة")
    all_files = get_all_import_files()
    st.write(f"• إجمالي ملفات الشحنات المسجلة: **{len(all_files)}**")
    st.write(f"• الشحنات المفتوحة والنشطة: **{len([f for f in all_files if f.get('status') == 'Open'])}**")
    st.write(f"• إجمالي المراحل النشطة بالتوازي: **{sum(step_counts.values())}**")
