import sys
import os
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
sys.stdout.reconfigure(encoding='utf-8')

from datetime import datetime, timezone
from database.database import SessionLocal, engine, Base
from modules.transport_locations.model import TransportLocation


GLOBAL_LOCATIONS = [
    # =========================================================================
    # 1. EGYPT (جمهورية مصر العربية) — All Sea Ports, Airports, Dry Ports, Land Outlets
    # =========================================================================
    # Egyptian Sea Ports (الموانئ البحرية المصرية)
    {"un_locode": "EGALY", "location_name": "Alexandria Port (ميناء الإسكندرية)", "location_type": "Sea Port", "country": "Egypt", "city": "Alexandria", "notes": "أكبر الموانئ التجارية المصرية على البحر المتوسط"},
    {"un_locode": "EGDKH", "location_name": "El Dekheila Port (ميناء الدخيلة)", "location_type": "Sea Port", "country": "Egypt", "city": "Alexandria", "notes": "الامتداد الطبيعي لميناء الإسكندرية ومحطة حاويات رئيسية"},
    {"un_locode": "EGDAM", "location_name": "Damietta Port (ميناء دمياط)", "location_type": "Sea Port", "country": "Egypt", "city": "Damietta", "notes": "محطة حاويات وبضائع عامة وصب سائل وجاف"},
    {"un_locode": "EGPSD", "location_name": "Port Said West Port (ميناء غرب بورسعيد)", "location_type": "Sea Port", "country": "Egypt", "city": "Port Said", "notes": "المدخل الشمالي لقناة السويس على البحر المتوسط"},
    {"un_locode": "EGPSE", "location_name": "Port Said East Container Terminal (ميناء شرق بورسعيد / SCCT)", "location_type": "Sea Port", "country": "Egypt", "city": "Port Said", "notes": "محطة الترانزيت المحورية الكبرى لقناة السويس"},
    {"un_locode": "EGSOK", "location_name": "Ain Sokhna Port (ميناء العين السخنة / DP World)", "location_type": "Sea Port", "country": "Egypt", "city": "Ain Sokhna", "notes": "بوابة البحر الأحمر والمنطقة الاقتصادية لقناة السويس"},
    {"un_locode": "EGADB", "location_name": "Adabiya Port (ميناء الأدبية)", "location_type": "Sea Port", "country": "Egypt", "city": "Suez", "notes": "ميناء البضائع العامة والصب الجاف والصب السائل بالسويس"},
    {"un_locode": "EGSUZ", "location_name": "Port Tawfik / Suez Port (ميناء بورتوفيق / السويس)", "location_type": "Sea Port", "country": "Egypt", "city": "Suez", "notes": "المدخل الجنوبي لقناة السويس وميناء الركاب والبضائع"},
    {"un_locode": "EGSGA", "location_name": "Safaga Port (ميناء سفاجا البحري)", "location_type": "Sea Port", "country": "Egypt", "city": "Red Sea", "notes": "ميناء رئيسي لخدمة الصعيد وتجارة الفوسفات والركاب"},
    {"un_locode": "EGNWB", "location_name": "Nuweiba Port (ميناء نويبع البحري)", "location_type": "Sea Port", "country": "Egypt", "city": "South Sinai", "notes": "الربط البحري مع ميناء العقبة الأردني وخط الجسر العربي"},
    {"un_locode": "EGAQR", "location_name": "Abu Qir Port (ميناء أبو قير الجديد)", "location_type": "Sea Port", "country": "Egypt", "city": "Alexandria", "notes": "ميناء بحري تجاري عميق ومحطة حاويات حديثة"},
    {"un_locode": "EGSID", "location_name": "Sidi Kerir Port (ميناء سيدي كرير)", "location_type": "Sea Port", "country": "Egypt", "city": "Alexandria", "notes": "محطة تداول وتصدير البترول والغاز (SUMED)"},
    {"un_locode": "EGAIS", "location_name": "Al Arish Port (ميناء العريش البحري)", "location_type": "Sea Port", "country": "Egypt", "city": "North Sinai", "notes": "ميناء شمال سيناء التجاري والصناعي"},
    {"un_locode": "EGHMR", "location_name": "Hamrawein Port (ميناء الحمراوين)", "location_type": "Sea Port", "country": "Egypt", "city": "Red Sea", "notes": "ميناء شحن وتصدير الفوسفات بالبحر الأحمر"},
    {"un_locode": "EGQSR", "location_name": "Quseir Port (ميناء القصير)", "location_type": "Sea Port", "country": "Egypt", "city": "Red Sea", "notes": "ميناء تعديني وتجاري بالبحر الأحمر"},
    {"un_locode": "EGTOR", "location_name": "El Tor Port (ميناء الطور البحري)", "location_type": "Sea Port", "country": "Egypt", "city": "South Sinai", "notes": "ميناء تجاري وخدمي بجنوب سيناء"},

    # Egyptian Airports (المطارات الجوية المصرية ومحطات الشحن الجوي)
    {"un_locode": "EGCAI", "location_name": "Cairo International Airport (مطار القاهرة الدولي / قرية البضائع)", "location_type": "Airport", "country": "Egypt", "city": "Cairo", "notes": "المركز الجوي الرئيسي للشحن والإفراج الجمركي بمصر"},
    {"un_locode": "EGHBE", "location_name": "Borg El Arab International Airport (مطار برج العرب الدولي)", "location_type": "Airport", "country": "Egypt", "city": "Alexandria", "notes": "مطار الإسكندرية والساحل الشمالي للشحن الجوي"},
    {"un_locode": "EGSPX", "location_name": "Sphinx International Airport (مطار سفنكس الدولي)", "location_type": "Airport", "country": "Egypt", "city": "Giza", "notes": "مطار غرب القاهرة لخدمة حركة البضائع والصادرات"},
    {"un_locode": "EGCCE", "location_name": "Capital International Airport (مطار العاصمة الإدارية الدولي)", "location_type": "Airport", "country": "Egypt", "city": "Cairo", "notes": "مطار شرق القاهرة والعاصمة الإدارية للشحن والركاب"},
    {"un_locode": "EGLXU", "location_name": "Luxor International Airport (مطار الأقصر الدولي)", "location_type": "Airport", "country": "Egypt", "city": "Luxor", "notes": "مطار شحن الصادرات الزراعية بصعيد مصر"},
    {"un_locode": "EGASW", "location_name": "Aswan International Airport (مطار أسوان الدولي)", "location_type": "Airport", "country": "Egypt", "city": "Aswan", "notes": "بوابة النقل الجوي لجنوب مصر"},
    {"un_locode": "EGHRG", "location_name": "Hurghada International Airport (مطار الغردقة الدولي)", "location_type": "Airport", "country": "Egypt", "city": "Red Sea", "notes": "مطار البحر الأحمر للشحن السريع"},
    {"un_locode": "EGSSH", "location_name": "Sharm El Sheikh International Airport (مطار شرم الشيخ الدولي)", "location_type": "Airport", "country": "Egypt", "city": "South Sinai", "notes": "مطار جنوب سيناء الدولي"},
    {"un_locode": "EGRMF", "location_name": "Marsa Alam International Airport (مطار مرسى علم الدولي)", "location_type": "Airport", "country": "Egypt", "city": "Red Sea", "notes": "مطار جنوب البحر الأحمر الدولي"},
    {"un_locode": "EGHMB", "location_name": "Sohag International Airport (مطار سوهاج الدولي)", "location_type": "Airport", "country": "Egypt", "city": "Sohag", "notes": "مطار وسط الصعيد التجاري"},
    {"un_locode": "EGATZ", "location_name": "Assiut International Airport (مطار أسيوط الدولي)", "location_type": "Airport", "country": "Egypt", "city": "Assiut", "notes": "مطار إقليم أسيوط"},

    # Egyptian Dry Ports & Inland Container Depots (الموانئ الجافة والمراكز اللوجستية)
    {"un_locode": "EG6OCT", "location_name": "6th of October Dry Port (الميناء الجاف بمدينة 6 أكتوبر)", "location_type": "Dry Port", "country": "Egypt", "city": "6th of October", "notes": "أول ميناء جاف متكامل بمصر متصل بالسكة الحديد والموانئ البحرية"},
    {"un_locode": "EG10R", "location_name": "10th of Ramadan Dry Port (الميناء الجاف بمدينة العاشر من رمضان)", "location_type": "Dry Port", "country": "Egypt", "city": "10th of Ramadan", "notes": "المركز اللوجستي للمنطقة الصناعية بالعاشر والشرقية"},
    {"un_locode": "EGSAD", "location_name": "Sadat City Dry Port (الميناء الجاف بمدينة السادات)", "location_type": "Dry Port", "country": "Egypt", "city": "Sadat City", "notes": "ميناء جاف لخدمة المنطقة الصناعية بالمنوفية والبحيرة"},
    {"un_locode": "EGBDR", "location_name": "Badr City Logistics Center / ICD (المركز اللوجستي والميناء الجاف بمدينة بدر)", "location_type": "Dry Port", "country": "Egypt", "city": "Cairo", "notes": "مركز لوجستي للتخليص الجمركي وتفريغ الحاويات"},
    {"un_locode": "EGBED", "location_name": "Borg El Arab Dry Port (الميناء الجاف ببرج العرب)", "location_type": "Dry Port", "country": "Egypt", "city": "Alexandria", "notes": "مركز لوجستي للصناعات بغرب الإسكندرية"},
    {"un_locode": "EGNCD", "location_name": "New Cairo Inland Container Depot (مستودع حاويات القاهرة الجديدة)", "location_type": "Dry Port", "country": "Egypt", "city": "Cairo", "notes": "مستودع جمركي لوجستي مغلق"},
    {"un_locode": "EGBNF", "location_name": "Beni Suef Logistics & Dry Port (الميناء الجاف ببني سويف)", "location_type": "Dry Port", "country": "Egypt", "city": "Beni Suef", "notes": "مركز لوجستي لصناعات ومصانع شمال الصعيد"},

    # Egyptian Land Border Ports (المنافذ البرية والمعابر الجمركية)
    {"un_locode": "EGSLM", "location_name": "Salloum Land Border Port (منفذ السلوم البري)", "location_type": "Land Border", "country": "Egypt", "city": "Matrouh", "notes": "المنفذ التجاري والبري الحدودي الرئيسي مع دولة ليبيا"},
    {"un_locode": "EGARG", "location_name": "Argeen Land Border Port (منفذ أرقين البري)", "location_type": "Land Border", "country": "Egypt", "city": "Aswan", "notes": "المعبر التجاري الدولي البري غرب النيل مع دولة السودان"},
    {"un_locode": "EGQAS", "location_name": "Qastal Land Border Port (منفذ قسطل البري)", "location_type": "Land Border", "country": "Egypt", "city": "Aswan", "notes": "المعبر التجاري الدولي البري شرق النيل مع دولة السودان"},
    {"un_locode": "EGTBA", "location_name": "Taba Land Border Crossing (معبر طابا البري)", "location_type": "Land Border", "country": "Egypt", "city": "South Sinai", "notes": "المنفذ البري الحدودي بجنوب سيناء"},
    {"un_locode": "EGRAF", "location_name": "Rafah Land Border Crossing (معبر رفح البري)", "location_type": "Land Border", "country": "Egypt", "city": "North Sinai", "notes": "المنفذ البري الحدودي بشمال سيناء"},
    {"un_locode": "EGAWJ", "location_name": "Al Awja Land Customs Crossing (منفذ العوجة الجمركي البري)", "location_type": "Land Border", "country": "Egypt", "city": "North Sinai", "notes": "منفذ التبادل التجاري البري بوسط سيناء"},

    # =========================================================================
    # 2. CHINA & EAST ASIA (الصين وشرق آسيا) — Major Origins for Egyptian Imports
    # =========================================================================
    {"un_locode": "CNSHA", "location_name": "Shanghai Port (ميناء شانغهاي)", "location_type": "Sea Port", "country": "China", "city": "Shanghai", "notes": "أكبر وأزحم ميناء حاويات في العالم"},
    {"un_locode": "CNNGB", "location_name": "Ningbo-Zhoushan Port (ميناء نينغبو زوشان)", "location_type": "Sea Port", "country": "China", "city": "Ningbo", "notes": "ثاني أكبر موانئ الصين وبوابة تصدير رئيسية"},
    {"un_locode": "CNSZX", "location_name": "Shenzhen / Yantian / Shekou Port (ميناء شينزين / يانتيان)", "location_type": "Sea Port", "country": "China", "city": "Shenzhen", "notes": "ميناء جنوب الصين الرئيسي لتصدير الإلكترونيات والمعدات"},
    {"un_locode": "CNCAN", "location_name": "Guangzhou / Nansha Port (ميناء غوانغتشو / نانشا)", "location_type": "Sea Port", "country": "China", "city": "Guangzhou", "notes": "ميناء إقليم كانتون ومصب نهر اللؤلؤ"},
    {"un_locode": "CNQDG", "location_name": "Qingdao Port (ميناء تشينغداو)", "location_type": "Sea Port", "country": "China", "city": "Qingdao", "notes": "ميناء رئيسي شمال الصين للكيماويات والمعدات الثقيلة"},
    {"un_locode": "CNTXG", "location_name": "Tianjin / Xingang Port (ميناء تيانجين / شينغانغ)", "location_type": "Sea Port", "country": "China", "city": "Tianjin", "notes": "البوابة البحرية للعاصمة بكين وشمال الصين"},
    {"un_locode": "CNXMN", "location_name": "Xiamen Port (ميناء شيامن)", "location_type": "Sea Port", "country": "China", "city": "Xiamen", "notes": "ميناء مقاطعة فوجيان للتجارة الدولية"},
    {"un_locode": "CNDLC", "location_name": "Dalian Port (ميناء داليان)", "location_type": "Sea Port", "country": "China", "city": "Dalian", "notes": "ميناء شمال شرق الصين التجاري والصناعي"},
    {"un_locode": "CNLYG", "location_name": "Lianyungang Port (ميناء ليانيونغانغ)", "location_type": "Sea Port", "country": "China", "city": "Lianyungang", "notes": "بداية جسر الأرض الأوراسي الجديد"},
    {"un_locode": "CNFOC", "location_name": "Fuzhou Port (ميناء فوتشو)", "location_type": "Sea Port", "country": "China", "city": "Fuzhou", "notes": "ميناء تجاري بمقاطعة فوجيان"},
    {"un_locode": "CNTAC", "location_name": "Taicang Port (ميناء تايتسانغ)", "location_type": "Sea Port", "country": "China", "city": "Taicang", "notes": "ميناء نهري وبحري على نهر اليانغتسي"},
    {"un_locode": "CNYIK", "location_name": "Yingkou Port (ميناء ينغكو)", "location_type": "Sea Port", "country": "China", "city": "Yingkou", "notes": "ميناء مقاطعة لياونينغ"},
    {"un_locode": "CNRZH", "location_name": "Rizhao Port (ميناء ريتشاو)", "location_type": "Sea Port", "country": "China", "city": "Rizhao", "notes": "ميناء الصب الجاف والحبوب بمقاطعة شاندونغ"},
    {"un_locode": "CNPVG", "location_name": "Shanghai Pudong International Airport (مطار شانغهاي بودنغ الدولي)", "location_type": "Airport", "country": "China", "city": "Shanghai", "notes": "أكبر مطار للشحن الجوي في الصين"},
    {"un_locode": "CNPEK", "location_name": "Beijing Capital International Airport (مطار بكين العاصمة الدولي)", "location_type": "Airport", "country": "China", "city": "Beijing", "notes": "مطار العاصمة للشحن الجوي"},
    {"un_locode": "CNPKX", "location_name": "Beijing Daxing International Airport (مطار بكين داشينغ الدولي)", "location_type": "Airport", "country": "China", "city": "Beijing", "notes": "المطار الدولي الحديث ببكين"},
    {"un_locode": "CNBAW", "location_name": "Guangzhou Baiyun Airport (مطار غوانغتشو بايون الدولي)", "location_type": "Airport", "country": "China", "city": "Guangzhou", "notes": "مركز الشحن الجوي لإقليم كانتون"},
    {"un_locode": "CNSZXA", "location_name": "Shenzhen Bao'an Airport (مطار شينزين باوآن الدولي)", "location_type": "Airport", "country": "China", "city": "Shenzhen", "notes": "مركز الشحن الإلكتروني السريع"},
    {"un_locode": "HKHKG", "location_name": "Hong Kong International Airport / Port (مطار وميناء هونغ كونغ الدولي)", "location_type": "Airport", "country": "Hong Kong", "city": "Hong Kong", "notes": "أكبر مطار للشحن الجوي على مستوى العالم"},

    # =========================================================================
    # 3. EUROPEAN UNION & TURKEY & UK (أوروبا وتركيا والمملكة المتحدة)
    # =========================================================================
    # Italy (إيطاليا - شريك تجاري استراتيجي)
    {"un_locode": "ITGOA", "location_name": "Genoa Port (ميناء جنوى)", "location_type": "Sea Port", "country": "Italy", "city": "Genoa", "notes": "البوابة البحرية الكبرى لشمال إيطاليا على المتوسط"},
    {"un_locode": "ITSPE", "location_name": "La Spezia Port (ميناء لا سبيتسيا)", "location_type": "Sea Port", "country": "Italy", "city": "La Spezia", "notes": "محطة حاويات متطورة لخدمة الصناعات الإيطالية"},
    {"un_locode": "ITTRS", "location_name": "Trieste Port (ميناء ترييستي)", "location_type": "Sea Port", "country": "Italy", "city": "Trieste", "notes": "بوابة البحر الأدرياتيكي والربط السككي مع وسط أوروبا"},
    {"un_locode": "ITLIV", "location_name": "Livorno Port (ميناء ليفورنو)", "location_type": "Sea Port", "country": "Italy", "city": "Livorno", "notes": "ميناء إقليم توسكانا للسيارات والبضائع العامة"},
    {"un_locode": "ITNAP", "location_name": "Naples Port (ميناء نابولي)", "location_type": "Sea Port", "country": "Italy", "city": "Naples", "notes": "ميناء جنوب إيطاليا التجاري"},
    {"un_locode": "ITGIT", "location_name": "Gioia Tauro Port (ميناء جويا تاورو)", "location_type": "Sea Port", "country": "Italy", "city": "Gioia Tauro", "notes": "محطة ترانزيت حاويات محورية في كالابريا"},
    {"un_locode": "ITVCE", "location_name": "Venice Port (ميناء البندقية / فينيسيا)", "location_type": "Sea Port", "country": "Italy", "city": "Venice", "notes": "ميناء تجاري وصناعي بشمال شرق إيطاليا"},
    {"un_locode": "ITRAN", "location_name": "Ravenna Port (ميناء رافينا)", "location_type": "Sea Port", "country": "Italy", "city": "Ravenna", "notes": "ميناء الصب والمواد الخام بالأدرياتيكي"},
    {"un_locode": "ITMXP", "location_name": "Milan Malpensa Airport (مطار ميلانو مالبينسا للشحن الجوي)", "location_type": "Airport", "country": "Italy", "city": "Milan", "notes": "المركز الجوي الرئيسي للشحن الصناعي الإيطالي"},
    {"un_locode": "ITFCO", "location_name": "Rome Fiumicino Airport (مطار روما فيوميتشينو الدولي)", "location_type": "Airport", "country": "Italy", "city": "Rome", "notes": "مطار العاصمة الإيطالية روما"},

    # Germany (ألمانيا)
    {"un_locode": "DEHAM", "location_name": "Hamburg Port (ميناء هامبورغ)", "location_type": "Sea Port", "country": "Germany", "city": "Hamburg", "notes": "أكبر موانئ ألمانيا وثاني أكبر موانئ أوروبا"},
    {"un_locode": "DEBRV", "location_name": "Bremerhaven Port (ميناء بريمرهافن)", "location_type": "Sea Port", "country": "Germany", "city": "Bremerhaven", "notes": "أكبر محطة تداول وتصدير سيارات وحاويات بألمانيا"},
    {"un_locode": "DEWVN", "location_name": "Wilhelmshaven Port (ميناء فيلهلمسهافن / JadeWeserPort)", "location_type": "Sea Port", "country": "Germany", "city": "Wilhelmshaven", "notes": "الميناء الوحيد ذو المياه العميقة بألمانيا"},
    {"un_locode": "DEFRA", "location_name": "Frankfurt Airport Cargo City (مطار فرانكفورت الدولي)", "location_type": "Airport", "country": "Germany", "city": "Frankfurt", "notes": "أكبر مطار للشحن الجوي في أوروبا"},
    {"un_locode": "DEMUC", "location_name": "Munich Airport (مطار ميونيخ الدولي)", "location_type": "Airport", "country": "Germany", "city": "Munich", "notes": "مطار جنوب ألمانيا للشحن الصناعي"},
    {"un_locode": "DELEJ", "location_name": "Leipzig/Halle Airport (مطار لايبزيغ / هاله)", "location_type": "Airport", "country": "Germany", "city": "Leipzig", "notes": "المركز العالمي للشحن الجوي لشركة DHL"},

    # Netherlands & Belgium (هولندا وبلجيكا)
    {"un_locode": "NLRTM", "location_name": "Rotterdam Port (ميناء روتردام)", "location_type": "Sea Port", "country": "Netherlands", "city": "Rotterdam", "notes": "أكبر ميناء بحري ومحطة لوجستية في أوروبا"},
    {"un_locode": "NLAMS", "location_name": "Amsterdam Port & Schiphol Airport (ميناء أمستردام ومطار سخيبول)", "location_type": "Airport", "country": "Netherlands", "city": "Amsterdam", "notes": "مركز شحن جوي وبحري أوروبي محوري"},
    {"un_locode": "BEANR", "location_name": "Port of Antwerp-Bruges (ميناء أنتويرب - بروج)", "location_type": "Sea Port", "country": "Belgium", "city": "Antwerp", "notes": "ثاني أكبر موانئ أوروبا والمركز الأول للبتروكيماويات"},
    {"un_locode": "BEZEE", "location_name": "Zeebrugge Port (ميناء زيبروج)", "location_type": "Sea Port", "country": "Belgium", "city": "Zeebrugge", "notes": "أكبر ميناء لتداول سيارات الرورو والغاز المسال"},
    {"un_locode": "BELGG", "location_name": "Liège Airport (مطار لييج للشحن الجوي)", "location_type": "Airport", "country": "Belgium", "city": "Liege", "notes": "مركز الشحن الجوي والطرود السريعة ببلجيكا"},

    # Spain & France (إسبانيا وفرنسا)
    {"un_locode": "ESVLC", "location_name": "Valencia Port (ميناء فالنسيا)", "location_type": "Sea Port", "country": "Spain", "city": "Valencia", "notes": "أكبر ميناء حاويات في إسبانيا والبحر المتوسط"},
    {"un_locode": "ESBCN", "location_name": "Barcelona Port (ميناء برشلونة)", "location_type": "Sea Port", "country": "Spain", "city": "Barcelona", "notes": "ميناء إقليم كتالونيا التجاري الدولي"},
    {"un_locode": "ESALG", "location_name": "Algeciras Port (ميناء الجزيرة الخضراء / الجزيرة)", "location_type": "Sea Port", "country": "Spain", "city": "Algeciras", "notes": "محطة الترانزيت الكبرى بمضيق جبل طارق"},
    {"un_locode": "ESMAD", "location_name": "Madrid-Barajas Airport (مطار مدريد باراخاس الدولي)", "location_type": "Airport", "country": "Spain", "city": "Madrid", "notes": "مطار العاصمة الإسبانية للشحن الجوي"},
    {"un_locode": "FRLEH", "location_name": "Le Havre / HAROPA Port (ميناء لوهافر)", "location_type": "Sea Port", "country": "France", "city": "Le Havre", "notes": "الميناء البحري الرئيسي لخدمة باريس وشمال فرنسا"},
    {"un_locode": "FRMRS", "location_name": "Marseille / Fos Port (ميناء مرسيليا / فوس)", "location_type": "Sea Port", "country": "France", "city": "Marseille", "notes": "ميناء جنوب فرنسا التجاري على البحر المتوسط"},
    {"un_locode": "FRCDG", "location_name": "Paris Charles de Gaulle Airport (مطار باريس شارل ديغول)", "location_type": "Airport", "country": "France", "city": "Paris", "notes": "أكبر مطارات فرنسا للشحن الجوي"},

    # Turkey (تركيا - شريك تجاري صناعي رئيسي)
    {"un_locode": "TRIST", "location_name": "Istanbul / Ambarli Port (ميناء إسطنبول / أمبارلي)", "location_type": "Sea Port", "country": "Turkey", "city": "Istanbul", "notes": "أكبر محطة حاويات في تركيا على بحر مرمرة"},
    {"un_locode": "TRMER", "location_name": "Mersin Port / MIP (ميناء مرسين الدولي)", "location_type": "Sea Port", "country": "Turkey", "city": "Mersin", "notes": "أكبر موانئ جنوب وشرق تركيا على البحر المتوسط"},
    {"un_locode": "TRIZM", "location_name": "Izmir / Aliaga Port (ميناء إزمير / علياغا)", "location_type": "Sea Port", "country": "Turkey", "city": "Izmir", "notes": "ميناء بحر إيجة التركي للصناعات والصلب"},
    {"un_locode": "TRGEM", "location_name": "Gemlik Port (ميناء غيمليك)", "location_type": "Sea Port", "country": "Turkey", "city": "Bursa", "notes": "ميناء صناعة السيارات والكيماويات ببورصة"},
    {"un_locode": "TRKOC", "location_name": "Kocaeli / Evyap / DP World Yarimca (ميناء كوجالي / ياريمجا)", "location_type": "Sea Port", "country": "Turkey", "city": "Kocaeli", "notes": "موانئ خليج إزميت الصناعية الكبرى"},
    {"un_locode": "TRISK", "location_name": "Iskenderun Port (ميناء إسكندرون)", "location_type": "Sea Port", "country": "Turkey", "city": "Hatay", "notes": "ميناء جنوب شرق تركيا للتجارة والصلب"},
    {"un_locode": "TRISTA", "location_name": "Istanbul Airport (مطار إسطنبول الدولي / كارجو)", "location_type": "Airport", "country": "Turkey", "city": "Istanbul", "notes": "المركز الجوي العالمي للخطوط التركية والشحن"},

    # United Kingdom (المملكة المتحدة)
    {"un_locode": "GBFXT", "location_name": "Felixstowe Port (ميناء فيلكستو)", "location_type": "Sea Port", "country": "United Kingdom", "city": "Felixstowe", "notes": "أكبر ميناء حاويات في بريطانيا"},
    {"un_locode": "GBSOU", "location_name": "Southampton Port (ميناء ساوثهامبتون)", "location_type": "Sea Port", "country": "United Kingdom", "city": "Southampton", "notes": "ميناء الحاويات وسيارات الرورو بجنوب إنجلترا"},
    {"un_locode": "GBLON", "location_name": "London Gateway Port (ميناء لندن جيتواي / DP World)", "location_type": "Sea Port", "country": "United Kingdom", "city": "London", "notes": "الميناء الذكي العميق على مصب نهر التايمز"},
    {"un_locode": "GBLHR", "location_name": "London Heathrow Airport (مطار لندن هيثرو الدولي)", "location_type": "Airport", "country": "United Kingdom", "city": "London", "notes": "المركز الجوي الرئيسي للشحن بالمملكة المتحدة"},

    # Greece & Russia (اليونان وروسيا)
    {"un_locode": "GRPIR", "location_name": "Piraeus Port (ميناء بيرايوس / كوسكو)", "location_type": "Sea Port", "country": "Greece", "city": "Athens", "notes": "أكبر موانئ اليونان وبوابة الحزام والطريق لجنوب أوروبا"},
    {"un_locode": "GRSKG", "location_name": "Thessaloniki Port (ميناء سالونيك)", "location_type": "Sea Port", "country": "Greece", "city": "Thessaloniki", "notes": "بوابة البلقان البحرية"},
    {"un_locode": "RUNVS", "location_name": "Novorossiysk Port (ميناء نوفوروسيسك)", "location_type": "Sea Port", "country": "Russia", "city": "Novorossiysk", "notes": "أكبر موانئ روسيا التجارية على البحر الأسود لتصدير الحبوب"},
    {"un_locode": "RULED", "location_name": "Saint Petersburg Port (ميناء سانت بطرسبرغ)", "location_type": "Sea Port", "country": "Russia", "city": "Saint Petersburg", "notes": "ميناء روسيا الرئيسي على بحر البلطيق"},

    # =========================================================================
    # 4. MIDDLE EAST & ARAB GULF (الشرق الأوسط والخليج العربي)
    # =========================================================================
    # UAE (الإمارات العربية المتحدة)
    {"un_locode": "AEJEA", "location_name": "Jebel Ali Port (ميناء جبل علي / DP World)", "location_type": "Sea Port", "country": "United Arab Emirates", "city": "Dubai", "notes": "أكبر ميناء اصطناعي وأكبر مركز لوجستي في الشرق الأوسط"},
    {"un_locode": "AEKHL", "location_name": "Khalifa Port (ميناء خليفة / أبوظبي)", "location_type": "Sea Port", "country": "United Arab Emirates", "city": "Abu Dhabi", "notes": "الميناء شبه الآلي المتطور بإمارة أبوظبي"},
    {"un_locode": "AEKLF", "location_name": "Khor Fakkan Port (ميناء خورفكان)", "location_type": "Sea Port", "country": "United Arab Emirates", "city": "Sharjah", "notes": "ميناء ترانزيت على خليج عمان خارج مضيق هرمز"},
    {"un_locode": "AEDXB", "location_name": "Dubai International Airport (مطار دبي الدولي للركاب والبضائع)", "location_type": "Airport", "country": "United Arab Emirates", "city": "Dubai", "notes": "المركز الجوي العالمي لطيران الإمارات للشحن"},
    {"un_locode": "AEDWC", "location_name": "Al Maktoum International Airport (مطار آل مكتوم الدولي / دبي ورلد سنترال)", "location_type": "Airport", "country": "United Arab Emirates", "city": "Dubai", "notes": "المدينة اللوجستية الجوية العالمية بدبي"},
    {"un_locode": "AEAUH", "location_name": "Zayed International Airport (مطار زايد الدولي / أبوظبي)", "location_type": "Airport", "country": "United Arab Emirates", "city": "Abu Dhabi", "notes": "مطار العاصمة أبوظبي الدولي"},
    {"un_locode": "AEGHW", "location_name": "Al Ghuwaifat Border Crossing (منفذ الغويفات الحدودي البري)", "location_type": "Land Border", "country": "United Arab Emirates", "city": "Abu Dhabi", "notes": "المنفذ البري الرئيسي الرابط بين الإمارات والسعودية"},

    # Saudi Arabia (المملكة العربية السعودية)
    {"un_locode": "SAJED", "location_name": "Jeddah Islamic Port (ميناء جدة الإسلامي)", "location_type": "Sea Port", "country": "Saudi Arabia", "city": "Jeddah", "notes": "أكبر وأهم موانئ السعودية على البحر الأحمر"},
    {"un_locode": "SADMM", "location_name": "King Abdulaziz Port / Dammam (ميناء الملك عبد العزيز بالدمام)", "location_type": "Sea Port", "country": "Saudi Arabia", "city": "Dammam", "notes": "بوابة الخليج العربي الرئيسية للمملكة"},
    {"un_locode": "SAKAP", "location_name": "King Abdullah Port (ميناء الملك عبد الله برابغ)", "location_type": "Sea Port", "country": "Saudi Arabia", "city": "Rabigh", "notes": "أحدث وأعمق موانئ الحاويات الخاصة بالسعودية"},
    {"un_locode": "SAJUB", "location_name": "Jubail Commercial Port (ميناء الجبيل التجاري والصناعي)", "location_type": "Sea Port", "country": "Saudi Arabia", "city": "Jubail", "notes": "ميناء تصدير البتروكيماويات والحديد"},
    {"un_locode": "SAYNB", "location_name": "Yanbu Commercial Port (ميناء ينبع التجاري والصناعي)", "location_type": "Sea Port", "country": "Saudi Arabia", "city": "Yanbu", "notes": "ميناء صناعي وتجاري على ساحل البحر الأحمر"},
    {"un_locode": "SARUH", "location_name": "Riyadh Dry Port & King Khalid Airport (الميناء الجاف بالرياض ومطار الملك خالد)", "location_type": "Dry Port", "country": "Saudi Arabia", "city": "Riyadh", "notes": "المركز اللوجستي الأكبر بالعاصمة الرياض"},
    {"un_locode": "SAJEDA", "location_name": "King Abdulaziz Airport Cargo Hub (مطار الملك عبدالعزيز الدولي بجدة)", "location_type": "Airport", "country": "Saudi Arabia", "city": "Jeddah", "notes": "المركز الجوي الرئيسي للشحن الجوي بالمنطقة الغربية"},
    {"un_locode": "SABTH", "location_name": "Al Batha Border Crossing (منفذ البطحاء البري الحدودي)", "location_type": "Land Border", "country": "Saudi Arabia", "city": "Eastern Province", "notes": "المنفذ البري الرابط بين السعودية والإمارات"},
    {"un_locode": "SAKFC", "location_name": "King Fahd Causeway Border (جسر الملك فهد - جمرك جسر البحرين)", "location_type": "Land Border", "country": "Saudi Arabia", "city": "Khobar", "notes": "المنفذ الجمركي البري الرابط بين السعودية ومملكة البحرين"},
    {"un_locode": "SAHAD", "location_name": "Al Haditha Border Crossing (منفذ الحديثة البري الحدودي)", "location_type": "Land Border", "country": "Saudi Arabia", "city": "Al Jouf", "notes": "أكبر منفذ بري بالشرق الأوسط الرابط بين السعودية والأردن"},

    # Jordan, Kuwait, Qatar, Oman, Bahrain
    {"un_locode": "JOAQJ", "location_name": "Aqaba Port (ميناء العقبة البحري)", "location_type": "Sea Port", "country": "Jordan", "city": "Aqaba", "notes": "المنفذ البحري الوحيد للمملكة الأردنية الهاشمية على البحر الأحمر"},
    {"un_locode": "JOAMM", "location_name": "Queen Alia International Airport (مطار الملكة علياء الدولي)", "location_type": "Airport", "country": "Jordan", "city": "Amman", "notes": "مطار العاصمة الأردنية عمان"},
    {"un_locode": "JOOMA", "location_name": "Al Omari Border Crossing (منفذ العمري البري)", "location_type": "Land Border", "country": "Jordan", "city": "Zarqa", "notes": "المنفذ البري الحدودي مع المملكة العربية السعودية"},
    {"un_locode": "KWSWK", "location_name": "Shuwaikh Port (ميناء الشويخ)", "location_type": "Sea Port", "country": "Kuwait", "city": "Kuwait City", "notes": "الميناء التجاري الرئيسي لدولة الكويت"},
    {"un_locode": "KWSAA", "location_name": "Shuaiba Port (ميناء الشعيبة)", "location_type": "Sea Port", "country": "Kuwait", "city": "Shuaiba", "notes": "الميناء الصناعي والتجاري الكويتي"},
    {"un_locode": "KWKWI", "location_name": "Kuwait International Airport (مطار الكويت الدولي)", "location_type": "Airport", "country": "Kuwait", "city": "Kuwait City", "notes": "مطار الكويت للشحن الجوي"},
    {"un_locode": "QAHMD", "location_name": "Hamad Port (ميناء حمد الدولي)", "location_type": "Sea Port", "country": "Qatar", "city": "Umm Al Houl", "notes": "الميناء البحري التجاري الرئيسي المتطور لدولة قطر"},
    {"un_locode": "QADOH", "location_name": "Hamad International Airport (مطار حمد الدولي بالدوحة)", "location_type": "Airport", "country": "Qatar", "city": "Doha", "notes": "المركز الجوي الرئيسي للخطوط القطرية للشحن"},
    {"un_locode": "QABSR", "location_name": "Abu Samra Border Crossing (منفذ أبو سمرة البري)", "location_type": "Land Border", "country": "Qatar", "city": "Abu Samra", "notes": "المنفذ البري الحدودي الوحيد لقطر مع السعودية"},
    {"un_locode": "OMSOH", "location_name": "Sohar Port (ميناء صحار الصناعي)", "location_type": "Sea Port", "country": "Oman", "city": "Sohar", "notes": "ميناء سلطنة عمان الرئيسي للتجارة والصناعة خارج مضيق هرمز"},
    {"un_locode": "OMSLH", "location_name": "Salalah Port (ميناء صلالة)", "location_type": "Sea Port", "country": "Oman", "city": "Salalah", "notes": "محطة الترانزيت المحورية الكبرى على المحيط الهندي"},
    {"un_locode": "OMMCT", "location_name": "Muscat International Airport (مطار مسقط الدولي)", "location_type": "Airport", "country": "Oman", "city": "Muscat", "notes": "مطار العاصمة العمانية مسقط"},
    {"un_locode": "BHKBS", "location_name": "Khalifa Bin Salman Port (ميناء خليفة بن سلمان)", "location_type": "Sea Port", "country": "Bahrain", "city": "Hidd", "notes": "الميناء التجاري الرئيسي لمملكة البحرين"},
    {"un_locode": "BHBAH", "location_name": "Bahrain International Airport (مطار البحرين الدولي)", "location_type": "Airport", "country": "Bahrain", "city": "Muharraq", "notes": "مركز الشحن الجوي والخدمات اللوجستية بالبحرين"},

    # North Africa (المغرب والجزائر وتونس وليبيا والسودان)
    {"un_locode": "MATNG", "location_name": "Tanger Med Port (ميناء طنجة المتوسط)", "location_type": "Sea Port", "country": "Morocco", "city": "Tangier", "notes": "أكبر ميناء حاويات في أفريقيا والبحر المتوسط"},
    {"un_locode": "MACAS", "location_name": "Casablanca Port (ميناء الدار البيضاء)", "location_type": "Sea Port", "country": "Morocco", "city": "Casablanca", "notes": "الميناء التاريخي والتجاري الرئيسي للمغرب"},
    {"un_locode": "MACMN", "location_name": "Mohammed V International Airport (مطار محمد الخامس الدولي)", "location_type": "Airport", "country": "Morocco", "city": "Casablanca", "notes": "مطار الدار البيضاء للشحن الجوي"},
    {"un_locode": "DZALG", "location_name": "Algiers Port & Airport (ميناء ومطار الجزائر الدولي)", "location_type": "Sea Port", "country": "Algeria", "city": "Algiers", "notes": "الميناء والمطار التجاري الرئيسي للجمهورية الجزائرية"},
    {"un_locode": "DZORN", "location_name": "Oran Port (ميناء وهران البحري)", "location_type": "Sea Port", "country": "Algeria", "city": "Oran", "notes": "ميناء غرب الجزائر التجاري"},
    {"un_locode": "TNRDS", "location_name": "Rades Port (ميناء رادس البحري)", "location_type": "Sea Port", "country": "Tunisia", "city": "Tunis", "notes": "الميناء الرئيسي لتداول الحاويات والتجارة بتونس"},
    {"un_locode": "TNTUN", "location_name": "Tunis-Carthage Airport (مطار تونس قرطاج الدولي)", "location_type": "Airport", "country": "Tunisia", "city": "Tunis", "notes": "مطار العاصمة التونسية للشحن"},
    {"un_locode": "LYTIP", "location_name": "Tripoli Port (ميناء طرابلس البحري)", "location_type": "Sea Port", "country": "Libya", "city": "Tripoli", "notes": "الميناء التجاري الرئيسي للعاصمة الليبية"},
    {"un_locode": "LYMRA", "location_name": "Misurata Free Zone Port (ميناء المنطقة الحرة بمصراتة)", "location_type": "Sea Port", "country": "Libya", "city": "Misurata", "notes": "أكبر محطة حاويات وتجارة ترانزيت في ليبيا"},
    {"un_locode": "LYBEN", "location_name": "Benghazi Port (ميناء بنغازي البحري)", "location_type": "Sea Port", "country": "Libya", "city": "Benghazi", "notes": "ميناء شرق ليبيا التجاري"},
    {"un_locode": "SDPZU", "location_name": "Port Sudan (ميناء بورتسودان البحري)", "location_type": "Sea Port", "country": "Sudan", "city": "Port Sudan", "notes": "المنفذ البحري الرئيسي لجمهورية السودان على البحر الأحمر"},

    # =========================================================================
    # 5. NORTH & SOUTH AMERICA (أمريكا الشمالية والجنوبية)
    # =========================================================================
    # United States (الولايات المتحدة الأمريكية)
    {"un_locode": "USLAX", "location_name": "Port of Los Angeles (ميناء لوس أنجلوس)", "location_type": "Sea Port", "country": "United States", "city": "Los Angeles", "notes": "أكبر ميناء حاويات في أمريكا الشمالية وبوابة التجارة مع آسيا"},
    {"un_locode": "USLGB", "location_name": "Port of Long Beach (ميناء لونغ بيتش)", "location_type": "Sea Port", "country": "United States", "city": "Long Beach", "notes": "ثاني أكبر موانئ الحاويات بالولايات المتحدة"},
    {"un_locode": "USNYC", "location_name": "Port of New York & New Jersey (ميناء نيويورك ونيوجيرسي)", "location_type": "Sea Port", "country": "United States", "city": "New York", "notes": "أكبر موانئ الساحل الشرقي الأمريكي"},
    {"un_locode": "USSAV", "location_name": "Port of Savannah (ميناء سافانا)", "location_type": "Sea Port", "country": "United States", "city": "Savannah", "notes": "أسرع موانئ الساحل الشرقي نمواً"},
    {"un_locode": "USHOU", "location_name": "Port of Houston (ميناء هيوستن)", "location_type": "Sea Port", "country": "United States", "city": "Houston", "notes": "الميناء الأول في تداول البتروكيماويات والصلب بخليج المكسيك"},
    {"un_locode": "USORF", "location_name": "Port of Virginia / Norfolk (ميناء فرجينيا / نورفولك)", "location_type": "Sea Port", "country": "United States", "city": "Norfolk", "notes": "ميناء متطور ذو مياه عميقة على الأطلسي"},
    {"un_locode": "USCHS", "location_name": "Port of Charleston (ميناء تشارلستون)", "location_type": "Sea Port", "country": "United States", "city": "Charleston", "notes": "ميناء صناعي وتجاري متقدم بكارولاينا الجنوبية"},
    {"un_locode": "USSEA", "location_name": "Port of Seattle & Tacoma (موانئ سياتل وتاكوما / NWSA)", "location_type": "Sea Port", "country": "United States", "city": "Seattle", "notes": "بوابة شمال غرب المحيط الهادئ الأمريكية"},
    {"un_locode": "USMIA", "location_name": "Port of Miami (ميناء ميامي)", "location_type": "Sea Port", "country": "United States", "city": "Miami", "notes": "بوابة التجارة مع أمريكا اللاتينية ومنطقة الكاريبي"},
    {"un_locode": "USORD", "location_name": "Chicago O'Hare International Airport (مطار شيكاغو أوهير الدولي)", "location_type": "Airport", "country": "United States", "city": "Chicago", "notes": "المركز الجوي الرئيسي للشحن بوسط أمريكا"},
    {"un_locode": "USMEM", "location_name": "Memphis International Airport (مطار ممفيس الدولي / FedEx SuperHub)", "location_type": "Airport", "country": "United States", "city": "Memphis", "notes": "أكبر مركز شحن جوي في نصف الكرة الغربي"},
    {"un_locode": "USSDF", "location_name": "Louisville Muhammad Ali Airport (مطار لويفيل / UPS Worldport)", "location_type": "Airport", "country": "United States", "city": "Louisville", "notes": "المركز العالمي اللوجستي لشركة UPS"},
    {"un_locode": "USJFK", "location_name": "John F. Kennedy International Airport (مطار نيويورك جون كينيدي)", "location_type": "Airport", "country": "United States", "city": "New York", "notes": "بوابة الشحن الجوي الدولي لنيويورك"},
    {"un_locode": "USLRD", "location_name": "Port of Laredo (ميناء لاريدو الجاف والبري)", "location_type": "Land Border", "country": "United States", "city": "Laredo", "notes": "أكبر منفذ تجاري بري بين الولايات المتحدة والمكسيك"},

    # Canada & Brazil & Argentina
    {"un_locode": "CAVAN", "location_name": "Port of Vancouver (ميناء فانكوفر)", "location_type": "Sea Port", "country": "Canada", "city": "Vancouver", "notes": "أكبر موانئ كندا وبوابتها على المحيط الهادئ"},
    {"un_locode": "CAMTR", "location_name": "Port of Montreal (ميناء مونتريال)", "location_type": "Sea Port", "country": "Canada", "city": "Montreal", "notes": "ميناء نهر سانت لورانس الرئيسي لخدمة شرق كندا"},
    {"un_locode": "CAYYZ", "location_name": "Toronto Pearson International Airport (مطار تورونتو بيرسون الدولي)", "location_type": "Airport", "country": "Canada", "city": "Toronto", "notes": "أكبر مطار للشحن الجوي في كندا"},
    {"un_locode": "BRSSZ", "location_name": "Port of Santos (ميناء سانتوس)", "location_type": "Sea Port", "country": "Brazil", "city": "Santos", "notes": "أكبر وأهم موانئ أمريكا اللاتينية والبرازيل"},
    {"un_locode": "BRPNG", "location_name": "Port of Paranagua (ميناء باراناغوا)", "location_type": "Sea Port", "country": "Brazil", "city": "Paranagua", "notes": "ميناء تصدير الحبوب واللحوم والسكر البرازيلي"},
    {"un_locode": "BRRIO", "location_name": "Port of Rio de Janeiro (ميناء ريو دي جانيرو)", "location_type": "Sea Port", "country": "Brazil", "city": "Rio de Janeiro", "notes": "ميناء ريو دي جانيرو التجاري"},
    {"un_locode": "BRGRU", "location_name": "Sao Paulo Guarulhos Airport (مطار ساو باولو غواروليوس الدولي)", "location_type": "Airport", "country": "Brazil", "city": "Sao Paulo", "notes": "أكبر مركز شحن جوي في أمريكا الجنوبية"},
    {"un_locode": "ARBUE", "location_name": "Port of Buenos Aires (ميناء بوينس آيرس)", "location_type": "Sea Port", "country": "Argentina", "city": "Buenos Aires", "notes": "الميناء الرئيسي لجمهورية الأرجنتين على ريو دي لا بلاتا"},

    # =========================================================================
    # 6. INDIA & SOUTH/SOUTHEAST ASIA (الهند وجنوب وشرق آسيا)
    # =========================================================================
    # India (الهند)
    {"un_locode": "INNSA", "location_name": "Nhava Sheva / JNPT Port (ميناء نهافا شيفا / مومباي)", "location_type": "Sea Port", "country": "India", "city": "Mumbai", "notes": "أكبر ميناء حاويات في الهند"},
    {"un_locode": "INMUN", "location_name": "Mundra Port (ميناء موندرا / أداني)", "location_type": "Sea Port", "country": "India", "city": "Mundra", "notes": "أكبر ميناء تجاري خاص وأكبر بوابة تجارية لغرب وشمال الهند"},
    {"un_locode": "INMAA", "location_name": "Chennai Port (ميناء تشيناي / مدراس)", "location_type": "Sea Port", "country": "India", "city": "Chennai", "notes": "أكبر موانئ شرق وجنوب الهند"},
    {"un_locode": "INCOK", "location_name": "Cochin / Vallarpadam ICTT (ميناء كوتشين)", "location_type": "Sea Port", "country": "India", "city": "Cochin", "notes": "محطة الحاويات الدولية الترانزيت على بحر العرب"},
    {"un_locode": "INCCU", "location_name": "Kolkata / Haldia Port (ميناء كولكاتا / هالديا)", "location_type": "Sea Port", "country": "India", "city": "Kolkata", "notes": "الميناء النهري والبحري لشرق الهند"},
    {"un_locode": "INDEL", "location_name": "Indira Gandhi International Airport (مطار أنديرا غاندي الدولي بنيودلهي)", "location_type": "Airport", "country": "India", "city": "New Delhi", "notes": "أكبر مركز للشحن الجوي بالهند"},
    {"un_locode": "INBOM", "location_name": "Chhatrapati Shivaji Maharaj Airport (مطار مومباي الدولي)", "location_type": "Airport", "country": "India", "city": "Mumbai", "notes": "مطار العاصمة المالية مومباي للشحن الجوي"},

    # Singapore, Malaysia, South Korea, Japan, Vietnam, Thailand, Indonesia
    {"un_locode": "SGSIN", "location_name": "Port of Singapore & Changi Airport (ميناء سنغافورة ومطار شانغي)", "location_type": "Sea Port", "country": "Singapore", "city": "Singapore", "notes": "أكبر مركز عالمي لإعادة الشحن والترانزيت البحري والجوي"},
    {"un_locode": "MYPKG", "location_name": "Port Klang (ميناء كلانج)", "location_type": "Sea Port", "country": "Malaysia", "city": "Klang", "notes": "الميناء الرئيسي لماليزيا وثاني أكبر موانئ جنوب شرق آسيا"},
    {"un_locode": "MYTPP", "location_name": "Port of Tanjung Pelepas (ميناء تانجونغ بيليباس)", "location_type": "Sea Port", "country": "Malaysia", "city": "Johor", "notes": "محطة ترانزيت حاويات رئيسية بجنوب ماليزيا"},
    {"un_locode": "MYKUL", "location_name": "Kuala Lumpur International Airport (مطار كوالالمبور الدولي)", "location_type": "Airport", "country": "Malaysia", "city": "Kuala Lumpur", "notes": "مطار العاصمة الماليزية للشحن"},
    {"un_locode": "KRPUS", "location_name": "Busan Port (ميناء بوسان)", "location_type": "Sea Port", "country": "South Korea", "city": "Busan", "notes": "أكبر موانئ كوريا الجنوبية وسادس أكبر ميناء حاويات في العالم"},
    {"un_locode": "KRINC", "location_name": "Incheon Port & International Airport (ميناء ومطار إنتشون الدولي)", "location_type": "Airport", "country": "South Korea", "city": "Incheon", "notes": "بوابة العاصمة سيول للشحن البحري والجوي الدولي"},
    {"un_locode": "JPTYO", "location_name": "Port of Tokyo (ميناء طوكيو)", "location_type": "Sea Port", "country": "Japan", "city": "Tokyo", "notes": "ميناء العاصمة اليابانية طوكيو"},
    {"un_locode": "JPYOK", "location_name": "Port of Yokohama (ميناء يوكوهاما)", "location_type": "Sea Port", "country": "Japan", "city": "Yokohama", "notes": "أقدم وأكبر الموانئ التجارية باليابان"},
    {"un_locode": "JPNGO", "location_name": "Port of Nagoya (ميناء ناغويا)", "location_type": "Sea Port", "country": "Japan", "city": "Nagoya", "notes": "الميناء الأول في اليابان لتصدير السيارات وتجارة الترانزيت"},
    {"un_locode": "JPUKB", "location_name": "Port of Kobe (ميناء كوبيه)", "location_type": "Sea Port", "country": "Japan", "city": "Kobe", "notes": "ميناء رئيسي بمنطقة كانساي"},
    {"un_locode": "JPNRT", "location_name": "Tokyo Narita International Airport (مطار طوكيو ناريتا الدولي)", "location_type": "Airport", "country": "Japan", "city": "Tokyo", "notes": "أكبر مطار للشحن الجوي باليابان"},
    {"un_locode": "VNSGN", "location_name": "Ho Chi Minh / Cat Lai Port (ميناء هو تشي منه / كات لاي)", "location_type": "Sea Port", "country": "Vietnam", "city": "Ho Chi Minh", "notes": "أكبر موانئ فيتنام الجنوبية التجارية"},
    {"un_locode": "VNHPH", "location_name": "Hai Phong Port (ميناء هاي فونغ)", "location_type": "Sea Port", "country": "Vietnam", "city": "Hai Phong", "notes": "الميناء الرئيسي لشمال فيتنام وهانوي"},
    {"un_locode": "VNCMT", "location_name": "Cai Mep International Terminal (ميناء كاي ميب الدولي)", "location_type": "Sea Port", "country": "Vietnam", "city": "Vung Tau", "notes": "الميناء ذو المياه العميقة للخطوط الملاحية المباشرة"},
    {"un_locode": "THLCH", "location_name": "Laem Chabang Port (ميناء لايم شابانغ)", "location_type": "Sea Port", "country": "Thailand", "city": "Chonburi", "notes": "أكبر موانئ تايلاند التجارية والصناعية"},
    {"un_locode": "THBKK", "location_name": "Bangkok Port & Suvarnabhumi Airport (ميناء بانكوك ومطار سوفارنابومي الدولي)", "location_type": "Airport", "country": "Thailand", "city": "Bangkok", "notes": "مركز النقل الجوي والبحري للعاصمة التايلاندية"},
    {"un_locode": "IDTPP", "location_name": "Tanjung Priok / Jakarta Port (ميناء تانجونغ بريوك / جاكرتا)", "location_type": "Sea Port", "country": "Indonesia", "city": "Jakarta", "notes": "أكبر وأزحم موانئ إندونيسيا"},
    {"un_locode": "TWKHH", "location_name": "Port of Kaohsiung (ميناء كوهسيونغ)", "location_type": "Sea Port", "country": "Taiwan", "city": "Kaohsiung", "notes": "أكبر موانئ تايوان ومحطة حاويات دولية"},
    {"un_locode": "AUMEL", "location_name": "Port of Melbourne (ميناء ملبورن)", "location_type": "Sea Port", "country": "Australia", "city": "Melbourne", "notes": "أكبر موانئ أستراليا للحاويات والبضائع العامة"},
    {"un_locode": "AUSYD", "location_name": "Port Botany / Sydney (ميناء سيدني / بوتاني ومطار سيدني)", "location_type": "Sea Port", "country": "Australia", "city": "Sydney", "notes": "البوابة البحرية والجوية الكبرى لولاية نيو ساوث ويلز"},
]


