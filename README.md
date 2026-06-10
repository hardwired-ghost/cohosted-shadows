# cohosted-shadows

Passive-DNS reverse-IP lookup with live DNS verification.

Pulls historical hostnames that pointed to an IP from rapiddns.io, then re-resolves each one to classify its current DNS state. **No packets are sent to the target.**

## Usage

```bash
chmod +x cohosted-shadows.sh
./cohosted-shadows.sh <IPv4>
```

## Output

| Status | Meaning |
|--------|---------|
| `[+] CURRENT` | DNS still resolves to the target IP |
| `[-] MOVED` | Resolves but to a different IP |
| `[x] DEAD` | No A record found |

## Dependencies

- `curl`
- `dig` (bind-utils / dnsutils)

## Notes

- Data sourced from [rapiddns.io](https://rapiddns.io) — may be rate-limited or incomplete
- `CURRENT` means DNS points to the IP, not that the host is actually reachable
