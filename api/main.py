import duckdb
from tabulate import tabulate

from fastapi import FastAPI
from fastapi.responses import PlainTextResponse

app = FastAPI()
app.title="Rabobank"                                                         
con = duckdb.connect("./database/records.db", read_only = True)

@app.get("/records/invalid", response_class=PlainTextResponse)
def get_invalid_records():
    result = con.sql("select (reference, description, start_balance, mutation, end_balance) from invalid_records limit 10")
    rows = [row[0] for row in result.fetchall()]
    columns = ["reference", "description", "start_balance", "mutation", "end_balance"]
    table = tabulate(rows, headers=columns, tablefmt="simple")  
    return table