def seed_transport_locations():
    db = SessionLocal()
    try:
        print("=" * 70)
        print("Seeding & Updating Comprehensive Global Transport Locations (MD-009)...")
        print("=" * 70)

        created_count = 0
        updated_count = 0

        for item in GLOBAL_LOCATIONS:
            code = item["un_locode"].strip().upper()
            existing = db.query(TransportLocation).filter(TransportLocation.un_locode == code).first()

            if existing:
                existing.location_name = item["location_name"]
                existing.location_type = item["location_type"]
                existing.country = item["country"]
                existing.city = item["city"]
                existing.notes = item.get("notes")
                existing.is_active = True
                updated_count += 1
            else:
                loc = TransportLocation(
                    un_locode=code,
                    location_name=item["location_name"],
                    location_type=item["location_type"],
                    country=item["country"],
                    city=item["city"],
                    notes=item.get("notes"),
                    is_active=True,
                )
                db.add(loc)
                created_count += 1

        db.commit()
        total_now = db.query(TransportLocation).count()

        print(f"✓ Created: {created_count} new transport locations.")
        print(f"✓ Updated: {updated_count} existing locations with full official metadata.")
        print(f"✓ Total Locations in Database now: {total_now}")
        print("=" * 70)

    except Exception as e:
        db.rollback()
        print(f"Error seeding transport locations: {e}")
        raise
    finally:
        db.close()


if __name__ == "__main__":
    seed_transport_locations()
