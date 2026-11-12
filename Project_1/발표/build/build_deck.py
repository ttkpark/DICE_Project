# Project 1 발표자료 생성: 같은 DATA 로 pptx 와 html 을 만든다. pdf 는 pptx 를 PowerPoint 로 내보낸다.
# 사용: python build_deck.py <출력 폴더>
import sys, os, html
from pptx import Presentation
from pptx.util import Inches, Pt, Emu
from pptx.dml.color import RGBColor
from pptx.chart.data import CategoryChartData
from pptx.enum.chart import XL_CHART_TYPE, XL_LEGEND_POSITION, XL_LABEL_POSITION
from pptx.enum.text import PP_ALIGN, MSO_ANCHOR
from pptx.enum.shapes import MSO_SHAPE

OUT = sys.argv[1]
FONT = "맑은 고딕"
INK, MUTED, LINE, BG2 = "1F2933", "5B6770", "D5DAE0", "F2F4F7"
ACC = "1F5FAD"                       # 강조 1색
SER = ["9DB4D3", "5C86BF", "1F5FAD"]  # small, opt64, fast (같은 색상 계열, 진할수록 빠른 프로그램)

# ---------------------------------------------------------------- 수치 (원본: 1110_compare/results/summary.md, PRESENTATION_1110_KO.md)
CPUS = ["단일 사이클", "파이프라인 ID", "파이프라인 EX"]
PROGS = ["int8_small", "int8_opt64", "int8_fast"]
PERIOD = [3.82, 2.36, 1.62]
CYC = {  # 평균 cycle, 공개 16 case
    "기준본": [8135.6875, 10186.3750, 12170.0625],
    "int8_small": [729.5000, 831.3750, 929.2500],
    "int8_opt64": [677.8750, 751.1250, 821.3750],
    "int8_fast": [552.5000, 594.3750, 636.2500],
}
T = {"int8_small": [2.7867, 1.9620, 1.5054], "int8_opt64": [2.5895, 1.7727, 1.3306], "int8_fast": [2.1105, 1.4027, 1.0307]}
A = {"int8_small": [77533.67, 82218.56, 81704.17], "int8_opt64": [77533.67, 82218.56, 81704.17], "int8_fast": [96172.47, 100857.36, 100342.97]}
P = {"int8_small": [5.2745, 8.8657, 11.8007], "int8_opt64": [5.3181, 8.9327, 11.8878], "int8_fast": [6.9959, 11.5112, 15.5594]}

SLIDES = []  # (title, kind, payload) — pptx·html 공통


def S(title, kind, **kw):
    SLIDES.append(dict(title=title, kind=kind, **kw))


S("RV32I CPU로 INT8 선형계층 빠르게 계산하기", "cover",
  sub="EE362 Project 1 · Release 1.4",
  meta="박기호 (어셈블리 최적화) · 김대현 (CPU 파이프라인) · 2026-11-17")

S("과제: 곱셈기 없는 CPU로 Y = BIAS + W·X", "bullets",
  lead="Y[j] = BIAS[j] + Σ X[i]·W[j][i]   (i = 0..7, j = 0..3)",
  items=[
      "입력 X·W 는 INT8, BIAS·Y 는 INT32. 데이터 위치는 case 마다 바뀌어 0x300 설정 블록에서 매번 읽는다",
      "명령은 기본 8개(ADD SUB AND ADDI LW SW BEQ JAL)만 사용. MUL 등 M 확장은 금지",
      "관문: 공개 16 + 숨김 8 case 정답, 고정 포트, 합성 후 setup/hold 통과. 하나라도 FAIL 이면 PPA 0점",
      "점수 = 12.5·T_best/T + 6.25·A_best/A + 6.25·P_best/P   → 실행시간 T 가 면적·전력의 2배",
      "T = 평균 cycle × 주기,  A = CPU + IMEM + DMEM 면적,  P = CPU + 메모리 전력",
  ])

S("결론: EX 분기 5단 파이프라인 + int8_fast, 1.62 ns", "kpi",
  kpis=[("31.6×", "기준본 대비 빨라짐"), ("1.0307 µs", "실행시간 T"), ("100,343", "면적 A (µm²)"), ("15.56 mW", "전력 P"), ("16 / 16", "공개 case PASS")],
  note="기준본 T ≈ 32.54 µs (단일 사이클 + 배포 프로그램, 4.00 ns) → 1.0307 µs",
  factors=[("14.73×", "프로그램", "8135.7 → 552.5 cycle"), ("1.05×", "단일 사이클 주기", "4.00 → 3.82 ns"), ("2.05×", "CPU 구조", "단일 → EX 파이프라인")])

