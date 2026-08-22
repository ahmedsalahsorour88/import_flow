"""
Wipe Projects, Fix Currencies, and Populate All World Transport Locations.
"""
import sqlite3
from pathlib import Path
from datetime import datetime

ROOT_DIR = Path(__file__).resolve().parent

DATABASES = [
    ROOT_DIR / "sorour_logistics.db",
    ROOT_DIR / "dist" / "ImportFlow_Standalone" / "sorour_logistics.db",
    ROOT_DIR / "dist" / "sorour_logistics.db",
    ROOT_DIR / "dist_backend" / "sorour_logistics.db",
]

CURRENCY_SYMBOLS = {
    "USD": "$", "EUR": "€", "GBP": "£", "EGP": "E£", "JPY": "¥", "CNY": "¥",
    "SAR": "SAR", "AED": "AED", "KWD": "KD", "QAR": "QR", "BHD": "BD",
    "OMR": "OMR", "JOD": "JD", "CHF": "CHF", "CAD": "CA$", "AUD": "A$",
    "NZD": "NZ$", "INR": "₹", "RUB": "₽", "TRY": "₺", "BRL": "R$",
    "ZAR": "R", "KRW": "₩", "SEK": "kr", "NOK": "kr", "DKK": "kr",
    "PLN": "zł", "THB": "฿", "IDR": "Rp", "MYR": "RM", "SGD": "S$",
    "HKD": "HK$", "TWD": "NT$", "MXN": "Mex$", "ARS": "ARS", "CLP": "CLP",
    "COP": "COP", "PEN": "S/.", "VND": "₫", "PHP": "₱", "PKR": "₨",
    "BDT": "৳", "NGN": "₦", "KES": "KSh", "GHS": "GH₵", "MAD": "MAD",
    "DZD": "DZD", "TND": "DT", "IQD": "IQD", "LYD": "LD", "LBP": "LL",
    "SYP": "LS", "YER": "YR", "SDG": "SDG", "AFN": "؋", "ALL": "L",
    "AMD": "֏", "AOA": "Kz", "AZN": "₼", "BAM": "KM", "BBD": "Bds$",
    "BIF": "FBu", "BMD": "BD$", "BND": "B$", "BOB": "Bs.", "BSD": "B$",
    "BTN": "Nu.", "BWP": "P", "BYN": "Br", "BZD": "BZ$", "CDF": "FC",
    "CRC": "₡", "CUP": "₱", "CVE": "Esc", "CZK": "Kč", "DJF": "Fdj",
    "DOP": "RD$", "ERN": "Nfk", "ETB": "Br", "FJD": "FJ$", "FKP": "FK£",
    "GEL": "₾", "GIP": "GIP", "GMD": "D", "GNF": "FG", "GTQ": "Q",
    "GYD": "G$", "HNL": "L", "HRK": "kn", "HTG": "G", "HUF": "Ft",
    "ILS": "₪", "ISK": "kr", "JMD": "J$", "KGS": "с", "KHR": "៛",
    "KMF": "CF", "KPW": "₩", "KZT": "₸", "LAK": "₭", "LKR": "Rs",
    "LRD": "L$", "LSL": "M", "MDL": "L", "MGA": "Ar", "MKD": "ден",
    "MMK": "K", "MNT": "₮", "MOP": "MOP$", "MRU": "UM", "MUR": "Rs",
    "MVR": "Rf", "MWK": "MK", "MZN": "MT", "NAD": "N$", "NIO": "C$",
    "NPR": "Rs", "PAB": "B/.", "PGK": "K", "PYG": "₲", "RON": "lei",
    "RSD": "дин.", "RWF": "RF", "SBD": "SI$", "SCR": "SR", "SHP": "SH£",
    "SLL": "Le", "SOS": "Sh", "SRD": "Sr$", "SSP": "SS£", "STN": "Db",
    "SVC": "₡", "SZL": "L", "TJS": "SM", "TMT": "T", "TOP": "T$",
    "TTD": "TT$", "TZS": "TSh", "UAH": "₴", "UGX": "USh", "UYU": "$U",
    "UZS": "so'm", "VES": "Bs.S", "VUV": "VT", "WST": "WS$", "XAF": "FCFA",
    "XCD": "EC$", "XOF": "CFA", "XPF": "CFPF", "ZMW": "ZK", "ZWL": "Z$",
}

