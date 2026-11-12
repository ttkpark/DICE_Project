# pptx -> pdf (+ 선택: 슬라이드 PNG). 사용: export.ps1 <pptx 경로> <pdf 경로> [png 폴더]
param([string]$Pptx, [string]$Pdf, [string]$PngDir = "")
$pp = New-Object -ComObject PowerPoint.Application
$pres = $pp.Presentations.Open((Resolve-Path $Pptx).Path, $true, $false, $false)
$pres.SaveAs($Pdf, 32)
if ($PngDir) { New-Item -ItemType Directory -Force $PngDir | Out-Null; $pres.Export($PngDir, "PNG", 1600, 900) }
$pres.Close(); $pp.Quit()
