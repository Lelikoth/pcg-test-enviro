import math
import traceback
from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd


INPUT_DIR = Path("output/csv")
OUTPUT_DIR = Path("output/charts")
COMBINED_CSV_PATH = OUTPUT_DIR / "combined_results.csv"
SUMMARY_CSV_PATH = OUTPUT_DIR / "summary_stats.csv"
DEBUG_LOG_PATH = OUTPUT_DIR / "debug_log.txt"

MAIN_METRICS = [
    "generation_time_ms",
    "path_length",
    "floor_ratio",
    "largest_component_ratio",
    "tile_entropy",
    "pattern_entropy_2x2",
]

OPTIONAL_METRICS = [
    "room_count",
    "largest_room_area",
    "retry_count",
]

DEBUG_LINES = []


def debug(message):
    line = f"[DEBUG] {message}"
    DEBUG_LINES.append(line)
    print(line)


def flush_debug_log():
    try:
        OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
        DEBUG_LOG_PATH.write_text("\n".join(DEBUG_LINES), encoding="utf-8")
    except Exception as exc:
        print(f"[DEBUG] Failed to write debug log: {exc}")


def main():
    try:
        debug("Script started.")
        debug(f"Current working directory: {Path.cwd().resolve()}")
        debug(f"INPUT_DIR resolved: {INPUT_DIR.resolve()}")
        debug(f"OUTPUT_DIR resolved: {OUTPUT_DIR.resolve()}")

        OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
        debug("Ensured output/charts directory exists.")

        if not INPUT_DIR.exists():
            debug("Input directory does not exist.")
            flush_debug_log()
            raise SystemExit(f"Input directory not found: {INPUT_DIR.resolve()}")

        if not INPUT_DIR.is_dir():
            debug("Input path exists but is not a directory.")
            flush_debug_log()
            raise SystemExit(f"Input path is not a directory: {INPUT_DIR.resolve()}")

        csv_candidates = sorted(INPUT_DIR.glob("*.csv"))
        debug(f"CSV candidates found: {len(csv_candidates)}")
        for path in csv_candidates:
            debug(f" - {path.name}")

        df = load_and_merge_csvs(INPUT_DIR)
        debug(f"Merged dataframe shape: {df.shape}")

        if df.empty:
            debug("Merged dataframe is empty.")
            flush_debug_log()
            raise SystemExit(f"No valid CSV data found in: {INPUT_DIR.resolve()}")

        df = normalize_dataframe(df)
        debug(f"Normalized dataframe shape: {df.shape}")
        debug(f"Normalized dataframe columns: {list(df.columns)}")

        df.to_csv(COMBINED_CSV_PATH, index=False)
        debug(f"Saved combined CSV to: {COMBINED_CSV_PATH.resolve()}")

        summary_df = build_summary(df)
        debug(f"Summary dataframe shape: {summary_df.shape}")
        debug(f"Summary dataframe columns: {list(summary_df.columns)}")

        summary_df.to_csv(SUMMARY_CSV_PATH, index=False)
        debug(f"Saved summary CSV to: {SUMMARY_CSV_PATH.resolve()}")

        create_all_charts(df, summary_df, OUTPUT_DIR)

        debug("All chart generation steps finished.")
        flush_debug_log()

        print("Done.")
        print(f"Combined CSV: {COMBINED_CSV_PATH.resolve()}")
        print(f"Summary CSV:  {SUMMARY_CSV_PATH.resolve()}")
        print(f"Charts dir:   {OUTPUT_DIR.resolve()}")
        print(f"Debug log:    {DEBUG_LOG_PATH.resolve()}")

    except Exception as exc:
        debug(f"Fatal exception: {exc}")
        debug(traceback.format_exc())
        flush_debug_log()
        raise


def load_and_merge_csvs(input_dir):
    debug("Entering load_and_merge_csvs().")
    csv_files = sorted(input_dir.glob("*.csv"))
    debug(f"CSV files found for merge: {len(csv_files)}")

    if not csv_files:
        debug("No CSV files found.")
        return pd.DataFrame()

    frames = []

    for csv_path in csv_files:
        debug(f"Reading CSV: {csv_path.resolve()}")
        try:
            df = pd.read_csv(str(csv_path))
            debug(f"Read success: {csv_path.name}, shape={df.shape}, columns={list(df.columns)}")

            if "algorithm" not in df.columns:
                inferred_algorithm = csv_path.stem.replace("_results", "")
                debug(f"'algorithm' column missing, inferring as: {inferred_algorithm}")
                df["algorithm"] = inferred_algorithm

            frames.append(df)

        except Exception as exc:
            debug(f"Skipping {csv_path.name} due to read error: {exc}")

    if not frames:
        debug("No valid dataframes after reading CSV files.")
        return pd.DataFrame()

    merged = pd.concat(frames, ignore_index=True, sort=False)
    debug(f"Concatenated merged dataframe shape: {merged.shape}")
    return merged