# Major Global Hubs and Ports dataset
MAJOR_PORTS_AIRPORTS_BORDERS = [
    # --- EGYPT (Complete Comprehensive Ports, Airports, Dry Ports, Land Borders) ---
    ("EGALY", "Alexandria Port (ميناء الإسكندرية البحري)", "Sea Port", "Egypt", "Alexandria"),
    ("EGEDK", "El Dekheila Port (ميناء الدخيلة البحري)", "Sea Port", "Egypt", "Alexandria"),
    ("EGPSD", "Port Said West (ميناء غرب بورسعيد)", "Sea Port", "Egypt", "Port Said"),
    ("EGPSG", "Port Said East / SCCT (ميناء شرق بورسعيد)", "Sea Port", "Egypt", "Port Said"),
    ("EGDAM", "Damietta Port (ميناء دمياط البحري)", "Sea Port", "Egypt", "Damietta"),
    ("EGSOK", "Ain Sokhna Port / DP World (ميناء العين السخنة)", "Sea Port", "Egypt", "Suez"),
    ("EGSUZ", "Suez Port / Port Tawfiq (ميناء السويس - بور توفيق)", "Sea Port", "Egypt", "Suez"),
    ("EGADA", "Adabiya Port (ميناء الأدبية)", "Sea Port", "Egypt", "Suez"),
    ("EGSFA", "Safaga Port (ميناء سفاجا البحري)", "Sea Port", "Egypt", "Red Sea"),
    ("EGNWB", "Nuweiba Port (ميناء نويبع البحري)", "Sea Port", "Egypt", "South Sinai"),
    ("EGSSH", "Sharm El Sheikh Port (ميناء شرم الشيخ البحري)", "Sea Port", "Egypt", "South Sinai"),
    ("EGHRG", "Hurghada Port (ميناء الغردقة البحري)", "Sea Port", "Egypt", "Red Sea"),
    ("EGABS", "Abu Zenima Port (ميناء أبو زنيمة البترولي/التجاري)", "Sea Port", "Egypt", "South Sinai"),
    ("EGAQU", "Abu Qir Port (ميناء أبو قير البحري الجديد)", "Sea Port", "Egypt", "Alexandria"),
    ("EGGAR", "El Garada / Arish Port (ميناء العريش البحري)", "Sea Port", "Egypt", "North Sinai"),
    ("EGMTR", "Mersa Matruh Port (ميناء مرسى مطروح)", "Sea Port", "Egypt", "Matrouh"),
    ("EGBER", "Berenice Port (ميناء برنيس البحري التجاري)", "Sea Port", "Egypt", "Red Sea"),
    ("EGSKR", "Sidi Kerir Offshore Terminal (ميناء سيدي كرير البترولي)", "Sea Port", "Egypt", "Alexandria"),
    ("EGRGH", "Ras Ghareb Terminal (ميناء رأس غارب)", "Sea Port", "Egypt", "Red Sea"),
    ("EGRSH", "Ras Shukheir Terminal (ميناء رأس شقير)", "Sea Port", "Egypt", "Red Sea"),
    ("EGHMD", "El Hamra Oil Port (ميناء الحمراء البترولي بالعلمين)", "Sea Port", "Egypt", "Matrouh"),
    
    # Egypt Cargo Airports
    ("EGCAI", "Cairo Cargo Terminal / CAI Airport (قرية البضائع - مطار القاهرة الدولي)", "Airport", "Egypt", "Cairo"),
    ("EGHBE", "Borg El Arab Cargo Airport (مطار برج العرب الدولي)", "Airport", "Egypt", "Alexandria"),
    ("EGSPX", "Sphinx International Cargo Airport (مطار سفنكس الدولي)", "Airport", "Egypt", "Giza"),
    ("EGLXR", "Luxor Cargo Airport (مطار الأقصر الدولي)", "Airport", "Egypt", "Luxor"),
    ("EGASW", "Aswan Cargo Airport (مطار أسوان الدولي)", "Airport", "Egypt", "Aswan"),
    ("EGHRK", "Hurghada International Cargo (مطار الغردقة الدولي)", "Airport", "Egypt", "Red Sea"),
    ("EGSSZ", "Sharm El Sheikh Cargo Airport (مطار شرم الشيخ الدولي)", "Airport", "Egypt", "South Sinai"),
    ("EGDBB", "El Dabaa / Al Alamein Cargo Airport (مطار العلمين الدولي)", "Airport", "Egypt", "Matrouh"),
    ("EGTBA", "Taba International Airport (مطار طابا الدولي)", "Airport", "Egypt", "South Sinai"),
    
    # Egypt Dry Ports & Logistics Centers (الموانئ الجافة والمراكز اللوجستية)
    ("EGOCT", "6th of October Dry Port / ODPI (الميناء الجاف بـ 6 أكتوبر)", "Dry Port", "Egypt", "6th of October"),
    ("EGRAM", "10th of Ramadan Dry Port (الميناء الجاف بالعاشر من رمضان)", "Dry Port", "Egypt", "10th of Ramadan"),
    ("EGSAD", "Sadat City Dry Port (الميناء الجاف بمدينة السادات)", "Dry Port", "Egypt", "Sadat City"),
    ("EGBOR", "Borg El Arab Dry Port (الميناء الجاف ببرج العرب)", "Dry Port", "Egypt", "Borg El Arab"),
    ("EGSHG", "Sohag Dry Port (الميناء الجاف بسوهاج الجديدة)", "Dry Port", "Egypt", "Sohag"),
    ("EGBNS", "Beni Suef Dry Port (الميناء الجاف ببني سويف)", "Dry Port", "Egypt", "Beni Suef"),
    ("EGFYM", "Fayoum Dry Port (الميناء الجاف بالكوم أوشيم الفيوم)", "Dry Port", "Egypt", "Fayoum"),
    ("EGBAD", "Badr Logistics City / Dry Port (الميناء الجاف بمدينة بدر)", "Dry Port", "Egypt", "Cairo"),
    
    # Egypt Land Borders & Border Crossings (المنافذ البرية والمعابر الحدودية)
    ("EGSLM", "Salloum Land Border Crossing (منفذ السلوم البري مع ليبيا)", "Land Border", "Egypt", "Matrouh"),
    ("EGAWN", "Qastal Land Border Crossing (منفذ قسطل البري مع السودان)", "Land Border", "Egypt", "Aswan"),
    ("EGARK", "Argeen Land Border Crossing (منفذ أرقين البري مع السودان)", "Land Border", "Egypt", "Aswan"),
    ("EGTAB", "Taba Land Border Port (منفذ طابا البري)", "Land Border", "Egypt", "Taba"),
    ("EGOJA", "Al Awja Land Cargo Port (منفذ العوجة البري التجاري)", "Land Border", "Egypt", "North Sinai"),
    ("EGRAH", "Rafah Land Crossing (معبر رفح البري)", "Land Border", "Egypt", "North Sinai"),
    ("EGHDB", "Ras Hadarba Land Crossing (منفذ رأس حدربة البري)", "Land Border", "Egypt", "Red Sea"),

    # --- CHINA (Major Sea Ports & Airports) ---
    ("CNSHA", "Shanghai Port / Yangshan (ميناء شنغهاي)", "Sea Port", "China", "Shanghai"),
    ("CNNGB", "Ningbo-Zhoushan Port (ميناء نينغبو تشوشان)", "Sea Port", "China", "Ningbo"),
    ("CNSZX", "Shenzhen Port / Yantian / Shekou (ميناء شنتشن)", "Sea Port", "China", "Shenzhen"),
    ("CNGZG", "Guangzhou Port / Nansha (ميناء قوانغتشو)", "Sea Port", "China", "Guangzhou"),
    ("CNQDG", "Qingdao Port (ميناء تشينغداو)", "Sea Port", "China", "Qingdao"),
    ("CNTNJ", "Tianjin Port / Xingang (ميناء تيانجين)", "Sea Port", "China", "Tianjin"),
    ("CNXMN", "Xiamen Port (ميناء شيامن)", "Sea Port", "China", "Xiamen"),
    ("CNDAL", "Dalian Port (ميناء داليان)", "Sea Port", "China", "Dalian"),
    ("CNLYG", "Lianyungang Port (ميناء ليانيونغانغ)", "Sea Port", "China", "Lianyungang"),
    ("CNFOC", "Fuzhou Port (ميناء فوتشو)", "Sea Port", "China", "Fuzhou"),
    ("CNPVG", "Shanghai Pudong Cargo Airport (مطار بودونغ شنغهاي للشحن)", "Airport", "China", "Shanghai"),
    ("CNCAN", "Guangzhou Baiyun Cargo Airport (مطار قوانغتشو باييون)", "Airport", "China", "Guangzhou"),
    ("CNPEK", "Beijing Capital Cargo Airport (مطار بكين الدولي)", "Airport", "China", "Beijing"),
    ("CNSZXA", "Shenzhen Bao'an Cargo Airport (مطار شنتشن باوان للشحن)", "Airport", "China", "Shenzhen"),
    ("CNHKG", "Hong Kong Port (ميناء هونغ كونغ البحري)", "Sea Port", "Hong Kong", "Hong Kong"),
    ("HKHKG", "Hong Kong International Cargo Airport (مطار هونغ كونغ الدولي)", "Airport", "Hong Kong", "Hong Kong"),

    # --- ARAB GULF & MIDDLE EAST ---
    ("AEJEA", "Jebel Ali Port / DP World (ميناء جبل علي - دبي)", "Sea Port", "United Arab Emirates", "Dubai"),
    ("AEKHL", "Khalifa Port / Abu Dhabi (ميناء خليفة - أبوظبي)", "Sea Port", "United Arab Emirates", "Abu Dhabi"),
    ("AESHJ", "Sharjah Port / Port Khalid (ميناء خالد - الشارقة)", "Sea Port", "United Arab Emirates", "Sharjah"),
    ("AEFJR", "Fujairah Port / Oil Bunkering (ميناء الفجيرة)", "Sea Port", "United Arab Emirates", "Fujairah"),
    ("AEDXB", "Dubai International Cargo Airport (قرية الشحن - مطار دبي)", "Airport", "United Arab Emirates", "Dubai"),
    ("AEDWC", "Al Maktoum Cargo Airport / DWC (مطار آل مكتوم للشحن)", "Airport", "United Arab Emirates", "Dubai"),
    ("AEAUH", "Abu Dhabi International Cargo (مطار أبوظبي الدولي)", "Airport", "United Arab Emirates", "Abu Dhabi"),
    ("AEGHW", "Al Ghuwaifat Land Border Crossing (منفذ الغويفات البري)", "Land Border", "United Arab Emirates", "Abu Dhabi"),

    ("SAJED", "Jeddah Islamic Port (ميناء جدة الإسلامي)", "Sea Port", "Saudi Arabia", "Jeddah"),
    ("SADMM", "King Abdulaziz Port Dammam (ميناء الملك عبد العزيز بالدمام)", "Sea Port", "Saudi Arabia", "Dammam"),
    ("SAJUB", "Jubail Commercial Port (ميناء الجبيل التجاري)", "Sea Port", "Saudi Arabia", "Jubail"),
    ("SAYAN", "Yanbu Commercial & Industrial Port (ميناء ينبع)", "Sea Port", "Saudi Arabia", "Yanbu"),
    ("SAKAP", "King Abdullah Port / KAEC (ميناء الملك عبد الله - رابغ)", "Sea Port", "Saudi Arabia", "Rabigh"),
    ("SARUH", "Riyadh King Khalid Cargo Airport (مطار الملك خالد الدولي بالرياض)", "Airport", "Saudi Arabia", "Riyadh"),
    ("SAJED2", "Jeddah King Abdulaziz Cargo Airport (مطار الملك عبد العزيز بجدة)", "Airport", "Saudi Arabia", "Jeddah"),
    ("SABTH", "Al Batha Land Border (منفذ البطحاء البري)", "Land Border", "Saudi Arabia", "Eastern Province"),
    ("SAKHA", "Khafji Land Border (منفذ الخفجي البري مع الكويت)", "Land Border", "Saudi Arabia", "Eastern Province"),
    ("SAHAL", "Halat Ammar Land Border (منفذ حالة عمار البري مع الأردن)", "Land Border", "Saudi Arabia", "Tabuk"),

    ("KWSWK", "Shuwaikh Port (ميناء الشويخ)", "Sea Port", "Kuwait", "Kuwait City"),
    ("KWSAA", "Shuaiba Port (ميناء الشعيبة)", "Sea Port", "Kuwait", "Shuaiba"),
    ("KWKWI", "Kuwait International Cargo Airport (مطار الكويت الدولي للشحن)", "Airport", "Kuwait", "Kuwait City"),
    ("KWNWS", "Nuwaiseeb Land Border (منفذ النويصيب البري)", "Land Border", "Kuwait", "Ahmadi"),
    ("KWSLM", "Salmi Land Border (منفذ السالمي البري مع السعودية)", "Land Border", "Kuwait", "Jahra"),

    ("QAHMD", "Hamad Port / Doha (ميناء حمد البحري)", "Sea Port", "Qatar", "Doha"),
    ("QADOH", "Doha Hamad International Cargo (مطار حمد الدولي للشحن)", "Airport", "Qatar", "Doha"),
    ("QAABU", "Abu Samra Land Border (منفذ أبو سمرة البري مع السعودية)", "Land Border", "Qatar", "Abu Samra"),

    ("OMSOH", "Sohar Port (ميناء صحار)", "Sea Port", "Oman", "Sohar"),
    ("OMSLH", "Salalah Port (ميناء صلالة)", "Sea Port", "Oman", "Salalah"),
    ("OMDQM", "Duqm Port (ميناء الدقم)", "Sea Port", "Oman", "Duqm"),
    ("OMMCT", "Muscat International Cargo (مطار مسقط الدولي)", "Airport", "Oman", "Muscat"),
    ("OMWJG", "Wajajah Land Border (منفذ الوجاجة البري مع الإمارات)", "Land Border", "Oman", "Batinah"),

    ("BHKBS", "Khalifa Bin Salman Port (ميناء خليفة بن سلمان)", "Sea Port", "Bahrain", "Hidd"),
    ("BHBAH", "Bahrain International Cargo Airport (مطار البحرين الدولي)", "Airport", "Bahrain", "Muharraq"),
    ("BHKFD", "King Fahd Causeway Border (منفذ جسر الملك فهد)", "Land Border", "Bahrain", "Jasra"),

    ("JOAQB", "Aqaba Container Terminal / ACT (ميناء العقبة للحاويات)", "Sea Port", "Jordan", "Aqaba"),
    ("JOAMM", "Queen Alia International Cargo (مطار الملكة علياء الدولي)", "Airport", "Jordan", "Amman"),
    ("JOOMR", "Al Omari Land Border Crossing (منفذ العمري البري مع السعودية)", "Land Border", "Jordan", "Zarqa"),
    ("JOJAB", "Jaber Land Border Crossing (معبر جابر البري مع سوريا)", "Land Border", "Jordan", "Mafraq"),

    ("LBBYR", "Beirut Port (ميناء بيروت البحري)", "Sea Port", "Lebanon", "Beirut"),
    ("LBTRP", "Tripoli Port (ميناء طرابلس البحري)", "Sea Port", "Lebanon", "Tripoli"),
    ("LBBEY", "Beirut Rafic Hariri Cargo Airport (مطار رفيق الحريري الدولي)", "Airport", "Lebanon", "Beirut"),
    ("LBMAS", "Masnaa Border Crossing (معبر المصنع البري مع سوريا)", "Land Border", "Lebanon", "Bekaa"),

    ("IQBSR", "Umm Qasr Port (ميناء أم قصر)", "Sea Port", "Iraq", "Basra"),
    ("IQFAW", "Al Faw Grand Port (ميناء الفاو الكبير)", "Sea Port", "Iraq", "Basra"),
    ("IQBGW", "Baghdad International Cargo (مطار بغداد الدولي للشحن)", "Airport", "Iraq", "Baghdad"),
    ("IQSFW", "Safwan Land Border Crossing (منفذ سفوان البري مع الكويت)", "Land Border", "Iraq", "Basra"),
    ("IQTRB", "Trebil Land Border (منفذ طريبيل البري مع الأردن)", "Land Border", "Iraq", "Anbar"),

    # --- EUROPE (Major Sea Ports & Airports) ---
    ("NLRTM", "Rotterdam Port / Maasvlakte (ميناء روتردام)", "Sea Port", "Netherlands", "Rotterdam"),
    ("NLAMS", "Amsterdam Port (ميناء أمستردام)", "Sea Port", "Netherlands", "Amsterdam"),
    ("NLSPL", "Amsterdam Schiphol Cargo Airport (مطار سخيبول للشحن)", "Airport", "Netherlands", "Amsterdam"),

    ("BEANR", "Antwerp-Bruges Port (ميناء أنتويرب - بروج)", "Sea Port", "Belgium", "Antwerp"),
    ("BEZEE", "Zeebrugge Port (ميناء زيبروج)", "Sea Port", "Belgium", "Zeebrugge"),
    ("BEBRU", "Brussels Airport Cargo (مطار بروكسل للشحن)", "Airport", "Belgium", "Brussels"),
    ("BELGG", "Liege Cargo Airport / Hub (مطار لييج للشحن الجوي)", "Airport", "Belgium", "Liege"),

    ("DEHAM", "Hamburg Port (ميناء هامبورغ)", "Sea Port", "Germany", "Hamburg"),
    ("DEBRE", "Bremerhaven Port (ميناء بريمرهافن)", "Sea Port", "Germany", "Bremerhaven"),
    ("DEWVN", "Wilhelmshaven JadeWeserPort (ميناء فيلهلمسهافن)", "Sea Port", "Germany", "Wilhelmshaven"),
    ("DEFRA", "Frankfurt Cargo City (مطار فرانكفورت الدولي للشحن)", "Airport", "Germany", "Frankfurt"),
    ("DELEJ", "Leipzig/Halle DHL Air Cargo Hub (مطار لايبزيغ للشحن)", "Airport", "Germany", "Leipzig"),
    ("DEMUC", "Munich Cargo Airport (مطار ميونخ الدولي)", "Airport", "Germany", "Munich"),

    ("ITGOA", "Genoa Port (ميناء جنوى)", "Sea Port", "Italy", "Genoa"),
    ("ITSPE", "La Spezia Port (ميناء لا سبيتسيا)", "Sea Port", "Italy", "La Spezia"),
    ("ITTRS", "Trieste Port (ميناء ترييستي)", "Sea Port", "Italy", "Trieste"),
    ("ITLIV", "Livorno Port (ميناء ليفورنو)", "Sea Port", "Italy", "Livorno"),
    ("ITNAP", "Naples Port (ميناء نابولي)", "Sea Port", "Italy", "Naples"),
    ("ITGIT", "Gioia Tauro Port (ميناء جويا تاورو)", "Sea Port", "Italy", "Gioia Tauro"),
    ("ITMXP", "Milan Malpensa Cargo Airport (مطار ميلانو مالبينسا)", "Airport", "Italy", "Milan"),
    ("ITFCO", "Rome Fiumicino Cargo (مطار روما فيوميتشينو)", "Airport", "Italy", "Rome"),

    ("ESVLC", "Valencia Port (ميناء فالنسيا)", "Sea Port", "Spain", "Valencia"),
    ("ESBCN", "Barcelona Port (ميناء برشلونة)", "Sea Port", "Spain", "Barcelona"),
    ("ESALG", "Algeciras Port (ميناء الجزيرة الخضراء)", "Sea Port", "Spain", "Algeciras"),
    ("ESBIL", "Bilbao Port (ميناء بلباو)", "Sea Port", "Spain", "Bilbao"),
    ("ESMAD", "Madrid Barajas Cargo Airport (مطار مدريد باراخاس)", "Airport", "Spain", "Madrid"),

    ("FRMRS", "Marseille-Fos Port (ميناء مرسيليا)", "Sea Port", "France", "Marseille"),
    ("FRLEH", "Le Havre Port / HAROPA (ميناء لو هافر)", "Sea Port", "France", "Le Havre"),
    ("FRDUN", "Dunkirk Port (ميناء دونكيرك)", "Sea Port", "France", "Dunkirk"),
    ("FRCDG", "Paris Charles de Gaulle Cargo (مطار باريس شارل ديغول)", "Airport", "France", "Paris"),

    ("GBFXT", "Felixstowe Port (ميناء فيلكستو)", "Sea Port", "United Kingdom", "Felixstowe"),
    ("GBSOU", "Southampton Port (ميناء ساوثهامبتون)", "Sea Port", "United Kingdom", "Southampton"),
    ("GBLON", "London Gateway Port (ميناء لندن غيتواي)", "Sea Port", "United Kingdom", "London"),
    ("GBLHR", "London Heathrow Cargo Airport (مطار لندن هيثرو للشحن)", "Airport", "United Kingdom", "London"),
    ("GBEMA", "East Midlands Air Cargo Hub (مطار إيست ميدلاندز)", "Airport", "United Kingdom", "Derby"),

    ("TRIST", "Istanbul Ambarli Port (ميناء إسطنبول أمبارلي)", "Sea Port", "Turkey", "Istanbul"),
    ("TRMERS", "Mersin International Port (ميناء مرسين الدولي)", "Sea Port", "Turkey", "Mersin"),
    ("TRALI", "Aliaga Port / Izmir (ميناء ألياجا - إزمير)", "Sea Port", "Turkey", "Izmir"),
    ("TRISG", "Gebze / Yilport (ميناء يلبورت - غبزة)", "Sea Port", "Turkey", "Kocaeli"),
    ("TRISL", "Istanbul Grand Airport Cargo (مطار إسطنبول الدولي للشحن)", "Airport", "Turkey", "Istanbul"),
    ("TRKPK", "Kapikule Land Border Crossing (معبر كابيكولي البري مع بلغاريا)", "Land Border", "Turkey", "Edirne"),
    ("TRGBL", "Gurbulak Land Border Crossing (معبر غوربولاك مع إيران)", "Land Border", "Turkey", "Agri"),

    ("GRPIR", "Piraeus Port / COSCO (ميناء بيرايوس - أثينا)", "Sea Port", "Greece", "Athens"),
    ("GRSKG", "Thessaloniki Port (ميناء سالونيك)", "Sea Port", "Greece", "Thessaloniki"),
    ("GRATH", "Athens Eleftherios Venizelos Cargo (مطار أثينا الدولي)", "Airport", "Greece", "Athens"),

    ("RUMOW", "Novorossiysk Black Sea Port (ميناء نوفوروسيسك)", "Sea Port", "Russian Federation", "Novorossiysk"),
    ("RUSPT", "Saint Petersburg Port (ميناء سانت بطرسبرغ)", "Sea Port", "Russian Federation", "Saint Petersburg"),
    ("RUVVO", "Vladivostok Pacific Port (ميناء فلاديفوستوك)", "Sea Port", "Russian Federation", "Vladivostok"),
    ("RUSVO", "Moscow Sheremetyevo Cargo (مطار شيريميتييفو موسكو)", "Airport", "Russian Federation", "Moscow"),

    # --- AMERICAS (USA, Canada, Brazil, Mexico, etc.) ---
    ("USNYC", "Port of New York and New Jersey (ميناء نيويورك ونيوجيرسي)", "Sea Port", "United States", "New York"),
    ("USLAX", "Port of Los Angeles (ميناء لوس أنجلوس)", "Sea Port", "United States", "Los Angeles"),
    ("USLGB", "Port of Long Beach (ميناء لونغ بيتش)", "Sea Port", "United States", "Long Beach"),
    ("USHOU", "Port of Houston (ميناء هيوستن)", "Sea Port", "United States", "Houston"),
    ("USSAV", "Port of Savannah (ميناء سافانا)", "Sea Port", "United States", "Savannah"),
    ("USCHS", "Port of Charleston (ميناء تشارلستون)", "Sea Port", "United States", "Charleston"),
    ("USORF", "Port of Virginia / Norfolk (ميناء نورفولك)", "Sea Port", "United States", "Norfolk"),
    ("USSEA", "Port of Seattle (ميناء سياتل)", "Sea Port", "United States", "Seattle"),
    ("USOAK", "Port of Oakland (ميناء أوكلاند)", "Sea Port", "United States", "Oakland"),
    ("USMEM", "Memphis FedEx World Cargo Hub (مطار ممفيس للشحن الدولي)", "Airport", "United States", "Memphis"),
    ("USORD", "Chicago O'Hare Cargo Airport (مطار شيكاغو أوهير)", "Airport", "United States", "Chicago"),
    ("USMIA", "Miami Americas Cargo Gateway (مطار ميامي الدولي للشحن)", "Airport", "United States", "Miami"),
    ("USJFK", "New York JFK Cargo Airport (مطار كينيدي نيويورك)", "Airport", "United States", "New York"),
    ("USLAXA", "Los Angeles LAX Cargo (مطار لوس أنجلوس للشحن)", "Airport", "United States", "Los Angeles"),
    ("USLAR", "Laredo World Trade Land Bridge (منفذ لاريدو البري مع المكسيك)", "Land Border", "United States", "Texas"),
    ("USDET", "Ambassador Bridge Land Border (جسر أمباسادور البري مع كندا)", "Land Border", "United States", "Detroit"),

    ("CAVAN", "Port of Vancouver (ميناء فانكوفر)", "Sea Port", "Canada", "Vancouver"),
    ("CAMTR", "Port of Montreal (ميناء مونتريال)", "Sea Port", "Canada", "Montreal"),
    ("CAPRR", "Prince Rupert Port (ميناء برينس روبرت)", "Sea Port", "Canada", "Prince Rupert"),
    ("CAYYZ", "Toronto Pearson Cargo Airport (مطار تورونتو بيرسون)", "Airport", "Canada", "Toronto"),

    ("MXMZT", "Manzanillo Port (ميناء مانزانيلو)", "Sea Port", "Mexico", "Manzanillo"),
    ("MXLZC", "Lazaro Cardenas Port (ميناء لازارو كارديناس)", "Sea Port", "Mexico", "Lazaro Cardenas"),
    ("MXVER", "Veracruz Port (ميناء فيراكروز)", "Sea Port", "Mexico", "Veracruz"),
    ("MXMEX", "Mexico City Cargo Airport (مطار مكسيكو سيتي الدولي)", "Airport", "Mexico", "Mexico City"),
    ("MXNLD", "Nuevo Laredo Land Border (منفذ نويفو لاريدو البري)", "Land Border", "Mexico", "Tamaulipas"),

    ("BRSSZ", "Santos Port (ميناء سانتوس - ساو باولو)", "Sea Port", "Brazil", "Santos"),
    ("BRPNG", "Paranagua Port (ميناء باراناغوا)", "Sea Port", "Brazil", "Paranagua"),
    ("BRRIO", "Rio de Janeiro Port (ميناء ريو دي جانيرو)", "Sea Port", "Brazil", "Rio de Janeiro"),
    ("BRGRU", "Sao Paulo Guarulhos Cargo Airport (مطار غواروليوس ساو باولو)", "Airport", "Brazil", "Sao Paulo"),

    # --- ASIA & OCEANIA (India, Japan, South Korea, Singapore, Malaysia, Australia) ---
    ("INNSA", "Jawaharlal Nehru Port / Nhava Sheva (ميناء نافا شيفا - مومباي)", "Sea Port", "India", "Mumbai"),
    ("INMUN", "Mundra Port / Adani Ports (ميناء موندرا)", "Sea Port", "India", "Gujarat"),
    ("INMAA", "Chennai Port (ميناء تشيناي)", "Sea Port", "India", "Chennai"),
    ("INCCU", "Kolkata Syama Prasad Port (ميناء كولكاتا)", "Sea Port", "India", "Kolkata"),
    ("INCOK", "Cochin Port / Vallarpadam (ميناء كوتشين)", "Sea Port", "India", "Kochi"),
    ("INDEL", "Delhi Indira Gandhi Cargo Airport (مطار دلهي إنديرا غاندي)", "Airport", "India", "Delhi"),
    ("INBOM", "Mumbai Chhatrapati Shivaji Cargo (مطار مومباي الدولي)", "Airport", "India", "Mumbai"),

    ("JPTYO", "Tokyo Port / Oi Terminal (ميناء طوكيو)", "Sea Port", "Japan", "Tokyo"),
    ("JPYOK", "Yokohama Port (ميناء يوكوهاما)", "Sea Port", "Japan", "Yokohama"),
    ("JPNGO", "Nagoya Port (ميناء ناغويا)", "Sea Port", "Japan", "Nagoya"),
    ("JPKOB", "Kobe Port (ميناء كوبه)", "Sea Port", "Japan", "Kobe"),
    ("JPOSA", "Osaka Port (ميناء أوساكا)", "Sea Port", "Japan", "Osaka"),
    ("JPNRT", "Tokyo Narita Cargo Airport (مطار ناريتا طوكيو للشحن)", "Airport", "Japan", "Tokyo"),
    ("JPKIX", "Kansai International Cargo Airport (مطار كانساي للشحن)", "Airport", "Japan", "Osaka"),

    ("KRPUS", "Busan Port / PNC (ميناء بوسان الدولي)", "Sea Port", "South Korea", "Busan"),
    ("KRINC", "Incheon Port (ميناء إنتشون البحري)", "Sea Port", "South Korea", "Incheon"),
    ("KRGYA", "Gwangyang Port (ميناء غوانغيانغ)", "Sea Port", "South Korea", "Gwangyang"),
    ("KRICH", "Incheon International Cargo Hub (مطار إنتشون الدولي للشحن)", "Airport", "South Korea", "Incheon"),

    ("SGSIN", "Singapore Port / PSA Terminals (ميناء سنغافورة العالمي)", "Sea Port", "Singapore", "Singapore"),
    ("SGSIN2", "Singapore Changi Air Cargo Center (مطار شانغي سنغافورة للشحن)", "Airport", "Singapore", "Singapore"),

    ("MYPKG", "Port Klang / Westports / Northport (ميناء كلانج)", "Sea Port", "Malaysia", "Klang"),
    ("MYTPP", "Tanjung Pelepas Port (ميناء تانجونغ بيليباس)", "Sea Port", "Malaysia", "Johor"),
    ("MYKUL", "Kuala Lumpur International Cargo (مطار كوالالمبور للشحن)", "Airport", "Malaysia", "Kuala Lumpur"),

    ("VNSGN", "Ho Chi Minh City / Cat Lai Port (ميناء هو تشي منه - كات لاي)", "Sea Port", "Vietnam", "Ho Chi Minh"),
    ("VNHPH", "Haiphong Port / Lach Huyen (ميناء هايفونغ)", "Sea Port", "Vietnam", "Haiphong"),
    ("VNCMT", "Cai Mep Deep Sea Port (ميناء كاي ميب)", "Sea Port", "Vietnam", "Vung Tau"),
    ("VNHAN", "Hanoi Noi Bai Cargo Airport (مطار هانوي نوي باي)", "Airport", "Vietnam", "Hanoi"),

    ("IDJKT", "Jakarta Tanjung Priok Port (ميناء تانجونغ بريوك - جاكرتا)", "Sea Port", "Indonesia", "Jakarta"),
    ("IDSUB", "Surabaya Tanjung Perak (ميناء سورابايا)", "Sea Port", "Indonesia", "Surabaya"),
    ("IDCGK", "Jakarta Soekarno-Hatta Cargo (مطار جاكرتا للشحن)", "Airport", "Indonesia", "Jakarta"),

    ("THBKK", "Bangkok Klong Toey Port (ميناء بانكوك)", "Sea Port", "Thailand", "Bangkok"),
    ("THLCH", "Laem Chabang Port (ميناء لايم تشابانغ)", "Sea Port", "Thailand", "Chonburi"),
    ("THBKK2", "Bangkok Suvarnabhumi Cargo Airport (مطار سوفارنابومي للشحن)", "Airport", "Thailand", "Bangkok"),

    ("AUBNE", "Port of Brisbane (ميناء بريسبان)", "Sea Port", "Australia", "Brisbane"),
    ("AUSYD", "Port Botany / Sydney (ميناء سيدني بوتاني)", "Sea Port", "Australia", "Sydney"),
    ("AUMEL", "Port of Melbourne (ميناء ملبورن)", "Sea Port", "Australia", "Melbourne"),
    ("AUFRE", "Fremantle Port / Perth (ميناء فريمانتل - بيرث)", "Sea Port", "Australia", "Perth"),
    ("AUADL", "Port Adelaide (ميناء أديلايد)", "Sea Port", "Australia", "Adelaide"),
    ("AUSYDA", "Sydney Kingsford Smith Cargo (مطار سيدني للشحن)", "Airport", "Australia", "Sydney"),

    # --- AFRICA (North Africa, West Africa, East Africa, South Africa) ---
    ("MATNG", "Tanger Med Port (ميناء طنجة المتوسط)", "Sea Port", "Morocco", "Tangier"),
    ("MACAS", "Casablanca Port (ميناء الدار البيضاء)", "Sea Port", "Morocco", "Casablanca"),
    ("MACMN", "Casablanca Mohammed V Cargo Airport (مطار محمد الخامس الدولي)", "Airport", "Morocco", "Casablanca"),
    ("MAGUR", "Guerguerat Border Crossing (معبر الكركرات البري مع موريتانيا)", "Land Border", "Morocco", "Guerguerat"),

    ("DZALG", "Algiers Port (ميناء الجزائر العاصمة)", "Sea Port", "Algeria", "Algiers"),
    ("DZORN", "Oran Port (ميناء وهران)", "Sea Port", "Algeria", "Oran"),
    ("DZAAE", "Annaba Port (ميناء عنابة)", "Sea Port", "Algeria", "Annaba"),
    ("DZALG2", "Algiers Houari Boumediene Cargo (مطار هواري بومدين للشحن)", "Airport", "Algeria", "Algiers"),
    ("DZTAL", "Taleb Larbi Land Border (معبر الطالب العربي البري مع تونس)", "Land Border", "Algeria", "El Oued"),

    ("TNRAD", "Rades Port (ميناء رادس - تونس)", "Sea Port", "Tunisia", "Tunis"),
    ("TNBIZ", "Bizerte Port (ميناء بنزرت)", "Sea Port", "Tunisia", "Bizerte"),
    ("TNTUN", "Tunis Carthage Cargo Airport (مطار تونس قرطاج الدولي)", "Airport", "Tunisia", "Tunis"),
    ("TNRAS", "Ras Jedir Land Border Crossing (معبر رأس جدير البري مع ليبيا)", "Land Border", "Tunisia", "Medenine"),

    ("LYTIP", "Tripoli Port (ميناء طرابلس البحري)", "Sea Port", "Libyan Arab Jamahiriya", "Tripoli"),
    ("LYBEN", "Benghazi Port (ميناء بنغازي البحري)", "Sea Port", "Libyan Arab Jamahiriya", "Benghazi"),
    ("LYMRA", "Misurata Free Zone Port (ميناء المنطقة الحرة مصراتة)", "Sea Port", "Libyan Arab Jamahiriya", "Misurata"),
    ("LYKHO", "Khoms Port (ميناء الخمس)", "Sea Port", "Libyan Arab Jamahiriya", "Khoms"),
    ("LYMGD", "Musaid Land Border Crossing (منفذ امساعد البري مع مصر)", "Land Border", "Libyan Arab Jamahiriya", "Musaid"),

    ("SDPZU", "Port Sudan (ميناء بورتسودان الرئيسي)", "Sea Port", "Sudan", "Port Sudan"),
    ("SDOSM", "Prince Osman Digna Port / Suakin (ميناء سواكن)", "Sea Port", "Sudan", "Suakin"),
    ("SDPZUA", "Port Sudan International Cargo (مطار بورتسودان الدولي)", "Airport", "Sudan", "Port Sudan"),
    ("SDKRT", "Khartoum International Cargo (مطار الخرطوم الدولي)", "Airport", "Sudan", "Khartoum"),
    ("SDASH", "Ashkeet Land Border Crossing (معبر أشكيت البري مع مصر)", "Land Border", "Sudan", "Wadi Halfa"),
    ("SDARG", "Argeen Sudan Land Border (معبر أرقين البري السوداني)", "Land Border", "Sudan", "Northern State"),

    ("DJJIB", "Djibouti Port / Doraleh (ميناء جيبوتي - دوراليه)", "Sea Port", "Djibouti", "Djibouti"),
    ("DJJIB2", "Djibouti Ambouli Cargo Airport (مطار جيبوتي أمبولي الدولي)", "Airport", "Djibouti", "Djibouti"),

    ("ZADUR", "Durban Port (ميناء ديربان)", "Sea Port", "South Africa", "Durban"),
    ("ZACPT", "Cape Town Port (ميناء كيب تاون)", "Sea Port", "South Africa", "Cape Town"),
    ("ZAPLZ", "Port Elizabeth / Ngqura (ميناء بورت إليزابيث)", "Sea Port", "South Africa", "Port Elizabeth"),
    ("ZAJNB", "Johannesburg O.R. Tambo Cargo (مطار جوهانسبرغ أو آر تامبو)", "Airport", "South Africa", "Johannesburg"),

    ("NGAPP", "Lagos Apapa Port (ميناء أبابا - لاغوس)", "Sea Port", "Nigeria", "Lagos"),
    ("NGTIN", "Tin Can Island Port (ميناء تين كان - لاغوس)", "Sea Port", "Nigeria", "Lagos"),
    ("NGLOS", "Lagos Murtala Muhammed Cargo (مطار مورتالا محمد الدولي)", "Airport", "Nigeria", "Lagos"),

    ("KEKPA", "Mombasa Port / Kilindini (ميناء مومباسا)", "Sea Port", "Kenya", "Mombasa"),
    ("KENBO", "Nairobi Jomo Kenyatta Cargo (مطار نيروبي جومو كينياتا)", "Airport", "Kenya", "Nairobi"),

    ("TZDAR", "Dar es Salaam Port (ميناء دار السلام)", "Sea Port", "Tanzania", "Dar es Salaam"),
    ("GHTEM", "Tema Port (ميناء تيما)", "Sea Port", "Ghana", "Tema"),
    ("CIABJ", "Abidjan Port (ميناء أبيدجان)", "Sea Port", "Cote D Ivoire", "Abidjan"),
    ("SNDKR", "Dakar Port (ميناء داكار)", "Sea Port", "Senegal", "Dakar"),
]