S("① 프로그램: 비트 직렬 곱셈을 네 행이 함께 쓴다", "chart_prog",
  items=[
      "X[i] 의 비트 k 가 1 이면 네 누산기에 W[j][i]·2ᵏ 을 더한다. 비트 7 은 부호라 뺀다",
      "2ᵏ 은 add w,w,w 로 매번 2배, 비트 검사 1번(and+beq)을 출력 4행이 공유",
      "기준본의 반복 덧셈 곱 + SCRATCH 저장·재로드를 없앴다",
      "int8_fast 는 루프를 펼쳐 분기를 줄였다. 대가로 IMEM 이 256 구간",
  ],
  rows=[("기준본", "57", "64", "8,135.7"), ("int8_small", "48", "64", "729.5"), ("int8_opt64", "58", "64", "677.9"), ("int8_fast", "192", "256", "552.5")])

S("② CPU: 세 가지 구조를 같은 조건에서 비교", "table",
  head=["", "단일 사이클", "파이프라인 ID", "파이프라인 EX"],
  rows=[
      ["분기 판정 위치", "같은 cycle", "ID 단", "EX 단"],
      ["taken 분기·JAL 손실", "0", "1 cycle", "2 cycle"],
      ["lw 직후 사용", "0", "1 cycle stall", "1 cycle stall"],
      ["최소 통과 주기", "3.82 ns", "2.36 ns", "1.62 ns"],
      ["int8_fast 평균 cycle", "552.5", "594.4", "636.3"],
      ["int8_fast 실행시간 T", "2.1105 µs", "1.4027 µs", "1.0307 µs"],
  ],
  hl=3,
  note="세 폴더는 rtl/CORE.v 만 다르다. TOP·CONTROLLER·TB·메모리·SDC·프로그램 HEX 는 동일. 나머지 데이터 의존은 포워딩으로 0 cycle.")

S("③ 주기를 정하는 경로와 넣은 개선", "two",
  left_title="가장 느린 경로 (setup 보고서)",
  left=[
      "단일 3.82 ns: INSTR 입력 → 레지스터 읽기 → ALU → ALURESULT 출력. 입출력 지연 1.00 ns 씩이 한 경로에 같이 들어간다",
      "ID 2.36 ns: EX 의 ALU 결과 → ID 비교기로 포워딩 → 분기 판정 → PC. 분기 손실 1 cycle 의 대가",
      "EX 1.62 ns: PCE 레지스터 → 분기 목표 덧셈기 → PC 선택. 남은 건 덧셈기 하나",
  ],
  right_title="cycle 수를 바꾸지 않는 개선 4가지",
  right=[
      "BEQ 같음 판정을 뺄셈 결과 대신 ALU 와 병렬인 비교기로 (EX)",
      "포워딩 select 를 ID 에서 미리 계산해 ID/EX 에 저장",
      "버블 때 데이터 레지스터는 두고 제어 비트만 0 → flush 팬아웃 축소",
      "result mux 를 MEM 단으로 옮겨 MEM/WB 에 32비트만 저장 (FF 66개 감소)",
  ])

S("④ PPA: 9개 조합 (공식 flow, 공개 16 case)", "chart_ppa",
  note="T 는 EX 가, A·P 는 단일 사이클이 가장 작다. T 배점이 2배라 EX + int8_fast 가 표 안에서 가장 높다.")

S("⑤ 트레이드오프", "bullets",
  items=[
      "EX 는 단일보다 cycle 이 15.2% 많지만 주기가 2.36배 짧아 T 가 2.05배 짧다",
      "ID 는 EX 보다 cycle 이 6.6% 적지만 주기가 45.7% 길어 T 가 36.1% 길다",
      "면적의 77.8% 가 메모리 → CPU 구조를 바꿔도 A 는 5% 안에서만 움직인다",
      "전력은 EX 가 단일의 2.22배. 그러나 한 번 실행 에너지(P×T)는 14.8 / 16.2 / 16.0 nJ 로 비슷하다",
      "int8_fast 는 opt64 대비 A +22.8%, P +30.9% 이지만 T −22.5%. T 배점이 2배라 fast 를 골랐다",
  ])

