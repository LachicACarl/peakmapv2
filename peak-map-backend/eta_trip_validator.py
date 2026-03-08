"""
Live ETA validator for PEAK MAP station-based ETA.

This script samples `/eta` over time for a driver and destination station,
then compares predicted ETA against actual arrival time when the bus reaches
the destination geofence.
"""

from __future__ import annotations

import argparse
import csv
import json
import math
import time
from dataclasses import dataclass, asdict
from datetime import datetime
from pathlib import Path
from typing import Any

import requests


@dataclass
class EtaSample:
    timestamp_iso: str
    elapsed_seconds: float
    eta_minutes: float | None
    eta_text: str
    stops_remaining: int | None
    current_station: str
    destination_station: str
    bus_latitude: float | None
    bus_longitude: float | None
    distance_to_station_m: float | None


def haversine_m(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """Calculate distance between two lat/lng points in meters."""
    radius_m = 6_371_000

    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    d_phi = math.radians(lat2 - lat1)
    d_lambda = math.radians(lon2 - lon1)

    a = (
        math.sin(d_phi / 2.0) ** 2
        + math.cos(phi1) * math.cos(phi2) * math.sin(d_lambda / 2.0) ** 2
    )
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return radius_m * c


def get_station(base_url: str, station_id: int, timeout: int) -> dict[str, Any]:
    response = requests.get(f"{base_url}/stations/", timeout=timeout)
    response.raise_for_status()
    stations = response.json()

    for station in stations:
        if int(station.get("id", -1)) == station_id:
            return station

    raise ValueError(f"Station {station_id} not found in /stations response")


def get_eta(base_url: str, driver_id: int, station_id: int, timeout: int) -> dict[str, Any]:
    response = requests.get(
        f"{base_url}/eta/",
        params={"driver_id": driver_id, "station_id": station_id},
        timeout=timeout,
    )
    response.raise_for_status()
    return response.json()


def to_float(value: Any) -> float | None:
    if value is None:
        return None
    try:
        return float(value)
    except (TypeError, ValueError):
        return None


def write_csv(path: Path, rows: list[EtaSample]) -> None:
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(asdict(rows[0]).keys()))
        writer.writeheader()
        for row in rows:
            writer.writerow(asdict(row))


def build_report(
    rows: list[EtaSample],
    station: dict[str, Any],
    arrived: bool,
    actual_arrival_elapsed_sec: float | None,
    started_at_iso: str,
    ended_at_iso: str,
    driver_id: int,
    station_id: int,
    base_url: str,
) -> dict[str, Any]:
    first_eta_minutes = next((r.eta_minutes for r in rows if r.eta_minutes is not None), None)

    report: dict[str, Any] = {
        "meta": {
            "driver_id": driver_id,
            "station_id": station_id,
            "station_name": station.get("name", "Unknown"),
            "base_url": base_url,
            "started_at": started_at_iso,
            "ended_at": ended_at_iso,
            "sample_count": len(rows),
        },
        "result": {
            "arrived": arrived,
            "first_eta_minutes": first_eta_minutes,
            "actual_arrival_seconds": actual_arrival_elapsed_sec,
        },
        "samples": [asdict(r) for r in rows],
    }

    if (
        arrived
        and actual_arrival_elapsed_sec is not None
        and first_eta_minutes is not None
        and first_eta_minutes >= 0
    ):
        predicted_seconds = first_eta_minutes * 60.0
        initial_error_seconds = predicted_seconds - actual_arrival_elapsed_sec

        # MAE across all samples against actual remaining time at each sample timestamp.
        abs_errors: list[float] = []
        for sample in rows:
            if sample.eta_minutes is None:
                continue
            actual_remaining = max(actual_arrival_elapsed_sec - sample.elapsed_seconds, 0.0)
            predicted_remaining = max(sample.eta_minutes * 60.0, 0.0)
            abs_errors.append(abs(predicted_remaining - actual_remaining))

        mae_seconds = sum(abs_errors) / len(abs_errors) if abs_errors else None

        report["result"].update(
            {
                "initial_prediction_seconds": round(predicted_seconds, 2),
                "initial_prediction_error_seconds": round(initial_error_seconds, 2),
                "mae_seconds": round(mae_seconds, 2) if mae_seconds is not None else None,
            }
        )

    return report


