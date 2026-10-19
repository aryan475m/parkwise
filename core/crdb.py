import os, re, time, psycopg
from psycopg.rows import dict_row
from psycopg import errors

def _sql(s):
    return re.sub(r'(?<![:\w]):(\w+)', r'%(\1)s', s)

def run(sql, params=None, tries=5):
    for i in range(tries):
        try:
            with psycopg.connect(os.environ['CRDB_URL'], row_factory=dict_row) as c:
                cur = c.execute(_sql(sql), params or {})
                rows = cur.fetchall() if cur.description else []
            return rows
        except errors.SerializationFailure:
            time.sleep(0.05 * 2 ** i)
    raise RuntimeError('still failing after retries (SQLSTATE 40001)')

def query(sql, p=None): return run(sql, p)
def execute(sql, p=None): run(sql, p)
def next_id(table, pk): return run('SELECT unique_rowid() AS n')[0]['n']