S("⑥ 기능 증거와 주기 탐색", "two",
  left_title="검증",
  left=[
      "서버 공식 flow: 9개 조합 모두 공개 16/16 PASS, timing PASS",
      "로컬 ModelSim: 프로그램 4종 × 16 case + 실행 중 RESET 재인가 + 해저드 시험 + 무작위 프로그램 150개를 ISA 모델과 store 순서·주소·데이터·최종 DMEM 까지 비교 → CPU 마다 219/219 일치",
      "계약 검사 check_release.py: TOP 48 포트, 합성 목록, 공통 SDC 통과",
  ],
  right_title="주기 탐색 (EX, 0.02 ns 간격)",
  right=[],
  right_table=(["주기 ns", "setup slack ns", "통과"], [["1.70", "+0.0031", "O"], ["1.68", "+0.0007", "O"], ["1.66", "+0.0002", "O"], ["1.64", "−0.0014", "X"], ["1.62", "+0.0026", "O ← 선택"], ["1.60", "−0.0000", "X"]]),
  right_note="공식 run_ppa.tcl 과 같은 compile 로 합성, setup·hold 모두 0 이상인 최소 주기. 합성 결과가 주기에 단조롭지 않아(1.64 실패, 1.62 통과) 전부 돌려 본다. hold slack 은 모두 0.103 ns 이상.")

S("⑦ 재현 절차 (수업 서버)", "code",
  code=[
      "# 제출 패키지에서 (R1.4 공통 flow)",
      "python3 tools/check_release.py   # 포트·합성 목록·SDC 계약",
      "bash run_sim.sh                  # VCS 로 공개 16 case 기능 + activity",
      "bash run_ppa.sh                  # DC 합성 · STA · CPU 전력 + SRAM 비용",
      "",
      "# 세 CPU × 세 프로그램 비교를 한 번에",
      "cd 1110_compare && bash run_all.sh 2>&1 | tee run_all.log",
      "#   → results/summary.md, <CPU>/comparisons/<프로그램>_P<주기>/ppa_summary.json",
  ],
  note="바꾼 SDC 값은 synth/common.sdc 의 -period 숫자 하나뿐. 합성은 compile (compile_ultra 미사용).")

S("한계와 질문에 대비할 것", "bullets",
  items=[
      "모든 숫자는 공개 16 case 기준. 공식 성적은 숨김 8개를 더한 24 case 로 나온다",
      "타이밍 여유가 EX 2.6 ps · 단일 0.8 ps · ID 0.3 ps. RTL 을 고치면 주기를 다시 찾아야 한다",
      "분기 예측기는 없다(항상 PC+4). 기본 8명령만 구현, 선택 명령은 쓰지 않았다",
      "전력은 배치·배선 전 추정값 (case 별 RTL SAIF 를 합성 결과에 입혀 cycle 가중 평균)",
      "기준본(단일 + 배포 프로그램)의 A·P 는 서버에서 재지 않았다. 기준 T 는 로컬 cycle × 4.00 ns",
  ])


# ================================================================ PPTX
def rgb(h): return RGBColor.from_string(h)


prs = Presentation()
prs.slide_width, prs.slide_height = Inches(13.333), Inches(7.5)
BLANK = prs.slide_layouts[6]
W = prs.slide_width


def tb(slide, x, y, w, h, text="", size=18, bold=False, color=INK, align=PP_ALIGN.LEFT, anchor=MSO_ANCHOR.TOP):
    box = slide.shapes.add_textbox(Inches(x), Inches(y), Inches(w), Inches(h))
    tf = box.text_frame
    tf.word_wrap = True
    tf.vertical_anchor = anchor
    tf.margin_left = tf.margin_right = Inches(0.05)
    p = tf.paragraphs[0]
    p.alignment = align
    r = p.add_run()
    r.text = text
    f = r.font
    f.name, f.size, f.bold, f.color.rgb = FONT, Pt(size), bold, rgb(color)
    return tf


def para(tf, text, size=18, color=INK, bold=False, space=10, first=False, bullet=True):
    p = tf.paragraphs[0] if first else tf.add_paragraph()
    p.space_after = Pt(space)
    r = p.add_run()
    r.text = ("•  " if bullet else "") + text
    r.font.name, r.font.size, r.font.color.rgb, r.font.bold = FONT, Pt(size), rgb(color), bold
    return p


def bullets(slide, x, y, w, h, items, size=18):
    box = slide.shapes.add_textbox(Inches(x), Inches(y), Inches(w), Inches(h))
    tf = box.text_frame
    tf.word_wrap = True
    for i, t in enumerate(items):
        para(tf, t, size=size, first=(i == 0), space=12)
    return tf


