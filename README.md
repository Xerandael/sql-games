This is a crazy project to implement the gameplay of [https://store.steampowered.com/app/1349230/5D_Chess_With_Multiverse_Time_Travel/](5D Chess With Multiverse Timetravel) in SQL.

Also I made a small custom test framework in Ruby.  The code defining the test macro is brutal but the tests themselves are straightforward.  Each test is of the following form:
```
name
---
the sequence of movements
from (w,x,y,z) to (w,x,y,z)
from (w,x,y,z) to (w,x,y,z)
...
---
an assertion query
```