def execute_all_updates(db_path: Path):
    if not db_path.exists():
        return

    print(f"\n=======================================================")
    print(f" Executing updates on: {db_path.name}")
    print(f"=======================================================")
    conn = sqlite3.connect(db_path)
    cur = conn.cursor()

    now_iso = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    # 1. Wipe all projects
    print("   [1/4] Wiping all projects...")
    cur.execute("DELETE FROM projects;")
    conn.commit()

    # 2. Fix currency symbols for all currencies
    print("   [2/4] Fixing currency symbols for all currencies...")
    cur.execute("SELECT currency_id, currency_code FROM currencies;")
    all_currs = cur.fetchall()
    for c_id, code in all_currs:
        sym = CURRENCY_SYMBOLS.get(code, code)
        cur.execute(
            "UPDATE currencies SET currency_symbol = ?, updated_at = ? WHERE currency_id = ?;",
            (sym, now_iso, c_id)
        )
    conn.commit()

    # 3. Populate Major Global & Regional Sea Ports, Airports, Dry Ports, and Land Borders
    print(f"   [3/4] Populating major global ports, airports, and borders ({len(MAJOR_PORTS_AIRPORTS_BORDERS)} entries)...")
    for un_locode, name, loc_type, country, city in MAJOR_PORTS_AIRPORTS_BORDERS:
        cur.execute(
            """INSERT INTO transport_locations (un_locode, location_name, location_type, country, city, is_active, created_at, updated_at)
               VALUES (?, ?, ?, ?, ?, 1, ?, ?)
               ON CONFLICT(un_locode) DO UPDATE SET
                   location_name=excluded.location_name,
                   location_type=excluded.location_type,
                   country=excluded.country,
                   city=excluded.city,
                   updated_at=excluded.updated_at;""",
            (un_locode, name, loc_type, country, city, now_iso, now_iso)
        )
    conn.commit()

    # 4. Integrate world cities as international transport terminals/customs ports
    print("   [4/4] Integrating world cities and terminals into transport locations...")
    cur.execute("SELECT city_code, city_name, country_code FROM cities;")
    cities = cur.fetchall()
    
    # Map country codes to country names
    cur.execute("SELECT country_code, country_name FROM countries;")
    c_map = {row[0]: row[1] for row in cur.fetchall()}

    added_from_cities = 0
    for code, name, c_code in cities:
        country_name = c_map.get(c_code, c_code or "International")
        loc_type = "Port / Terminal"
        if "Port" in name or "Harbour" in name or "Marina" in name or "Terminal" in name or "FPSO" in name:
            loc_type = "Sea Port"
        elif "Apt" in name or "Airport" in name:
            loc_type = "Airport"
        elif "Border" in name or "Crossing" in name:
            loc_type = "Land Border"

        cur.execute(
            """INSERT OR IGNORE INTO transport_locations (un_locode, location_name, location_type, country, city, is_active, created_at, updated_at)
               VALUES (?, ?, ?, ?, ?, 1, ?, ?);""",
            (code, f"{name} ({code})", loc_type, country_name, name, now_iso, now_iso)
        )
        if cur.rowcount > 0:
            added_from_cities += 1

    conn.commit()

    # Stats Summary
    cur.execute("SELECT COUNT(*) FROM projects;")
    prj_cnt = cur.fetchone()[0]
    cur.execute("SELECT COUNT(*) FROM currencies WHERE currency_symbol = '' OR currency_symbol IS NULL;")
    empty_syms = cur.fetchone()[0]
    cur.execute("SELECT COUNT(*) FROM transport_locations;")
    ports_cnt = cur.fetchone()[0]
    print(f"   [SUMMARY] Projects: {prj_cnt} records | Empty Symbols: {empty_syms} | Transport Locations: {ports_cnt} total ports/airports/borders")
    conn.close()

if __name__ == "__main__":
    for db in DATABASES:
        execute_all_updates(db)
    print("\n[SUCCESS] Successfully wiped projects, fixed currency symbols, and populated all world transport locations!")