def rect(slide, x, y, w, h, fill, line=None):
    s = slide.shapes.add_shape(MSO_SHAPE.RECTANGLE, Inches(x), Inches(y), Inches(w), Inches(h))
    s.fill.solid()
    s.fill.fore_color.rgb = rgb(fill)
    if line:
        s.line.color.rgb = rgb(line)
    else:
        s.line.fill.background()
    s.shadow.inherit = False
    return s


def header(slide, title, n):
    tb(slide, 0.6, 0.35, 12.1, 0.8, title, size=28, bold=True)
    rect(slide, 0.6, 1.12, 1.0, 0.06, ACC)
    tb(slide, 11.9, 7.0, 0.9, 0.35, str(n), size=11, color=MUTED, align=PP_ALIGN.RIGHT)


def table(slide, x, y, w, head, rows, colw=None, size=15, hl=None):
    nr, nc = len(rows) + 1, len(head)
    shp = slide.shapes.add_table(nr, nc, Inches(x), Inches(y), Inches(w), Inches(0.5 * nr))
    t = shp.table
    if colw:
        for i, cw in enumerate(colw):
            t.columns[i].width = Inches(cw)
    for r in range(nr):
        for c in range(nc):
            cell = t.cell(r, c)
            val = head[c] if r == 0 else rows[r - 1][c]
            cell.text = ""
            p = cell.text_frame.paragraphs[0]
            run = p.add_run()
            run.text = val
            run.font.name, run.font.size = FONT, Pt(size)
            run.font.bold = (r == 0) or (hl is not None and c == hl)
            run.font.color.rgb = rgb("FFFFFF" if r == 0 else (ACC if hl is not None and c == hl else INK))
            p.alignment = PP_ALIGN.LEFT if c == 0 else PP_ALIGN.CENTER
            cell.fill.solid()
            cell.fill.fore_color.rgb = rgb(ACC if r == 0 else ("FFFFFF" if r % 2 else BG2))
            cell.margin_top = cell.margin_bottom = Inches(0.06)
    return t


def style_chart(ch, legend=True, size=12):
    ch.font.name, ch.font.size = FONT, Pt(size)
    ch.has_legend = legend
    if legend:
        ch.legend.position = XL_LEGEND_POSITION.BOTTOM
        ch.legend.include_in_layout = False
        ch.legend.font.size = Pt(size)
    va = ch.value_axis
    va.has_major_gridlines = True
    va.major_gridlines.format.line.color.rgb = rgb(LINE)
    va.format.line.fill.background()
    va.tick_labels.font.size = Pt(size - 1)
    va.tick_labels.font.color.rgb = rgb(MUTED)
    ch.category_axis.tick_labels.font.size = Pt(size)
    ch.category_axis.format.line.color.rgb = rgb(LINE)


def grouped(slide, x, y, w, h, title, data, fmt, legend):
    cd = CategoryChartData()
    cd.categories = ["단일", "ID", "EX"]
    for p in PROGS:
        cd.add_series(p, data[p])
    gf = slide.shapes.add_chart(XL_CHART_TYPE.COLUMN_CLUSTERED, Inches(x), Inches(y), Inches(w), Inches(h), cd)
    ch = gf.chart
    style_chart(ch, legend=legend, size=11)
    ch.has_title = True
    ch.chart_title.text_frame.text = title
    tp = ch.chart_title.text_frame.paragraphs[0]
    tp.runs[0].font.size, tp.runs[0].font.bold, tp.runs[0].font.name = Pt(14), True, FONT
    ch.value_axis.tick_labels.number_format = fmt
    ch.value_axis.tick_labels.number_format_is_linked = False
    ch.plots[0].gap_width = 60
    ch.plots[0].overlap = -10
    for i, s in enumerate(ch.series):
        s.format.fill.solid()
        s.format.fill.fore_color.rgb = rgb(SER[i])
    return ch


