# RTK (Rust Token Killer) - Token-Optimized Commands

Always prefix commands with `rtk`. If RTK has a dedicated filter, it uses it. If not, it passes through unchanged.

```bash
rtk git status
rtk git diff
rtk grep <pattern>
rtk ls <path>
```

Even in command chains with `&&`, use `rtk`:
```bash
rtk git add . && rtk git commit -m "msg" && rtk git push
```