def normalize_dataframe(df):
    debug("Entering normalize_dataframe().")
    df = df.copy()

    if "is_connected" in df.columns:
        debug("Normalizing boolean column: is_connected")
        df["is_connected"] = df["is_connected"].apply(parse_bool)

    numeric_candidates = set(MAIN_METRICS + OPTIONAL_METRICS + [
        "time_per_cell_ms",
        "time_per_floor_cell_ms",
        "floor_count",
        "wall_count",
        "room_module_count",
        "small_room_count",
        "medium_room_count",
        "large_room_count",
        "connected_components_count",
        "largest_component_size",
        "dead_end_count",
        "junction_count",
        "average_degree",
        "path_tortuosity",
        "cycle_count",
        "branching_factor",
        "average_corridor_length",
        "max_corridor_length",
        "seed",
        "run_index",
    ])

    for col in sorted(numeric_candidates):
        if col in df.columns:
            debug(f"Converting column to numeric: {col}")
            df[col] = pd.to_numeric(df[col], errors="coerce")

    if "algorithm" in df.columns:
        debug("Converting 'algorithm' column to string.")
        df["algorithm"] = df["algorithm"].astype(str)

    return df


def parse_bool(value):
    if isinstance(value, bool):
        return value
    if pd.isna(value):
        return False

    text = str(value).strip().lower()
    return text in {"true", "1", "yes", "y"}


def build_summary(df):
    debug("Entering build_summary().")
    summary_rows = []

    algorithms = sorted([str(x) for x in df["algorithm"].dropna().unique().tolist()])
    debug(f"Algorithms found for summary: {algorithms}")

    for algorithm in algorithms:
        subset = df[df["algorithm"] == algorithm]
        debug(f"Building summary for algorithm={algorithm}, rows={len(subset)}")

        row = {
            "algorithm": algorithm,
            "sample_count": len(subset),
        }

        if "is_connected" in subset.columns:
            row["connected_ratio"] = float(subset["is_connected"].mean())

        for metric in MAIN_METRICS + OPTIONAL_METRICS:
            if metric in subset.columns:
                values = subset[metric].dropna()
                debug(f"  Metric={metric}, non-null count={len(values)}")
                if not values.empty:
                    row[f"{metric}_mean"] = float(values.mean())
                    row[f"{metric}_median"] = float(values.median())
                    row[f"{metric}_std"] = float(values.std()) if len(values) > 1 else 0.0
                else:
                    row[f"{metric}_mean"] = math.nan
                    row[f"{metric}_median"] = math.nan
                    row[f"{metric}_std"] = math.nan

        summary_rows.append(row)

    summary_df = pd.DataFrame(summary_rows)
    debug(f"Summary dataframe built with shape: {summary_df.shape}")
    return summary_df


