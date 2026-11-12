#!/usr/bin/env python3
"""R1.4 common interface/source/clock checks. Not a functional grader."""
from pathlib import Path
import re,hashlib,json
ROOT=Path(__file__).resolve().parents[1]
def cpu_sources():
 paths=[]
 for line in (ROOT/'synth/rtl.f').read_text(encoding='utf-8').splitlines():
  name=line.split('#',1)[0].strip()
  if not name:continue
  p=(ROOT/name).resolve()
  if ROOT not in p.parents or not p.is_file():raise ValueError('CPU file not in package: '+name)
  if p.suffix!='.v' or p.name.upper() in ['IMEM.V','DMEM.V','MEMORY_POWER.V'] or 'sim' in p.relative_to(ROOT).parts:
   raise ValueError('Simulation file in CPU synthesis list: '+name)
  text=p.read_text(encoding='utf-8')
  clean=re.sub(r'//[^\n]*|/\*.*?\*/','',text,flags=re.S)
  if re.search(r'\$(?:readmem[hb]|value\$plusargs)|\binitial\b',clean):
   raise ValueError('Simulation initialization in CPU source: '+name)
  paths.append(p)
 if len(set(paths))!=len(paths):raise ValueError('Duplicate CPU file in synth/rtl.f')
 return paths
def period_ns():
 s=(ROOT/'synth/common.sdc').read_text(encoding='utf-8')
 m=re.findall(r'^create_clock\s+-name\s+CPU_CLK\s+-period\s+([\d.]+)\s+\[get_ports CLK\]',s,re.M)
 if len(m)!=1 or float(m[0])<=0:raise ValueError('Exactly one positive literal clock period is required')
 return float(m[0])
def fingerprint(program):
 paths=set(cpu_sources())|{Path(program).resolve()}
 for pattern in ['sim/**/*.v','synth/*.tcl','synth/*.sdc','cases/*','tools/run_flow.py','tools/trim_vcd.py','tools/check_release.py']:
  paths.update(p for p in ROOT.glob(pattern) if p.name!='case_list.tcl')
 entries={p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(paths) if p.is_file()}
 return hashlib.sha256(json.dumps(entries,sort_keys=True).encode()).hexdigest(),entries
def check():
 sources=cpu_sources();top=(ROOT/'rtl/TOP.v').read_text(encoding='utf-8')
 ports=re.findall(r'\b(input|output)\s+wire\s*(\[31:0\])?\s*(\w+)\s*[,\n)]',top)
 actual={name:(direction,32 if width else 1) for direction,width,name in ports}
 expected={'CLK':('input',1),'RESET':('input',1),'INSTR':('input',32),'READDATA':('input',32),
           'PC':('output',32),'MEMWRITE':('output',1),'ALURESULT':('output',32),'WRITEDATA':('output',32)}
 expected.update({'RESERVED_IN'+str(i):('input',32) for i in range(20)})
 expected.update({'RESERVED_OUT'+str(i):('output',32) for i in range(20)})
 if actual!=expected or len(ports)!=48:raise ValueError('TOP R1.4 port contract mismatch')
 if re.search(r'\b(?:IMEM|DMEM)\s+\w+\s*\(',top):raise ValueError('Memory instance remains inside TOP')
 sdc=(ROOT/'synth/common.sdc').read_text(encoding='utf-8')
 for cmd in ['set_input_delay -clock [get_clocks CPU_CLK] -min 1.00 [get_ports {INSTR READDATA RESERVED_IN*}]',
             'set_input_delay -clock [get_clocks CPU_CLK] -max 1.00 [get_ports {INSTR READDATA RESERVED_IN*}]',
             'set_input_transition 0.10 [get_ports {INSTR READDATA RESERVED_IN*}]']:
  if cmd not in sdc:raise ValueError('Common input constraint changed: '+cmd)
 actual_commands=[line.strip() for line in sdc.splitlines() if line.strip() and not line.lstrip().startswith('#')]
 actual_commands[0]=re.sub(r'-period [\d.]+','-period PERIOD',actual_commands[0])
 expected_commands=['create_clock -name CPU_CLK -period PERIOD [get_ports CLK]',
  'set_clock_uncertainty -setup 0.10 [get_clocks CPU_CLK]',
  'set_clock_uncertainty -hold 0.05 [get_clocks CPU_CLK]',
  'set_clock_transition 0.08 [get_clocks CPU_CLK]',
  'set_input_delay -clock [get_clocks CPU_CLK] -min 1.00 [get_ports {INSTR READDATA RESERVED_IN*}]',
  'set_input_delay -clock [get_clocks CPU_CLK] -max 1.00 [get_ports {INSTR READDATA RESERVED_IN*}]',
  'set_input_transition 0.10 [get_ports {INSTR READDATA RESERVED_IN*}]',
  'set_output_delay -clock [get_clocks CPU_CLK] -min 1.00 [all_outputs]',
  'set_output_delay -clock [get_clocks CPU_CLK] -max 1.00 [all_outputs]',
  'set_load 20.0 [all_outputs]',
  'set_max_transition 0.25 [all_outputs]']
 if actual_commands!=expected_commands:raise ValueError('Common SDC commands/numbers changed; only clock period may change')
 return {'release':'1.4','cpu_sources':[p.relative_to(ROOT).as_posix() for p in sources],'top_ports':len(ports),'period_ns':period_ns(),'frequency_mhz':1000/period_ns()}
if __name__=='__main__':print(json.dumps(check(),ensure_ascii=False,indent=2))
