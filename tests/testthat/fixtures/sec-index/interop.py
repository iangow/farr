"""Generate synthetic Python fixtures, or check an R-generated file.

Run with pyarrow installed. No downloads or research data are used.
  python interop.py                  # regenerate fixtures beside this script
  python interop.py R_FILE [GZIP]    # verify R -> Python; optionally era_pl parser
"""
from datetime import date, datetime
from pathlib import Path
import sys

import pyarrow as pa
import pyarrow.parquet as pq

VINTAGE = datetime.fromisoformat("2022-04-02T22:15:30-04:00")
EXPECTED = {
    "company_name": ["CAFÉ INC"],
    "form_type": ["SC 13G/A"],
    "cik": [1234567],
    "date_filed": [date(2022, 4, 1)],
    "file_name": ["edgar/data/1234567/filing.txt"],
}

if len(sys.argv) == 1:
    for text_type in (pa.string(), pa.large_string()):
        schema = pa.schema([
            ("company_name", text_type), ("form_type", text_type),
            ("cik", pa.int32()), ("date_filed", pa.date32()),
            ("file_name", text_type),
        ], metadata={b"last_modified": VINTAGE.isoformat().encode("utf-8"),
                     b"fixture_note": "Synthetic café fixture".encode("utf-8")})
        pq.write_table(pa.table(EXPECTED, schema=schema),
                       Path(__file__).with_name(f"python-{text_type}.parquet"))
else:
    path = Path(sys.argv[1])
    table = pq.read_table(path)
    assert table.to_pydict() == EXPECTED
    raw = table.schema.metadata[b"last_modified"].decode("utf-8")
    assert datetime.fromisoformat(raw.replace("Z", "+00:00")) == VINTAGE
    assert table.schema.field("cik").type == pa.int32()
    assert table.schema.field("date_filed").type == pa.date32()
    print("R -> PyArrow: values, types, and vintage passed")
    if len(sys.argv) > 2:
        from era_pl.sec import sec_parquet_last_modified, sec_parse_company_bytes
        assert sec_parquet_last_modified(str(path)) == VINTAGE
        parsed = sec_parse_company_bytes(Path(sys.argv[2]).read_bytes())
        assert parsed.to_dict(as_series=False) == EXPECTED
        print("R -> era_pl.sec: vintage and fixed-width parser parity passed")
