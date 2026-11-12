#!/usr/bin/env python3
"""Common public-case simulation, activity and CPU-only PPA flow (R1.4)."""
from pathlib import Path
import argparse,subprocess,sys,shutil,json,re,math
from check_release import ROOT,check,cpu_sources,period_ns,fingerprint
from trim_vcd import trim
def run(args,log):
 print('+',' '.join(map(str,args)),flush=True)
 with Path(log).open('w',encoding='utf-8') as f:
  p=subprocess.run(list(map(str,args)),cwd=ROOT,stdout=f,stderr=subprocess.STDOUT)
 text=Path(log).read_text(encoding='utf-8',errors='replace')
 if p.returncode:raise RuntimeError('Command failed; see '+str(log))
 return text
def needed(cmd):
 p=shutil.which(cmd)
 if not p:raise RuntimeError('Required server command not found: '+cmd)
 return p
def sim(args):
 cfg=check();program=(ROOT/args.program).resolve()
 if ROOT not in program.parents or not program.is_file():raise ValueError('Program must be a HEX inside the package')
 words=program.read_text(encoding='utf-8').splitlines()
 if not 1<=len(words)<=512 or any(not re.fullmatch(r'[0-9a-fA-F]{8}',x.strip()) for x in words):raise ValueError('HEX must have 1..512 contiguous 8-digit words')
 manifest=ROOT/'results/simulation_manifest.json'
 if manifest.exists():manifest.unlink()
 files=cpu_sources()+[ROOT/'sim/mem/IMEM.v',ROOT/'sim/mem/DMEM.v',ROOT/'sim/MEMORY_POWER.v',ROOT/'sim/TB_TOP.v']
 if args.backend=='vcs':
  exe=ROOT/'build/simv';run([needed('vcs_queue'),'-full64','-timescale=1ns/1fs','-top','TB_TOP',*files,'-Mdir=build/csrc','-o',exe],ROOT/'logs/compile.log');launcher=[exe]
 else:
  exe=ROOT/'build/sim.vvp';run([args.iverilog,'-g2001','-s','TB_TOP','-o',exe,*files],ROOT/'logs/compile.log');launcher=[args.vvp,exe]
 signature,source_hashes=fingerprint(program);rows=[]
 for casefile in sorted((ROOT/'cases').glob('*.json')):
  case=json.loads(casefile.read_text(encoding='utf-8'));name=casefile.stem
  raw=ROOT/'build'/(name+'.raw.vcd');active=ROOT/'build'/(name+'.active.vcd');log=ROOT/'logs'/(name+'.log')
  for stale in [raw,active]:
   if stale.exists():stale.unlink()
  text=run([*launcher,'+PROGRAM='+str(program),'+DATA='+str(ROOT/'cases'/case['memory_file']),'+EXPECTED='+str(ROOT/'cases'/(name+'_expected.hex')),
       '+F_MHZ='+format(cfg['frequency_mhz'],'.12g'),'+VCD='+str(raw)],log)
  if re.search(r'\b(?:FAIL|Fatal|Error)\b',text,re.I) or 'PASS TB_TOP:' not in text:raise RuntimeError('CPU functional check failed: '+name+'; see '+str(log))
  m=re.search(r'MEMORY_PPA cycles=(\d+) LOAD=(\d+) STORE=(\d+) IMEM_words=(\d+) F_MHz=',text)
  window=re.search(r'ACTIVE_WINDOW start_ns=([\d.]+) end_ns=([\d.]+)',text)
  if not m or not window or not raw.is_file():raise RuntimeError('Missing counters/activity window: '+name)
  cycles,loads,stores,imem_words=map(int,m.groups());start,end=map(float,window.groups())
  if cycles<=0 or imem_words!=len(words) or abs((end-start)-cycles*cfg['period_ns'])>max(.00001,cycles*.000002):raise RuntimeError('Cycle/period/activity mismatch: '+name)
  vc=trim(raw,active,start,end)
  rows.append({'case':name,'cycles':cycles,'loads':loads,'stores':stores,'imem_words':imem_words,'vcd':active.relative_to(ROOT).as_posix(),'window':vc,'pass':True})
  print('PASS CPU',name,cycles,'cycles',flush=True)
 if len(rows)!=16:raise RuntimeError('Public case count is not 16')
 manifest.write_text(json.dumps({'release':'1.4','backend':args.backend,'program':program.relative_to(ROOT).as_posix(),'fingerprint':signature,'source_hashes':source_hashes,**cfg,'cases':rows},ensure_ascii=False,indent=2),encoding='utf-8')
 print('TOTAL CPU PASS 16/16. This is the public check, not the official 24-case grade.')
def power_mw(text,label):
 m=re.search(label+r'\s*=\s*([\d.eE+\-]+)\s*(mW|uW|nW|pW|W)\b',text)
 if not m:raise ValueError('Unrecognized report_power field: '+label)
 return float(m[1])*{'W':1000,'mW':1,'uW':.001,'nW':.000001,'pW':.000000001}[m[2]]
