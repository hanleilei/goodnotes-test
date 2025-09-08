#!/usr/bin/env python3
import argparse
import asyncio
import aiohttp
import random
import time
import statistics

async def do_request(session, host, url):
    start = time.perf_counter()
    try:
        async with session.get(url, headers={"Host": host}) as resp:
            body = await resp.text()
            elapsed = (time.perf_counter() - start) * 1000.0

            # check body contains expected hostname (foo/bar)
            expected = host.split(".")[0]  # foo.localhost -> foo
            ok = resp.status == 200 and expected in body.strip()
            return ok, elapsed, resp.status, body.strip()
    except Exception as e:
        elapsed = (time.perf_counter() - start) * 1000.0
        return False, elapsed, None, str(e)


async def run_loadtest(hosts, total_requests, concurrency):
    results = []
    connector = aiohttp.TCPConnector(limit=concurrency * 2)
    timeout = aiohttp.ClientTimeout(total=10)
    async with aiohttp.ClientSession(connector=connector, timeout=timeout) as session:
        sem = asyncio.Semaphore(concurrency)

        async def bound_req(host):
            async with sem:
                return await do_request(session, host, "http://localhost/")

        tasks = [asyncio.create_task(bound_req(random.choice(hosts)))
                 for _ in range(total_requests)]

        for fut in asyncio.as_completed(tasks):
            results.append(await fut)
    return results

def percentile(data, p):
    if not data:
        return None
    k = (len(data) - 1) * (p / 100)
    f = int(k)
    c = min(f + 1, len(data) - 1)
    if f == c:
        return data[int(k)]
    return data[f] + (data[c] - data[f]) * (k - f)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--hosts", nargs="+", default=["foo.localhost", "bar.localhost"])
    parser.add_argument("--requests", type=int, default=100)
    parser.add_argument("--concurrency", type=int, default=10)
    args = parser.parse_args()

    start_wall = time.time()
    results = asyncio.run(run_loadtest(args.hosts, args.requests, args.concurrency))
    wall = time.time() - start_wall

    latencies = [r[1] for r in results if r[0]]
    lat_sorted = sorted(latencies)
    failed = [r for r in results if not r[0]]

    avg = statistics.mean(latencies) if latencies else None
    p50 = percentile(lat_sorted, 50)
    p90 = percentile(lat_sorted, 90)
    p95 = percentile(lat_sorted, 95)
    p99 = percentile(lat_sorted, 99)

    reqs_per_sec = len(results)/wall if wall>0 else 0

    md = []
    md.append("## Load test report (aiohttp + body check)")
    md.append(f"- total requests: {len(results)}")
    md.append(f"- concurrency: {args.concurrency}")
    md.append(f"- duration (wall sec): {wall:.2f}")
    md.append(f"- requests/sec: {reqs_per_sec:.2f}")
    md.append(f"- failed requests: {len(failed)} ({len(failed)/len(results)*100:.2f}%)")
    md.append("")
    md.append("### Latency (ms)")
    md.append(f"- avg: {avg:.2f}" if avg else "- avg: N/A")
    md.append(f"- p50: {p50:.2f}" if p50 else "- p50: N/A")
    md.append(f"- p90: {p90:.2f}" if p90 else "- p90: N/A")
    md.append(f"- p95: {p95:.2f}" if p95 else "- p95: N/A")
    md.append(f"- p99: {p99:.2f}" if p99 else "- p99: N/A")

    out = "\n".join(md)
    print(out)
    with open("loadtest-report.md","w") as f:
        f.write(out)

if __name__ == "__main__":
    main()


# python3 scripts/loadtest.py --requests 500 --concurrency 50 --hosts foo.localhost bar.localhost