def run(args: argparse.Namespace) -> int:
    station = get_station(args.base_url, args.station_id, args.timeout)
    station_lat = float(station["latitude"])
    station_lng = float(station["longitude"])
    station_radius_m = float(station.get("radius", 200))

    arrival_radius_m = args.arrival_radius_m if args.arrival_radius_m > 0 else station_radius_m

    started_wall = datetime.now()
    started_monotonic = time.monotonic()

    rows: list[EtaSample] = []
    arrived = False
    actual_arrival_elapsed_sec: float | None = None

    max_seconds = args.max_minutes * 60.0

    print(
        f"[eta-validator] Monitoring driver={args.driver_id} to station={args.station_id} "
        f"({station.get('name')}) for up to {args.max_minutes:.1f} min"
    )

    while True:
        now_monotonic = time.monotonic()
        elapsed = now_monotonic - started_monotonic
        if elapsed > max_seconds:
            break

        payload = get_eta(args.base_url, args.driver_id, args.station_id, args.timeout)

        eta_minutes = to_float(payload.get("eta_minutes"))
        eta_text = str(payload.get("eta_text", ""))
        stops_remaining = payload.get("stops_remaining")
        if stops_remaining is not None:
            try:
                stops_remaining = int(stops_remaining)
            except (TypeError, ValueError):
                stops_remaining = None

        current_station = str(payload.get("current_station", ""))
        destination_station = str(payload.get("destination_station", ""))

        loc = payload.get("driver_location") or {}
        bus_lat = to_float(loc.get("latitude"))
        bus_lng = to_float(loc.get("longitude"))

        distance_to_station_m: float | None = None
        if bus_lat is not None and bus_lng is not None:
            distance_to_station_m = haversine_m(bus_lat, bus_lng, station_lat, station_lng)

        sample = EtaSample(
            timestamp_iso=datetime.now().isoformat(timespec="seconds"),
            elapsed_seconds=round(elapsed, 2),
            eta_minutes=round(eta_minutes, 2) if eta_minutes is not None else None,
            eta_text=eta_text,
            stops_remaining=stops_remaining,
            current_station=current_station,
            destination_station=destination_station,
            bus_latitude=bus_lat,
            bus_longitude=bus_lng,
            distance_to_station_m=round(distance_to_station_m, 2)
            if distance_to_station_m is not None
            else None,
        )
        rows.append(sample)

        eta_arrived = (eta_text.strip().lower() == "arrived") or (
            eta_minutes is not None and eta_minutes <= args.arrival_eta_minutes
        )
        geofence_arrived = (
            distance_to_station_m is not None and distance_to_station_m <= arrival_radius_m
        )

        print(
            f"[sample {len(rows):03d}] t={sample.elapsed_seconds:6.1f}s | "
            f"eta={sample.eta_text or 'n/a':>10} | "
            f"dist={sample.distance_to_station_m if sample.distance_to_station_m is not None else 'n/a':>8}m | "
            f"stops={sample.stops_remaining if sample.stops_remaining is not None else 'n/a'}"
        )

        if eta_arrived or geofence_arrived:
            arrived = True
            actual_arrival_elapsed_sec = elapsed
            break

        time.sleep(args.interval_seconds)

    ended_wall = datetime.now()

    if not rows:
        raise RuntimeError("No samples were collected. Check backend connectivity.")

    out_dir = Path(args.output_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    stamp = started_wall.strftime("%Y%m%d_%H%M%S")
    base_name = f"eta_validation_driver{args.driver_id}_station{args.station_id}_{stamp}"

    csv_path = out_dir / f"{base_name}.csv"
    json_path = out_dir / f"{base_name}.json"

    write_csv(csv_path, rows)

    report = build_report(
        rows=rows,
        station=station,
        arrived=arrived,
        actual_arrival_elapsed_sec=round(actual_arrival_elapsed_sec, 2)
        if actual_arrival_elapsed_sec is not None
        else None,
        started_at_iso=started_wall.isoformat(timespec="seconds"),
        ended_at_iso=ended_wall.isoformat(timespec="seconds"),
        driver_id=args.driver_id,
        station_id=args.station_id,
        base_url=args.base_url,
    )

    with json_path.open("w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)

    print("\n[eta-validator] Report complete")
    print(f"  CSV : {csv_path}")
    print(f"  JSON: {json_path}")

    result = report["result"]
    print(f"  Arrived: {result.get('arrived')}")
    print(f"  First ETA (min): {result.get('first_eta_minutes')}")
    print(f"  Actual arrival (sec): {result.get('actual_arrival_seconds')}")

    if "initial_prediction_error_seconds" in result:
        print(f"  Initial ETA error (sec): {result.get('initial_prediction_error_seconds')}")
        print(f"  MAE (sec): {result.get('mae_seconds')}")

    return 0


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Validate live ETA against actual arrival time for a driver/station pair."
    )
    parser.add_argument("--driver-id", type=int, required=True)
    parser.add_argument("--station-id", type=int, required=True)
    parser.add_argument("--base-url", default="http://127.0.0.1:8000")
    parser.add_argument("--max-minutes", type=float, default=45.0)
    parser.add_argument("--interval-seconds", type=float, default=5.0)
    parser.add_argument("--arrival-radius-m", type=float, default=0.0)
    parser.add_argument("--arrival-eta-minutes", type=float, default=0.2)
    parser.add_argument("--timeout", type=int, default=10)
    parser.add_argument(
        "--output-dir",
        default="eta_validation_reports",
        help="Directory where CSV and JSON report files are written.",
    )
    return parser.parse_args()


if __name__ == "__main__":
    raise SystemExit(run(parse_args()))
