import re
import pandas as pd
from pathlib import Path
import unicodedata
from difflib import SequenceMatcher

sharecity_path = Path("sharecity200-export-1768225380870.csv")

def read_csv_robust(path: Path) -> pd.DataFrame:
    for enc in ("utf-8", "utf-8-sig", "cp1252", "latin1"):
        try:
            return pd.read_csv(path, encoding=enc)
        except UnicodeDecodeError:
            continue
    return pd.read_csv(path, encoding="latin1")

df_share = read_csv_robust(sharecity_path)

def normalise_columns(df: pd.DataFrame) -> pd.DataFrame:
    df = df.copy()
    df.columns = [c.strip().lower() for c in df.columns]
    rename_map = {
        "country": "country",
        "city": "city",
        "name": "name",
        "organisation": "name",
        "organization": "name",
        "title": "name",
        "url": "url",
        "website": "url",
        "link": "url",
    }
    df = df.rename(columns={c: rename_map.get(c, c) for c in df.columns})
    return df

df_share = normalise_columns(df_share)

# --- required columns for key-based duplication ---
required = ["country", "city", "name"]
for r in required:
    if r not in df_share.columns:
        raise KeyError(
            f"ShareCity file is missing column: {r}. "
            f"Columns: {list(df_share.columns)}"
        )

def clean_text(x) -> str:
    if pd.isna(x):
        return ""
    x = str(x).strip()
    x = unicodedata.normalize("NFKC", x)     
    x = x.casefold()                         
    x = re.sub(r"\s+", " ", x)               
    x = re.sub(r"[’'`´]", "'", x)            
    x = re.sub(r"[^\w\s']", " ", x)          
    x = re.sub(r"\s+", " ", x).strip()
    return x

for col in ["country", "city", "name"]:
    df_share[f"{col}__key"] = df_share[col].map(clean_text)

df_share["match_key"] = (
    df_share["country__key"] + " | " +
    df_share["city__key"] + " | " +
    df_share["name__key"]
).str.strip()

dup_share = (
    df_share[df_share.duplicated("match_key", keep=False)]
    .sort_values(["match_key"])
    .copy()
)

print("Rows:")
print("  ShareCity:", len(df_share))
print("  Unique keys (country+city+name):", df_share["match_key"].nunique())
print("  Duplicate rows (within ShareCity):", len(dup_share))
print("  Duplicate groups:", dup_share["match_key"].nunique())
print()

dup_cols = [c for c in df_share.columns if not c.endswith("__key")]
dup_share[dup_cols + ["match_key"]].to_csv(
    "duplicates_sharecity_by_key.csv",
    index=False,
    encoding="utf-8-sig"
)
print("Saved:")
print("  duplicates_sharecity_by_key.csv")

def normalise_url(u) -> str:
    if pd.isna(u):
        return ""
    u = str(u).strip()
    u = unicodedata.normalize("NFKC", u)
    u = u.casefold()
    u = re.sub(r"#.*$", "", u)               
    u = re.sub(r"\?.*$", "", u)              
    u = re.sub(r"^https?://", "", u)         
    u = re.sub(r"^www\.", "", u)             
    u = u.rstrip("/")
    return u

if "url" in df_share.columns:
    df_share["url__key"] = df_share["url"].map(normalise_url)

    df_share["city_country_url_key"] = (
        df_share["country__key"] + " | " +
        df_share["city__key"] + " | " +
        df_share["url__key"]
    ).str.strip()

    dup_url = (
        df_share[
            df_share["url__key"].ne("") &
            df_share.duplicated("city_country_url_key", keep=False)
        ]
        .sort_values(["city_country_url_key", "match_key"])
        .copy()
    )

    if len(dup_url) > 0:
        dup_url_cols = [c for c in df_share.columns if not c.endswith("__key")]
        dup_url[dup_url_cols + ["city_country_url_key", "url__key", "match_key"]].to_csv(
            "duplicates_sharecity_by_city_country_url.csv",
            index=False,
            encoding="utf-8-sig"
        )
        print("Also saved URL duplicates (same country+city only):")
        print("  duplicates_sharecity_by_city_country_url.csv")
    else:
        print("No URL duplicates found within the same country+city (or url column empty).")
else:
    print("No 'url' column found, skipped URL duplicates check.")

def similarity(a: str, b: str) -> float:
    return SequenceMatcher(None, a, b).ratio()

FUZZY_THRESHOLD = 0.92
MAX_GROUP_SIZE = 400        
MAX_RESULTS_PER_GROUP = 200 

near_dups = []

for (cty, city), g in df_share.groupby(["country__key", "city__key"], dropna=False):
    g = g.copy()
    if len(g) < 2:
        continue
    if len(g) > MAX_GROUP_SIZE:
        continue

    names = g["name__key"].tolist()
    idxs = g.index.tolist()

    found = 0
    for i in range(len(names)):
        for j in range(i + 1, len(names)):
            if names[i] == names[j]:
                continue 
            s = similarity(names[i], names[j])
            if s >= FUZZY_THRESHOLD:
                near_dups.append({
                    "country__key": cty,
                    "city__key": city,
                    "row_i": idxs[i],
                    "row_j": idxs[j],
                    "name_i": df_share.loc[idxs[i], "name"],
                    "name_j": df_share.loc[idxs[j], "name"],
                    "similarity": s,
                    "match_key_i": df_share.loc[idxs[i], "match_key"],
                    "match_key_j": df_share.loc[idxs[j], "match_key"],
                })
                found += 1
                if found >= MAX_RESULTS_PER_GROUP:
                    break
        if found >= MAX_RESULTS_PER_GROUP:
            break

df_near = pd.DataFrame(near_dups).sort_values("similarity", ascending=False)
if len(df_near) > 0:
    df_near.to_csv("near_duplicates_sharecity_fuzzy.csv", index=False, encoding="utf-8-sig")
    print("\nSaved fuzzy near-duplicates (if any):")
    print("  near_duplicates_sharecity_fuzzy.csv")
else:
    print("\nNo fuzzy near-duplicates found at the current threshold.")
