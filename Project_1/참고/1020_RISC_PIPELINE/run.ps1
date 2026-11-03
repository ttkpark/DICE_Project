# 1020_RISC_PIPELINE local runner (ModelSim ASE).   .\run.ps1 [-F_MHZ 100] [-Progs int8_fast,int8_small]
#   1) assemble sw/*.s   2) Python ISA model, 16 cases   3) ModelSim, programs x cases   4) results/cycles.csv
# ASCII only in this file (no BOM needed). Messages from the simulator are ASCII too.
param(
  [double]$F_MHZ = 100,
  [string[]]$Progs = @("baseline_int8_fc_slow", "int8_small", "int8_fast")
)
$ErrorActionPreference = "Stop"
$MS = "C:\altera\13.0sp1\modelsim_ase\win32aloem"
if (Test-Path $MS) { $env:PATH = "$MS;" + $env:PATH }
Set-Location $PSScriptRoot
New-Item -ItemType Directory -Force build, results | Out-Null

foreach ($p in $Progs) {
  python tools\rv32i_assembler.py "sw\$p.s" -o "sw\$p.hex" --listing "sw\$p.lst"
  if ($LASTEXITCODE) { throw "assemble failed: $p" }
  python tools\verify.py "sw\$p.hex"
  if ($LASTEXITCODE) { throw "python model FAIL: $p" }
}

if (Test-Path build\work) { Remove-Item -Recurse -Force build\work }
vlib build\work
vlog -quiet -work build\work rtl\TOP.v rtl\CORE.v rtl\CONTROLLER.v rtl\IMEM.v rtl\DMEM.v sim\MEMORY_POWER.v sim\tb_top_demo.v
if ($LASTEXITCODE) { throw "vlog failed" }

vlog -quiet -work build\work sim\tb_ctrl.v
vsim -c -quiet -lib build\work TB_CTRL -l build\tb_ctrl.log -do "run -all; quit -f" | Out-Null
Select-String -Path build\tb_ctrl.log -Pattern "FAIL|TB_CTRL RESULT" | ForEach-Object { Write-Host $_.Line }

foreach ($p in $Progs) {
  foreach ($c in Get-ChildItem cases\*.json) {
    $n = $c.BaseName
    $log = "build\sim_${p}_${n}.log"
    vsim -c -quiet -lib build\work TB_TOP_DEMO "+PROGRAM=sw/$p.hex" "+DATA=cases/${n}_dmem.hex" `
         "+EXPECTED=cases/${n}_expected.hex" "+F_MHZ=$F_MHZ" -l $log -do "run -all; quit -f" | Out-Null
    $line = Select-String -Path $log -Pattern "PASS TB_TOP_DEMO|FAIL" | Select-Object -First 1
    Write-Host ("{0,-24} {1,-17} {2}" -f $p, $n, $line.Line.Trim())
  }
}
python tools\summarize.py $F_MHZ
