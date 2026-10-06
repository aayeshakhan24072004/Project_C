import argparse
from pathlib import Path

from google.cloud import bigquery


PROJECT_ROOT = Path(__file__).resolve().parents[1]
SOURCE_TABLES = {
    "branches": "branches.csv",
    "customers": "customers.csv",
    "accounts": "accounts.csv",
    "transactions": "transactions.csv",
    "cards": "cards.csv",
    "loans": "loans.csv",
    "loan_payments": "loan_payments.csv",
}


def parse_args():
    parser = argparse.ArgumentParser(description="Load unchanged BankSphere CSV files into BigQuery raw tables.")
    parser.add_argument("--project", required=True, help="Google Cloud project ID.")
    parser.add_argument("--dataset", default="banksphere_raw", help="Raw BigQuery dataset.")
    parser.add_argument("--location", default="US", help="BigQuery dataset location.")
    parser.add_argument(
        "--replace",
        action="store_true",
        help="Replace existing tables. Without this flag, existing non-empty tables are protected.",
    )
    return parser.parse_args()


def main():
    args = parse_args()
    client = bigquery.Client(project=args.project)
    dataset = bigquery.Dataset(f"{args.project}.{args.dataset}")
    dataset.location = args.location
    client.create_dataset(dataset, exists_ok=True)

    write_disposition = (
        bigquery.WriteDisposition.WRITE_TRUNCATE
        if args.replace
        else bigquery.WriteDisposition.WRITE_EMPTY
    )
    for table_name, filename in SOURCE_TABLES.items():
        path = PROJECT_ROOT / filename
        if not path.is_file():
            raise FileNotFoundError(f"Missing source CSV: {path}")

        job_config = bigquery.LoadJobConfig(
            source_format=bigquery.SourceFormat.CSV,
            skip_leading_rows=1,
            autodetect=True,
            create_disposition=bigquery.CreateDisposition.CREATE_IF_NEEDED,
            write_disposition=write_disposition,
        )
        with path.open("rb") as source_file:
            job = client.load_table_from_file(
                source_file,
                f"{args.project}.{args.dataset}.{table_name}",
                job_config=job_config,
                location=args.location,
            )
        job.result()
        print(f"Loaded {job.output_rows:,} rows into {args.dataset}.{table_name}")


if __name__ == "__main__":
    main()