def create_all_charts(df, summary_df, output_dir):
    debug("Entering create_all_charts().")
    algorithms = sorted([str(x) for x in df["algorithm"].dropna().unique().tolist()])
    debug(f"Algorithms for plotting: {algorithms}")

    if column_available(df, "generation_time_ms"):
        debug("Creating chart 01: generation_time_ms boxplot")
        save_boxplot(
            df=df,
            metric="generation_time_ms",
            algorithms=algorithms,
            title="Generation time by algorithm",
            y_axis_label="Generation time [ms]",
            output_path=output_dir / "01_generation_time_boxplot.png",
        )
    else:
        debug("Skipping chart 01: generation_time_ms unavailable")

    if column_available(df, "is_connected"):
        debug("Creating chart 02: connectivity stacked bar")
        save_connectivity_chart(
            df=df,
            algorithms=algorithms,
            output_path=output_dir / "02_connectivity_stacked_bar.png",
        )
    else:
        debug("Skipping chart 02: is_connected unavailable")

    if column_available(df, "path_length") and column_available(df, "is_connected"):
        connected_df = df[df["is_connected"] == True].copy()
        debug(f"Connected-only dataframe for path_length shape: {connected_df.shape}")
        if not connected_df.empty:
            debug("Creating chart 03: path_length boxplot")
            save_boxplot(
                df=connected_df,
                metric="path_length",
                algorithms=algorithms,
                title="Path length by algorithm (connected maps only)",
                y_axis_label="Path length",
                output_path=output_dir / "03_path_length_boxplot.png",
            )
        else:
            debug("Skipping chart 03: no connected rows")
    else:
        debug("Skipping chart 03: path_length or is_connected unavailable")

    if column_available(df, "floor_ratio"):
        debug("Creating chart 04: floor_ratio boxplot")
        save_boxplot(
            df=df,
            metric="floor_ratio",
            algorithms=algorithms,
            title="Floor ratio by algorithm",
            y_axis_label="Floor ratio",
            output_path=output_dir / "04_floor_ratio_boxplot.png",
        )
    else:
        debug("Skipping chart 04: floor_ratio unavailable")

    if column_available(df, "largest_component_ratio"):
        debug("Creating chart 05: largest_component_ratio boxplot")
        save_boxplot(
            df=df,
            metric="largest_component_ratio",
            algorithms=algorithms,
            title="Largest component ratio by algorithm",
            y_axis_label="Largest component ratio",
            output_path=output_dir / "05_largest_component_ratio_boxplot.png",
        )
    else:
        debug("Skipping chart 05: largest_component_ratio unavailable")

    if column_available(df, "tile_entropy"):
        debug("Creating chart 06: tile_entropy boxplot")
        save_boxplot(
            df=df,
            metric="tile_entropy",
            algorithms=algorithms,
            title="Tile entropy by algorithm",
            y_axis_label="Tile entropy",
            output_path=output_dir / "06_tile_entropy_boxplot.png",
        )
    else:
        debug("Skipping chart 06: tile_entropy unavailable")

    if column_available(df, "pattern_entropy_2x2"):
        debug("Creating chart 07: pattern_entropy_2x2 boxplot")
        save_boxplot(
            df=df,
            metric="pattern_entropy_2x2",
            algorithms=algorithms,
            title="2x2 pattern entropy by algorithm",
            y_axis_label="2x2 pattern entropy",
            output_path=output_dir / "07_pattern_entropy_2x2_boxplot.png",
        )
    else:
        debug("Skipping chart 07: pattern_entropy_2x2 unavailable")

    if column_available(df, "room_count"):
        debug("Creating chart 08: room_count boxplot")
        save_boxplot(
            df=df,
            metric="room_count",
            algorithms=algorithms,
            title="Room count by algorithm",
            y_axis_label="Room count",
            output_path=output_dir / "08_room_count_boxplot.png",
        )
    else:
        debug("Skipping chart 08: room_count unavailable")

    if column_available(df, "largest_room_area"):
        debug("Creating chart 09: largest_room_area boxplot")
        save_boxplot(
            df=df,
            metric="largest_room_area",
            algorithms=algorithms,
            title="Largest room area by algorithm",
            y_axis_label="Largest room area",
            output_path=output_dir / "09_largest_room_area_boxplot.png",
        )
    else:
        debug("Skipping chart 09: largest_room_area unavailable")

    if column_available(df, "generation_time_ms") and column_available(df, "tile_entropy"):
        debug("Creating chart 10: scatter generation_time_ms vs tile_entropy")
        save_scatter_by_algorithm(
            df=df,
            x_col="generation_time_ms",
            y_col="tile_entropy",
            title="Generation time vs tile entropy",
            x_axis_label="Generation time [ms]",
            y_axis_label="Tile entropy",
            output_path=output_dir / "10_scatter_time_vs_entropy.png",
        )
    else:
        debug("Skipping chart 10: generation_time_ms or tile_entropy unavailable")

    if column_available(df, "floor_ratio") and column_available(df, "path_length"):
        scatter_df = df.copy()
        if "is_connected" in scatter_df.columns:
            scatter_df = scatter_df[scatter_df["is_connected"] == True]
        debug(f"Scatter dataframe for floor_ratio vs path_length shape: {scatter_df.shape}")
        if not scatter_df.empty:
            debug("Creating chart 11: scatter floor_ratio vs path_length")
            save_scatter_by_algorithm(
                df=scatter_df,
                x_col="floor_ratio",
                y_col="path_length",
                title="Floor ratio vs path length",
                x_axis_label="Floor ratio",
                y_axis_label="Path length",
                output_path=output_dir / "11_scatter_floor_ratio_vs_path_length.png",
            )
        else:
            debug("Skipping chart 11: no connected rows")
    else:
        debug("Skipping chart 11: floor_ratio or path_length unavailable")

    debug("Creating chart 12: summary heatmap")
    save_summary_heatmap(
        summary_df=summary_df,
        output_path=output_dir / "12_summary_heatmap.png",
    )


def column_available(df, column):
    available = column in df.columns and df[column].notna().any()
    debug(f"Column available check: {column} -> {available}")
    return available


