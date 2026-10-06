import csv
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[1]
EXPECTED_STATUS = {
    "account_status": {"ACTIVE", "BLOCKED", "CLOSED", "DORMANT"},
    "card_status": {"ACTIVE", "BLOCKED", "CLOSED", "EXPIRED"},
    "transaction_status": {"SUCCESS", "FAILED", "PENDING", "REVERSED"},
    "loan_status": {"ACTIVE", "CLOSED", "DEFAULTED", "PENDING"},
    "payment_status": {"SUCCESS", "FAILED", "LATE"},
}


def read_csv(filename):
    with (PROJECT_ROOT / filename).open(newline="", encoding="utf-8") as source_file:
        return list(csv.DictReader(source_file))


def assert_unique(rows, key, filename, failures):
    values = [row[key] for row in rows]
    if not all(values):
        failures.append(f"{filename}.{key} contains a null or blank key")
    if len(values) != len(set(values)):
        failures.append(f"{filename}.{key} contains duplicate keys")


def main():
    failures = []
    branches = read_csv("branches.csv")
    customers = read_csv("customers.csv")
    accounts = read_csv("accounts.csv")
    transactions = read_csv("transactions.csv")
    cards = read_csv("cards.csv")
    loans = read_csv("loans.csv")
    payments = read_csv("loan_payments.csv")

    for rows, key, filename in (
        (branches, "branch_id", "branches.csv"),
        (customers, "customer_id", "customers.csv"),
        (accounts, "account_id", "accounts.csv"),
        (transactions, "transaction_id", "transactions.csv"),
        (cards, "card_id", "cards.csv"),
        (loans, "loan_id", "loans.csv"),
        (payments, "payment_id", "loan_payments.csv"),
    ):
        assert_unique(rows, key, filename, failures)

    customer_ids = {row["customer_id"] for row in customers}
    branch_ids = {row["branch_id"] for row in branches}
    account_customer = {row["account_id"]: row["customer_id"] for row in accounts}
    loan_ids = {row["loan_id"] for row in loans}

    for row in accounts:
        if row["customer_id"] not in customer_ids or row["branch_id"] not in branch_ids:
            failures.append(f"Account {row['account_id']} has an unknown customer or branch")
        if row["account_status"] not in EXPECTED_STATUS["account_status"]:
            failures.append(f"Account {row['account_id']} has an invalid status")
    for row in transactions:
        if row["account_id"] not in account_customer:
            failures.append(f"Transaction {row['transaction_id']} has an unknown account")
        elif row["customer_id"] != account_customer[row["account_id"]]:
            failures.append(f"Transaction {row['transaction_id']} customer differs from its account")
        if row["transaction_status"] not in EXPECTED_STATUS["transaction_status"]:
            failures.append(f"Transaction {row['transaction_id']} has an invalid status")
        if row["transaction_status"] == "SUCCESS" and float(row["amount"]) < 0:
            failures.append(f"Transaction {row['transaction_id']} has a negative successful amount")
    for row in cards:
        if row["account_id"] not in account_customer or row["customer_id"] not in customer_ids:
            failures.append(f"Card {row['card_id']} has an unknown account or customer")
        elif row["customer_id"] != account_customer[row["account_id"]]:
            failures.append(f"Card {row['card_id']} customer differs from its account")
        if row["card_status"] not in EXPECTED_STATUS["card_status"]:
            failures.append(f"Card {row['card_id']} has an invalid status")
    for row in loans:
        if row["customer_id"] not in customer_ids or row["account_id"] not in account_customer:
            failures.append(f"Loan {row['loan_id']} has an unknown customer or account")
        if row["loan_status"] not in EXPECTED_STATUS["loan_status"]:
            failures.append(f"Loan {row['loan_id']} has an invalid status")
        if float(row["outstanding_amount"]) > float(row["sanctioned_amount"]):
            failures.append(f"Loan {row['loan_id']} outstanding amount exceeds sanctioned amount")
    for row in payments:
        if row["loan_id"] not in loan_ids:
            failures.append(f"Payment {row['payment_id']} has an unknown loan")
        if row["payment_status"] not in EXPECTED_STATUS["payment_status"]:
            failures.append(f"Payment {row['payment_id']} has an invalid status")

    for filename, rows in (
        ("branches.csv", branches),
        ("customers.csv", customers),
        ("accounts.csv", accounts),
        ("transactions.csv", transactions),
        ("cards.csv", cards),
        ("loans.csv", loans),
        ("loan_payments.csv", payments),
    ):
        print(f"{filename}: {len(rows):,} rows")

    if failures:
        print(f"FAILED: {len(failures)} source quality issue(s)")
        for failure in failures[:50]:
            print(f"- {failure}")
        raise SystemExit(1)
    print("PASSED: primary keys, references, status domains, and required amount rules")


if __name__ == "__main__":
    main()