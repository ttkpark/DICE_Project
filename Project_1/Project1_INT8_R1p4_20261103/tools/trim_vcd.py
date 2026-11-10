#!/usr/bin/env python3
"""Keep the TB's active window and rebase VCD time to 0. Never fabricate activity."""
from pathlib import Path
import re,decimal
def trim(src,dst,start_ns,end_ns):
 lines=Path(src).read_text(encoding='utf-8',errors='strict').splitlines(keepends=True)
 stop=next(i for i,x in enumerate(lines) if '$enddefinitions' in x)
 # $enddefinitions $end is normally one line; also accept a separate $end.
 if '$end' not in lines[stop].split('$enddefinitions',1)[1]:
  stop=next(i for i in range(stop+1,len(lines)) if '$end' in lines[i])
 head=''.join(lines[:stop+1]);m=re.search(r'\$timescale\s+(1|10|100)\s*(s|ms|us|ns|ps|fs)\s+\$end',head,re.S)
 if not m:raise ValueError('Unsupported/missing VCD timescale')
 unit=decimal.Decimal(m[1])*{'s':decimal.Decimal('1e9'),'ms':decimal.Decimal('1e6'),'us':decimal.Decimal('1e3'),'ns':decimal.Decimal(1),'ps':decimal.Decimal('.001'),'fs':decimal.Decimal('.000001')}[m[2]]
 a=int((decimal.Decimal(str(start_ns))/unit).to_integral_value());b=int((decimal.Decimal(str(end_ns))/unit).to_integral_value())
 if b<=a:raise ValueError('Empty active VCD window')
 current=-1;out=[head,'#0\n'];seen=False;on=False;dumped=False
 for line in lines[stop+1:]:
  t=re.fullmatch(r'#(\d+)\s*',line)
  if t:
   current=int(t[1])
   if current>=b:break
   if a<=current<b:
    if current!=a:out.append('#'+str(current-a)+'\n')
    seen=True
   continue
  if a<=current<b:
   if '$dumpoff' in line:raise ValueError('Unexpected dumpoff inside active window')
   if '$dumpon' in line or '$dumpvars' in line:on=True
   if re.match(r'[01xXzZbBrR]',line.strip()):dumped=True
   out.append(line)
 if not (seen and on and dumped):raise ValueError('Active-window initial dump is missing')
 out.append('#'+str(b-a)+'\n')
 Path(dst).write_bytes(''.join(out).encode('utf-8'))
 return {'timescale_ns':str(unit),'start_tick':a,'end_tick':b,'duration_ticks':b-a}
