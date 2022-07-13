Say something nice.

```elixir
_pid = Soju.start_link([])
job = %Soju.Job{}
:ok = Soju.schedule(job)
```
