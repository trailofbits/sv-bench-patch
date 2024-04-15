import argparse
import pandas as pd
import sys

def create_df(filename, header):
    df = pd.read_csv(filename, sep = ' ', index_col = 0, names = [header])
    return df

def merge_df(frames):
    df = pd.concat(frames, axis = 1)
    totals = df.loc[['Total']]
    df = df.drop(['Total'], axis = 0)
    return pd.concat([totals, df])

def main():
    parser = argparse.ArgumentParser(prog="make_table.py")
    parser.add_argument("--files")
    parser.add_argument("--columns")
    parser.add_argument("--output")
    config = parser.parse_args()
    columns = [column for column in config.columns.split(',')]
    files = [file for file in config.files.split(',')]
    results = [create_df(*pair) for pair in zip(files, columns)]
    merged = merge_df(results)
    with open(config.output + ".md", "w") as res:
        res.write(merged.to_markdown())

main()

