create table if not exists validated_records (
    reference INTEGER PRIMARY KEY, 
    account_number VARCHAR,
    description VARCHAR,
    start_balance NUMERIC(8, 2),
    mutation NUMERIC(8, 2),
    end_balance NUMERIC(8, 2)
);

create table if not exists invalid_records (
    reference INTEGER, 
    account_number VARCHAR,
    description VARCHAR,
    start_balance NUMERIC(8, 2),
    mutation NUMERIC(8, 2),
    end_balance NUMERIC(8, 2)
);