for n, sd in enumerate(SLIDES, 1):
    s = prs.slides.add_slide(BLANK)
    k = sd["kind"]
    if k == "cover":
        rect(s, 0, 0, 13.333, 7.5, "FFFFFF")
        rect(s, 0.8, 2.2, 0.12, 2.3, ACC)
        tb(s, 1.15, 2.1, 11, 1.4, sd["title"], size=40, bold=True)
        tb(s, 1.15, 3.45, 11, 0.6, sd["sub"], size=22, color=ACC)
        tb(s, 1.15, 4.05, 11, 0.6, sd["meta"], size=16, color=MUTED)
        continue
    header(s, sd["title"], n)
    if k == "bullets":
        y = 1.55
        if sd.get("lead"):
            rect(s, 0.6, 1.5, 12.1, 0.85, BG2)
            tb(s, 0.8, 1.5, 11.8, 0.85, sd["lead"], size=24, bold=True, color=ACC, anchor=MSO_ANCHOR.MIDDLE)
            y = 2.7
        bullets(s, 0.6, y, 12.1, 7.0 - y, sd["items"], size=20)
    elif k == "kpi":
        kp = sd["kpis"]
        cw = 12.1 / len(kp)
        for i, (v, lab) in enumerate(kp):
            x = 0.6 + i * cw
            rect(s, x + 0.05, 1.6, cw - 0.1, 1.7, BG2)
            tb(s, x + 0.05, 1.75, cw - 0.1, 0.8, v, size=30 if i else 40, bold=True, color=ACC if i == 0 else INK, align=PP_ALIGN.CENTER)
            tb(s, x + 0.05, 2.65, cw - 0.1, 0.5, lab, size=14, color=MUTED, align=PP_ALIGN.CENTER)
        tb(s, 0.6, 3.65, 12.1, 0.5, "31.6× 는 세 가지 곱이다", size=18, bold=True)
        fw = 12.1 / 3
        for i, (v, lab, d) in enumerate(sd["factors"]):
            x = 0.6 + i * fw
            rect(s, x + 0.05, 4.2, fw - 0.1, 1.75, "FFFFFF", line=LINE)
            tb(s, x + 0.25, 4.3, fw - 0.5, 0.7, v, size=32, bold=True, color=ACC)
            tb(s, x + 0.25, 5.0, fw - 0.5, 0.45, lab, size=17, bold=True)
            tb(s, x + 0.25, 5.45, fw - 0.5, 0.45, d, size=14, color=MUTED)
        tb(s, 0.6, 6.25, 12.1, 0.5, sd["note"], size=13, color=MUTED)
    elif k == "chart_prog":
        bullets(s, 0.6, 1.5, 6.3, 3.0, sd["items"], size=16)
        table(s, 0.6, 4.55, 6.3, ["프로그램", "word", "IMEM", "평균 cycle"], [list(r) for r in sd["rows"]], colw=[2.1, 1.2, 1.2, 1.8], size=13)
        cd = CategoryChartData()
        names = ["기준본", "int8_small", "int8_opt64", "int8_fast"]
        cd.categories = names
        cd.add_series("평균 cycle (단일 사이클)", [CYC[p][0] for p in names])
        gf = s.shapes.add_chart(XL_CHART_TYPE.BAR_CLUSTERED, Inches(7.2), Inches(1.5), Inches(5.6), Inches(5.3), cd)
        ch = gf.chart
        style_chart(ch, legend=False)
        ch.category_axis.reverse_order = True
        ch.value_axis.tick_labels.number_format = '#,##0'
        ch.value_axis.tick_labels.number_format_is_linked = False
        pl = ch.plots[0]
        pl.gap_width = 50
        pl.has_data_labels = True
        pl.data_labels.number_format = '#,##0'
        pl.data_labels.number_format_is_linked = False
        pl.data_labels.font.size = Pt(12)
        pl.data_labels.position = XL_LABEL_POSITION.OUTSIDE_END
        ser = ch.series[0]
        ser.format.fill.solid()
        ser.format.fill.fore_color.rgb = rgb(SER[2])
        pt = ser.points[0]
        pt.format.fill.solid()
        pt.format.fill.fore_color.rgb = rgb("B8C2CC")
        ch.has_title = True
        ch.chart_title.text_frame.text = "평균 cycle, 단일 사이클 CPU (14.7배 감소)"
        r0 = ch.chart_title.text_frame.paragraphs[0].runs[0]
        r0.font.size, r0.font.bold, r0.font.name = Pt(14), True, FONT
    elif k == "table":
        table(s, 0.6, 1.6, 12.1, sd["head"], sd["rows"], colw=[3.4, 2.9, 2.9, 2.9], size=17, hl=sd.get("hl"))
        tb(s, 0.6, 5.6, 12.1, 0.9, sd["note"], size=14, color=MUTED)
    elif k == "two":
        for i, (tt, items) in enumerate([(sd["left_title"], sd["left"]), (sd["right_title"], sd["right"])]):
            x = 0.6 + i * 6.2
            tb(s, x, 1.5, 5.9, 0.5, tt, size=19, bold=True, color=ACC)
            if i == 1 and sd.get("right_table"):
                h_, r_ = sd["right_table"]
                table(s, x, 2.1, 5.9, h_, r_, colw=[1.6, 2.3, 2.0], size=14)
                tb(s, x, 5.85, 5.9, 1.0, sd["right_note"], size=12, color=MUTED)
            else:
                bullets(s, x, 2.05, 5.9, 4.8, items, size=16)
    elif k == "chart_ppa":
        cw = 12.1 / 3
        grouped(s, 0.6, 1.45, cw, 4.6, "실행시간 T (µs)", T, '0.0', False)
        grouped(s, 0.6 + cw, 1.45, cw, 4.6, "면적 A (µm²)", A, '#,##0', False)
        grouped(s, 0.6 + 2 * cw, 1.45, cw, 4.6, "전력 P (mW)", P, '0', False)
        # 범례는 한 번만
        for i, p in enumerate(PROGS):
            rect(s, 3.6 + i * 2.2, 6.2, 0.22, 0.22, SER[i])
            tb(s, 3.88 + i * 2.2, 6.1, 1.9, 0.4, p, size=13)
        tb(s, 0.6, 6.6, 12.1, 0.5, sd["note"], size=14, color=MUTED)
    elif k == "code":
        rect(s, 0.6, 1.55, 12.1, 3.2, "1F2933")
        box = s.shapes.add_textbox(Inches(0.85), Inches(1.7), Inches(11.6), Inches(3.6))
        tf = box.text_frame
        tf.word_wrap = True
        for i, line in enumerate(sd["code"]):
            p = tf.paragraphs[0] if i == 0 else tf.add_paragraph()
            r = p.add_run()
            r.text = line or " "
            r.font.name, r.font.size = "Consolas", Pt(16)
            r.font.color.rgb = rgb("9FB3C8" if line.strip().startswith("#") else "F5F7FA")
        tb(s, 0.6, 5.0, 12.1, 0.8, sd["note"], size=15, color=MUTED)

