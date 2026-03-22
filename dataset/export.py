import zipfile
import io
import pandas as pd
from pymongo import MongoClient

# ── Parse the .arff inside the ZIP ─────────────────────────────────────────
with zipfile.ZipFile("phishing.csv", "r") as zf:
    # find the .arff entry (there may be a .old.arff and a real one)
    arff_names = [n for n in zf.namelist() if n.endswith(".arff") and "old" not in n]
    if not arff_names:                       # fallback: take any .arff
        arff_names = [n for n in zf.namelist() if n.endswith(".arff")]
    print("Files in ZIP:", zf.namelist())
    print("Using:", arff_names[0])
    raw = zf.read(arff_names[0]).decode("latin1")

columns = []
data_lines = []
in_data = False

for line in raw.splitlines():
    line = line.strip()
    if not line or line.startswith("%"):
        continue
    if line.lower().startswith("@attribute"):
        # @attribute <name> <type>
        col_name = line.split()[1]
        columns.append(col_name)
    elif line.lower() == "@data":
        in_data = True
    elif in_data:
        data_lines.append(line)

print(f"Columns ({len(columns)}): {columns}")
print(f"Rows: {len(data_lines)}")

# ── Build DataFrame ─────────────────────────────────────────────────────────
rows = [list(map(int, l.split(","))) for l in data_lines if l]
df = pd.DataFrame(rows, columns=columns)
print(df.head())

# ── Push to MongoDB ─────────────────────────────────────────────────────────
client = MongoClient("mongodb+srv://prathamsk333:@cluster0.cqhssts.mongodb.net/")
db = client["networksecurity_db"]
collection = db["network_data"]

# Optional: clear old docs before inserting
collection.delete_many({})

records = df.to_dict("records")
result = collection.insert_many(records)
print(f"✅ Inserted {len(result.inserted_ids)} records into networksecurity_db.network_data")