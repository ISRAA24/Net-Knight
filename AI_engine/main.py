import argparse
import uvicorn


def main() -> None:
    parser = argparse.ArgumentParser(description="Net-Knight AI_engine")
    parser.add_argument("--host", default="0.0.0.0")
    parser.add_argument("--port", type=int, default=5000)
    parser.add_argument("--reload", action="store_true", help=".")
    args = parser.parse_args()

    uvicorn.run("api.api_for_anomaly_IDS:app", host=args.host, port=args.port, reload=args.reload)


if __name__ == "__main__":
    main()