pptx_path = os.path.join(OUT, "Project1_발표.pptx")
prs.save(pptx_path)

# ================================================================ HTML (같은 SLIDES)
e = html.escape


def bars_svg(title, data, fmt):
    # 그룹 막대: 카테고리 3 (CPU) × 시리즈 3 (프로그램). 값 라벨은 fast 만.
    w, h, pl, pb, pt = 360, 240, 8, 28, 30
    mx = max(max(v) for v in data.values()) * 1.12
    gw = (w - pl * 2) / 3
    bw = gw / 4.2
    out = [f'<svg viewBox="0 0 {w} {h}" role="img" aria-label="{e(title)}"><text x="{pl}" y="18" class="ct">{e(title)}</text>']
    out.append(f'<line x1="{pl}" y1="{h-pb}" x2="{w-pl}" y2="{h-pb}" class="ax"/>')
    for ci, cat in enumerate(["단일", "ID", "EX"]):
        gx = pl + ci * gw + gw * 0.12
        for si, p in enumerate(PROGS):
            v = data[p][ci]
            bh = (h - pb - pt) * v / mx
            x = gx + si * (bw + 2)
            out.append(f'<rect x="{x:.1f}" y="{h-pb-bh:.1f}" width="{bw:.1f}" height="{bh:.1f}" rx="2" class="s{si}"><title>{cat} · {p}: {fmt(v)}</title></rect>')
            if si == 2:
                out.append(f'<text x="{x+bw/2:.1f}" y="{h-pb-bh-5:.1f}" class="vl">{fmt(v)}</text>')
        out.append(f'<text x="{gx + 1.5*(bw+2):.1f}" y="{h-8}" class="cl">{cat}</text>')
    out.append("</svg>")
    return "".join(out)


def li(items): return "<ul>" + "".join(f"<li>{e(t)}</li>" for t in items) + "</ul>"


