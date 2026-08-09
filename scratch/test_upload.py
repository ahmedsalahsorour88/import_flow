import urllib.request

content = """hs_code,hs_description,customs_category,customs_duty_rate,vat_rate
9999.99.99,Test Upload Item,Testing,10.0,14.0
"""

boundary = "----WebKitFormBoundary7MA4YWxkTrZu0gW"
body = (
    f"--{boundary}\r\n"
    f'Content-Disposition: form-data; name="file"; filename="test.csv"\r\n'
    f"Content-Type: text/csv\r\n\r\n"
    f"{content}\r\n"
    f"--{boundary}--\r\n"
).encode("utf-8")

req = urllib.request.Request(
    "http://127.0.0.1:8000/api/v1/customs-tariff/upload-excel",
    data=body,
    headers={"Content-Type": f"multipart/form-data; boundary={boundary}"},
)

res = urllib.request.urlopen(req)
print("UPLOAD RESPONSE:", res.read().decode("utf-8"))
