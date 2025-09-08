import matplotlib.pyplot as plt

# 从 CSV 读取压测数据 (req/s & p95 latency)
with open("reqs.csv") as f:
    reqs = list(map(int, f.read().strip().split(",")))
with open("latency.csv") as f:
    latency = list(map(int, f.read().strip().split(",")))

plt.figure(figsize=(6,4))

plt.subplot(2,1,1)
plt.plot(reqs, marker="o", label="Req/s")
plt.ylabel("Requests/s")
plt.legend()

plt.subplot(2,1,2)
plt.plot(latency, marker="x", color="red", label="p95 Latency (ms)")
plt.ylabel("Latency (ms)")
plt.legend()

plt.tight_layout()
plt.savefig("report.png")
print("✅ Report graph generated: report.png")