secs = []
for n, sd in enumerate(SLIDES, 1):
    k, t = sd["kind"], e(sd["title"])
    if k == "cover":
        body = f'<div class="cover"><h1>{t}</h1><p class="sub">{e(sd["sub"])}</p><p class="meta">{e(sd["meta"])}</p></div>'
        secs.append(f'<section class="slide">{body}</section>')
        continue
    if k == "bullets":
        body = (f'<p class="lead">{e(sd["lead"])}</p>' if sd.get("lead") else "") + li(sd["items"])
    elif k == "kpi":
        body = '<div class="kpis">' + "".join(f'<div class="kpi{" hero" if i == 0 else ""}"><b>{e(v)}</b><span>{e(l)}</span></div>' for i, (v, l) in enumerate(sd["kpis"])) + "</div>"
        body += '<h3>31.6× 는 세 가지 곱이다</h3><div class="factors">' + "".join(f'<div><b>{e(v)}</b><strong>{e(l)}</strong><span>{e(d)}</span></div>' for v, l, d in sd["factors"]) + "</div>"
        body += f'<p class="note">{e(sd["note"])}</p>'
    elif k == "chart_prog":
        mx = CYC["기준본"][0]
        rows = "".join(f'<div class="hb"><span>{e(p)}</span><i style="width:{CYC[p][0]/mx*100:.1f}%"{" class=base" if p=="기준본" else ""}></i><em>{CYC[p][0]:,.1f}</em></div>' for p in ["기준본", "int8_small", "int8_opt64", "int8_fast"])
        tbl = "<table><tr><th>프로그램</th><th>word</th><th>IMEM</th><th>평균 cycle</th></tr>" + "".join("<tr>" + "".join(f"<td>{e(c)}</td>" for c in r) + "</tr>" for r in sd["rows"]) + "</table>"
        body = f'<div class="grid2"><div>{li(sd["items"])}{tbl}</div><div><p class="ct2">평균 cycle, 단일 사이클 CPU (14.7배 감소)</p>{rows}</div></div>'
    elif k == "table":
        hl = sd.get("hl")
        tbl = "<table class='big'><tr>" + "".join(f"<th>{e(h)}</th>" for h in sd["head"]) + "</tr>" + "".join("<tr>" + "".join(f'<td{" class=hl" if i == hl else ""}>{e(c)}</td>' for i, c in enumerate(r)) + "</tr>" for r in sd["rows"]) + "</table>"
        body = f'<div class="scroll">{tbl}</div><p class="note">{e(sd["note"])}</p>'
    elif k == "two":
        if sd.get("right_table"):
            h_, r_ = sd["right_table"]
            rt = "<table><tr>" + "".join(f"<th>{e(h)}</th>" for h in h_) + "</tr>" + "".join("<tr>" + "".join(f"<td>{e(c)}</td>" for c in r) + "</tr>" for r in r_) + f'</table><p class="note">{e(sd["right_note"])}</p>'
        else:
            rt = li(sd["right"])
        body = f'<div class="grid2"><div><h3>{e(sd["left_title"])}</h3>{li(sd["left"])}</div><div><h3>{e(sd["right_title"])}</h3>{rt}</div></div>'
    elif k == "chart_ppa":
        body = '<div class="grid3">' + bars_svg("실행시간 T (µs)", T, lambda v: f"{v:.2f}") + bars_svg("면적 A (µm²)", A, lambda v: f"{v/1000:.1f}k") + bars_svg("전력 P (mW)", P, lambda v: f"{v:.1f}") + "</div>"
        body += '<div class="legend">' + "".join(f'<span><i class="s{i}"></i>{p}</span>' for i, p in enumerate(PROGS)) + "</div>"
        body += f'<p class="note">{e(sd["note"])}</p>'
    elif k == "code":
        body = "<pre>" + "\n".join(f'<span class="c">{e(l)}</span>' if l.strip().startswith("#") else e(l) for l in sd["code"]) + f'</pre><p class="note">{e(sd["note"])}</p>'
    secs.append(f'<section class="slide"><h2>{t}</h2>{body}<span class="pg">{n}</span></section>')

