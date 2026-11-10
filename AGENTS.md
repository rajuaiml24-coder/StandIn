## Development Safety and Azure Rate-Limit Protection

1. Preserve existing implementation context, workspace changes and project functionality.
2. Never discard, reset or overwrite uncommitted changes.
3. Avoid unnecessary parallel agents and concurrent model requests.
4. If Azure returns HTTP 429, respect `retry-after-ms` and use exponential backoff with jitter.
5. Never retry file modifications or other non-idempotent operations blindly.
6. Maintain task progress and resume unfinished work after temporary API failures.
7. Before starting a new major task, inspect the current Git status and relevant project state.
8. Do not change Azure API keys, endpoints, deployments, model settings or Codex configuration without explicit approval.
9. Do not introduce gateways, proxies or rate-limit infrastructure without approval.
10. Prioritize correctness, backward compatibility and preservation of existing functionality.
11. Verify completed changes with appropriate tests before reporting completion.
12. Do not claim a task is complete if any required implementation or verification remains outstanding.