def save_boxplot(df, metric, algorithms, title, y_axis_label, output_path):
    debug(f"Entering save_boxplot() for metric={metric}")
    data = []
    labels = []

    for algorithm in algorithms:
        values = df.loc[df["algorithm"] == algorithm, metric].dropna()
        debug(f"  {metric}: algorithm={algorithm}, value_count={len(values)}")
        if values.empty:
            continue
        data.append(values)
        labels.append(algorithm)

    if not data:
        debug(f"No data for boxplot metric={metric}, skipping save.")
        return

    plt.figure(figsize=(10, 6))
    plt.boxplot(data, labels=labels, vert=True)
    plt.title(title)
    plt.ylabel(y_axis_label)
    plt.xticks(rotation=20, ha="right")
    plt.tight_layout()
    plt.savefig(output_path, dpi=200)
    plt.close()
    debug(f"Saved boxplot: {output_path.resolve()}")


def save_connectivity_chart(df, algorithms, output_path):
    debug("Entering save_connectivity_chart()")
    connected_ratios = []
    disconnected_ratios = []
    labels = []

    for algorithm in algorithms:
        subset = df[df["algorithm"] == algorithm]
        debug(f"  connectivity: algorithm={algorithm}, rows={len(subset)}")
        if subset.empty or "is_connected" not in subset.columns:
            continue

        connected = float(subset["is_connected"].mean())
        disconnected = 1.0 - connected

        connected_ratios.append(connected)
        disconnected_ratios.append(disconnected)
        labels.append(algorithm)

    if not labels:
        debug("No labels/data for connectivity chart, skipping save.")
        return

    x = range(len(labels))

    plt.figure(figsize=(10, 6))
    plt.bar(x, connected_ratios, label="Connected")
    plt.bar(x, disconnected_ratios, bottom=connected_ratios, label="Disconnected")
    plt.xticks(list(x), labels, rotation=20, ha="right")
    plt.ylabel("Ratio")
    plt.title("Connectivity ratio by algorithm")
    plt.legend()
    plt.tight_layout()
    plt.savefig(output_path, dpi=200)
    plt.close()
    debug(f"Saved connectivity chart: {output_path.resolve()}")


def save_scatter_by_algorithm(df, x_col, y_col, title, x_axis_label, y_axis_label, output_path):
    debug(f"Entering save_scatter_by_algorithm() for {x_col} vs {y_col}")
    if df.empty:
        debug("Scatter dataframe is empty, skipping save.")
        return

    plt.figure(figsize=(10, 6))
    plotted_any = False

    for algorithm in sorted([str(x) for x in df["algorithm"].dropna().unique().tolist()]):
        subset = df[df["algorithm"] == algorithm]
        subset = subset[[x_col, y_col]].dropna()
        debug(f"  scatter: algorithm={algorithm}, point_count={len(subset)}")
        if subset.empty:
            continue

        plt.scatter(subset[x_col], subset[y_col], label=algorithm, alpha=0.7)
        plotted_any = True

    if not plotted_any:
        debug("No points plotted in scatter, skipping save.")
        plt.close()
        return

    plt.title(title)
    plt.xlabel(x_axis_label)
    plt.ylabel(y_axis_label)
    plt.legend()
    plt.tight_layout()
    plt.savefig(output_path, dpi=200)
    plt.close()
    debug(f"Saved scatter chart: {output_path.resolve()}")


def save_summary_heatmap(summary_df, output_path):
    debug("Entering save_summary_heatmap()")
    if summary_df.empty:
        debug("Summary dataframe empty, skipping heatmap.")
        return

    heatmap_cols = [
        "generation_time_ms_mean",
        "connected_ratio",
        "path_length_mean",
        "floor_ratio_mean",
        "largest_component_ratio_mean",
        "tile_entropy_mean",
        "pattern_entropy_2x2_mean",
    ]

    available_cols = [col for col in heatmap_cols if col in summary_df.columns]
    debug(f"Heatmap available columns: {available_cols}")

    if not available_cols:
        debug("No available heatmap columns, skipping save.")
        return

    heatmap_df = summary_df[["algorithm"] + available_cols].copy()
    heatmap_df = heatmap_df.set_index("algorithm")

    normalized = heatmap_df.copy()
    for col in normalized.columns:
        col_min = normalized[col].min()
        col_max = normalized[col].max()
        debug(f"  heatmap normalize: col={col}, min={col_min}, max={col_max}")

        if pd.isna(col_min) or pd.isna(col_max) or col_max == col_min:
            normalized[col] = 0.5
        else:
            normalized[col] = (normalized[col] - col_min) / (col_max - col_min)

    plt.figure(figsize=(10, 6))
    plt.imshow(normalized.values, aspect="auto")
    plt.xticks(range(len(normalized.columns)), normalized.columns, rotation=30, ha="right")
    plt.yticks(range(len(normalized.index)), normalized.index)
    plt.title("Normalized summary metrics by algorithm")
    plt.colorbar(label="Normalized value")
    plt.tight_layout()
    plt.savefig(output_path, dpi=200)
    plt.close()
    debug(f"Saved summary heatmap: {output_path.resolve()}")


if __name__ == "__main__":
    main()