def ppa(args):
 cfg=check();manifest=ROOT/'results/simulation_manifest.json'
 if not manifest.is_file():raise RuntimeError('Run a successful run_sim.sh first')
 data=json.loads(manifest.read_text(encoding='utf-8'))
 if data['backend']!='vcs':raise RuntimeError('Official server PPA activity must be generated with VCS, not local Icarus QA')
 signature,_=fingerprint(ROOT/data['program'])
 if signature!=data['fingerprint'] or cfg['period_ns']!=data['period_ns']:raise RuntimeError('RTL/program/constraints changed: rerun run_sim.sh')
 converter=needed('vcd2saif');dc=needed('dc_shell_queue')
 for row in data['cases']:
  saif=ROOT/'build'/(row['case']+'.saif')
  if saif.exists():saif.unlink()
  run([converter,'-input',ROOT/row['vcd'],'-output',saif],ROOT/'logs'/(row['case']+'_vcd2saif.log'))
  if not saif.is_file() or saif.stat().st_size<100:raise RuntimeError('SAIF was not generated: '+row['case'])
 (ROOT/'synth/case_list.tcl').write_text('set P1_CASES {'+' '.join(x['case'] for x in data['cases'])+'}\n',encoding='utf-8')
 for stale in ['results/ppa_status.json','results/ppa_summary.json']:
  p=ROOT/stale
  if p.exists():p.unlink()
 text=run([dc,'-f','synth/run_ppa.tcl'],ROOT/'logs/dc_ppa.log')
 if 'P1_PPA_COMPLETE' not in text or re.search(r'^Error:',text,re.M):raise RuntimeError('DC flow incomplete; inspect logs/dc_ppa.log')
 status=json.loads((ROOT/'results/ppa_status.json').read_text(encoding='utf-8'))
 if not status['timing_pass'] or status['setup_slack_ns']<0 or status['hold_slack_ns']<0:raise RuntimeError('Setup/hold FAIL: PPA gate not passed')
 area_text=(ROOT/'reports/cpu_area.rpt').read_text(encoding='utf-8',errors='replace')
 am=re.search(r'Total cell area:\s*([\d.eE+\-]+)',area_text)
 if not am or float(am[1])<=0:raise RuntimeError('Missing positive CPU cell area')
 cpu_area=float(am[1]);total_cycles=sum(x['cycles'] for x in data['cases']);total_access=sum(x['loads']+x['stores'] for x in data['cases'])
 nw=data['cases'][0]['imem_words'];a_imem,e_imem=(8713.50,2.23) if nw<=64 else ((27352.30,7.00) if nw<=256 else (50667.68,12.97))
 cpu_power=0;per=[]
 for row in data['cases']:
  report=(ROOT/'reports'/row['case']/'power.rpt').read_text(encoding='utf-8',errors='replace')
  mw=power_mw(report,'Total Dynamic Power')+power_mw(report,'Cell Leakage Power')
  if not math.isfinite(mw) or mw<=0:raise RuntimeError('Invalid CPU power: '+row['case'])
  cpu_power+=mw*row['cycles']/total_cycles;per.append({'case':row['case'],'cpu_average_power_mw':mw,'weight_cycles':row['cycles']})
 mem_dynamic=cfg['frequency_mhz']/1000*(e_imem+12.97*total_access/total_cycles);mem_static=.020*(a_imem+50667.68)/1000
 summary={'release':'1.4','scope':'공개 16개 연습 결과. 공식 24개 성적은 별도 고정 덱에서 산출.','fingerprint':signature,**cfg,**status,'public_case_count':len(per),'mean_cycles':total_cycles/len(per),
  'time_us':total_cycles/len(per)/cfg['frequency_mhz'],'cpu_cell_area_um2':cpu_area,'imem_area_um2':a_imem,'dmem_area_um2':50667.68,'total_area_um2':cpu_area+a_imem+50667.68,
  'cpu_power_mw':cpu_power,'memory_dynamic_mw':mem_dynamic,'memory_static_proxy_mw':mem_static,'total_power_mw':cpu_power+mem_dynamic+mem_static,'cpu_case_power':per,
  'power_method':'same mapped CPU, per-case RTL SAIF mapped with saif_map, cycle-weighted power; pre-route estimate, annotation reports require TA review'}
 (ROOT/'results/ppa_summary.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2),encoding='utf-8');print(json.dumps(summary,ensure_ascii=False,indent=2))
def main():
 p=argparse.ArgumentParser();p.add_argument('action',choices=['sim','ppa']);p.add_argument('--program',default='baseline_int8_fc_slow.hex');p.add_argument('--backend',choices=['vcs','iverilog'],default='vcs');p.add_argument('--iverilog',default='iverilog');p.add_argument('--vvp',default='vvp');args=p.parse_args()
 for name in ['build','logs','reports','results']:(ROOT/name).mkdir(exist_ok=True)
 try:(sim if args.action=='sim' else ppa)(args)
 except (ValueError,RuntimeError,OSError,KeyError) as e:print('FAIL COMMON FLOW:',e,file=sys.stderr);return 1
 return 0
if __name__=='__main__':sys.exit(main())