CSS = """
:root{--ink:#1F2933;--muted:#5B6770;--line:#D5DAE0;--bg:#FFFFFF;--bg2:#F2F4F7;--acc:#1F5FAD;--s0:#9DB4D3;--s1:#5C86BF;--s2:#1F5FAD;--code:#1F2933;--codefg:#F5F7FA}
@media (prefers-color-scheme: dark){:root:not([data-theme="light"]){--ink:#E6EAEE;--muted:#9AA5B1;--line:#3A444E;--bg:#14191F;--bg2:#1E252D;--acc:#6EA2E6;--s0:#3D5A80;--s1:#5C86BF;--s2:#8FB8F0;--code:#0B0F13}}
:root[data-theme="dark"]{--ink:#E6EAEE;--muted:#9AA5B1;--line:#3A444E;--bg:#14191F;--bg2:#1E252D;--acc:#6EA2E6;--s0:#3D5A80;--s1:#5C86BF;--s2:#8FB8F0;--code:#0B0F13}
*{box-sizing:border-box}html{scroll-snap-type:y proximity}
body{margin:0;background:var(--bg);color:var(--ink);font-family:"Malgun Gothic","맑은 고딕","Noto Sans KR",system-ui,sans-serif;line-height:1.55;word-break:keep-all;overflow-wrap:anywhere}
.slide{position:relative;min-height:100vh;max-width:1180px;margin:0 auto;padding:56px 40px 48px;scroll-snap-align:start;border-bottom:1px solid var(--line);display:flex;flex-direction:column;justify-content:center}
h2{font-size:clamp(22px,3vw,32px);margin:0 0 28px;padding-bottom:14px;border-bottom:3px solid var(--acc);display:inline-block;align-self:flex-start}
h3{color:var(--acc);font-size:19px;margin:8px 0 10px}
ul{margin:0;padding-left:1.2em}li{margin:0 0 12px;font-size:clamp(16px,1.6vw,20px)}
.cover h1{font-size:clamp(30px,5vw,48px);margin:0 0 16px;border-left:8px solid var(--acc);padding-left:24px}
.cover .sub{color:var(--acc);font-size:22px;margin:0 0 6px 32px}.cover .meta{color:var(--muted);margin:0 0 0 32px}
.lead{background:var(--bg2);color:var(--acc);font-weight:700;font-size:clamp(18px,2.2vw,24px);padding:16px 20px;border-radius:6px;margin:0 0 22px}
.kpis{display:grid;grid-template-columns:repeat(5,1fr);gap:10px}.kpi{background:var(--bg2);border-radius:6px;padding:18px 8px;text-align:center}
.kpi b{display:block;font-size:clamp(20px,2.6vw,30px)}.kpi.hero b{color:var(--acc);font-size:clamp(26px,3.4vw,40px)}.kpi span{color:var(--muted);font-size:14px}
.factors{display:grid;grid-template-columns:repeat(3,1fr);gap:10px}.factors div{border:1px solid var(--line);border-radius:6px;padding:14px 18px}
.factors b{display:block;color:var(--acc);font-size:30px}.factors strong{display:block}.factors span{color:var(--muted);font-size:14px}
.note{color:var(--muted);font-size:14px;margin-top:18px}
.grid2{display:grid;grid-template-columns:1fr 1fr;gap:36px}.grid3{display:grid;grid-template-columns:repeat(3,1fr);gap:16px}
table{border-collapse:collapse;width:100%;margin-top:14px;font-size:15px}th{background:var(--acc);color:#fff;padding:8px 10px;text-align:center}
td{padding:8px 10px;text-align:center;border-bottom:1px solid var(--line)}td:first-child,th:first-child{text-align:left}tr:nth-child(odd) td{background:var(--bg2)}
table.big{font-size:clamp(14px,1.5vw,18px)}td.hl{color:var(--acc);font-weight:700}.scroll{overflow-x:auto}
.hb{display:grid;grid-template-columns:96px 1fr 70px;align-items:center;gap:8px;margin:14px 0}.hb span{font-size:14px}
.hb i{display:block;height:28px;background:var(--s2);border-radius:3px;min-width:2px}.hb i.base{background:var(--line)}.hb em{font-style:normal;font-size:14px;font-variant-numeric:tabular-nums}
.ct2{font-weight:700;margin:0 0 6px}
svg{width:100%;height:auto}svg .ct{font-weight:700;font-size:14px;fill:var(--ink)}svg .ax{stroke:var(--line)}svg .cl{font-size:12px;fill:var(--muted);text-anchor:middle}svg .vl{font-size:11px;fill:var(--ink);text-anchor:middle}
.s0{fill:var(--s0);background:var(--s0)}.s1{fill:var(--s1);background:var(--s1)}.s2{fill:var(--s2);background:var(--s2)}
.legend{display:flex;gap:24px;justify-content:center;margin-top:8px;font-size:14px}.legend i{display:inline-block;width:12px;height:12px;border-radius:2px;margin-right:6px;vertical-align:-1px}
pre{background:var(--code);color:var(--codefg);padding:22px 24px;border-radius:6px;overflow-x:auto;font:15px/1.7 Consolas,"D2Coding",monospace}pre .c{color:#9FB3C8}
.pg{position:absolute;right:40px;bottom:20px;color:var(--muted);font-size:12px}
@media (max-width:760px){.slide{padding:40px 16px 40px;min-height:auto}.grid2,.grid3{grid-template-columns:1fr}.kpis{grid-template-columns:repeat(2,1fr)}.factors{grid-template-columns:1fr}.pg{right:16px}}
"""
page = f"""<!doctype html><html lang="ko"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Project 1 발표</title><style>{CSS}</style></head><body>
{''.join(secs)}
</body></html>"""
with open(os.path.join(OUT, "Project1_발표.html"), "w", encoding="utf-8") as f:
    f.write(page)
print("ok", pptx_path, len(SLIDES), "slides")
