// Project 1 발표 슬라이드 생성기 (R1.4 공통 flow 수치, R1.5~R1.7 제출 지침 반영).
// 사용:  npm install pptxgenjs   (한 번)
//        cd presentation/build && npm install && node build_deck.js ../project1.pptx apply_theme.js
// 수치 원본: 1110 tests/1112 tests 7/1110_compare.tar 의 results/summary.md, comparisons/*/ppa_summary.json
// 수치를 바꿀 때는 아래 "수치" 블록만 고친다.
const pptxgen = require("pptxgenjs");

const OUT = process.argv[2] || "project1.pptx";
const APPLY_THEME = process.argv[3];

// ---------------------------------------------------------------- 수치 (공개 16 case, 서버 R1.4 공식 flow)
const CPU = ["단일 사이클", "파이프라인 ID", "파이프라인 EX"];
const PERIOD = [3.82, 2.36, 1.62];
const PROG = ["int8_small", "int8_opt64", "int8_opt64v2", "int8_fast", "int8_fastv2"];
const WORDS = { baseline: 57, int8_small: 48, int8_opt64: 58, int8_opt64v2: 63, int8_fast: 192, int8_fastv2: 193 };
const CYC = { // [단일, ID, EX]
  baseline: [8135.6875, 10186.375, 12170.0625],
  int8_small: [729.5, 831.375, 929.25], int8_opt64: [677.875, 751.125, 821.375],
  int8_opt64v2: [663.125, 721.625, 777.125], int8_fast: [552.5, 594.375, 636.25],
  int8_fastv2: [551.5, 592.375, 630.25],
};
const T = {
  int8_small: [2.7867, 1.9620, 1.5054], int8_opt64: [2.5895, 1.7727, 1.3306],
  int8_opt64v2: [2.5331, 1.7030, 1.2589], int8_fast: [2.1105, 1.4027, 1.0307],
  int8_fastv2: [2.1067, 1.3980, 1.0210],
};
const A64 = [77533.67, 82218.56, 81704.17], A256 = [96172.47, 100857.36, 100342.97];
const ACPU = [18152.49, 22837.38, 22322.99];
const P = {
  int8_small: [5.2745, 8.8657, 11.8007], int8_opt64: [5.3181, 8.9327, 11.8878],
  int8_opt64v2: [5.3109, 8.9382, 11.8581], int8_fast: [6.9959, 11.5112, 15.5594],
  int8_fastv2: [6.9973, 11.4706, 15.4104],
};
const PCPU_FASTV2 = [3.2658, 6.4338, 8.8303];
const SCORE = {
  int8_small: [17.08, 16.12, 17.20], int8_opt64: [17.38, 16.78, 18.30],
  int8_opt64v2: [17.50, 17.08, 18.85], int8_fast: [15.80, 16.77, 19.33],
  int8_fastv2: [15.81, 16.81, 19.47],
};
const area = (prog, c) => (WORDS[prog] > 64 ? A256 : A64)[c];
const BASE_T = CYC.baseline[0] * PERIOD[0] / 1000;            // 기준본: 단일 사이클 3.82 ns
const BASE_P = null;                                          // 서버 측정 후 숫자로 바꾼다 (mW)

const f2 = (x) => x.toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
const f4 = (x) => x.toFixed(4);

// ---------------------------------------------------------------- 테마
const THEME = {
  name: "EE362 Project1",
  headFontFace: "Malgun Gothic",
  bodyFontFace: "Malgun Gothic",
  colors: {
    dk1: "1D2733", lt1: "FFFFFF", dk2: "14273A", lt2: "EDF1F4",
    accent1: "C4622D", accent2: "2B7A8A", accent3: "9AAFC2", accent4: "5E7387",
    accent5: "B7791F", accent6: "2E8A57", hlink: "2B7A8A", folHlink: "5E7387",
  },
};
const HX = THEME.colors;

const pres = new pptxgen();
pres.layout = "LAYOUT_WIDE"; // 13.333 x 7.5 in
pres.title = "EE362 Project 1 발표";
pres.author = "박기호, 김대현";
pres.theme = { headFontFace: THEME.headFontFace, bodyFontFace: THEME.bodyFontFace };
const C = pres.SchemeColor;
const W = 13.333;

// ---------------------------------------------------------------- 레이아웃
pres.defineSlideMaster({
  title: "COVER",
  background: { color: C.text2 },
  objects: [
    { placeholder: { options: { name: "title", type: "title", x: 0.8, y: 1.6, w: 11.7, h: 2.2, fontSize: 40, bold: true, color: C.background1, valign: "bottom", align: "left" }, text: "" } },
    { placeholder: { options: { name: "body", type: "body", x: 0.8, y: 4.1, w: 11.7, h: 2.6, fontSize: 18, color: C.background2, valign: "top", align: "left" }, text: "" } },
  ],
});
pres.defineSlideMaster({
  title: "CONTENT",
  background: { color: C.background1 },
  margin: [0.5, 0.6, 0.6, 0.6],
  objects: [
    { placeholder: { options: { name: "title", type: "title", x: 0.6, y: 0.38, w: 9.3, h: 0.8, fontSize: 26, bold: true, color: C.text1, valign: "middle", align: "left", margin: 0 }, text: "" } },
    { text: { text: "EE362 Project 1 · 박기호 · 김대현", options: { x: 0.6, y: 7.02, w: 6, h: 0.3, fontSize: 10, color: C.accent4, margin: 0 } } },
  ],
  slideNumber: { x: 12.2, y: 7.02, w: 0.55, h: 0.3, fontSize: 10, color: C.accent4, align: "right" },
});

let n = 0;
function content(title, tagText, notes, section) {
  const s = pres.addSlide({ masterName: "CONTENT", sectionTitle: section });
  s.addText(title, { placeholder: "title" });
  if (tagText) {
    s.addText(tagText, {
      shape: pres.shapes.ROUNDED_RECTANGLE, rectRadius: 0.12, x: 10.15, y: 0.55, w: 2.6, h: 0.46,
      fill: { color: C.background2 }, color: C.accent2, bold: true, fontSize: 12, align: "center", valign: "middle",
      isTextBox: true, objectName: "peer-review-tag",
    });
  }
  if (notes) s.addNotes(notes);
  n++;
  return s;
}
const txt = (s, t, o) => s.addText(t, Object.assign({ isTextBox: true, fontSize: 16, color: C.text1, valign: "top", margin: 0 }, o));
const bullets = (s, items, o) => txt(s, items.map((t, i) => ({
  text: t, options: { bullet: { indent: 16 }, breakLine: i < items.length - 1, paraSpaceAfter: 8 },
})), o);
const card = (s, o) => s.addShape(pres.shapes.ROUNDED_RECTANGLE, Object.assign({ rectRadius: 0.08, fill: { color: C.background2 }, line: { color: C.background2 } }, o));
const H = (text, o) => Object.assign({ text, options: Object.assign({ bold: true, fill: { color: C.text2 }, color: C.background1 }, o || {}) });
const hl = (text, o) => ({ text, options: Object.assign({ bold: true, color: C.accent1 }, o || {}) });
function table(s, rows, o) {
  s.addTable(rows, Object.assign({
    fontSize: 13, color: C.text1, valign: "middle", margin: [3, 6, 3, 6],
    border: { type: "solid", pt: 0.75, color: "D3DAE1" },
  }, o));
}
function arrow(s, x1, y1, x2, y2, label, lo) {
  s.addShape(pres.shapes.LINE, {
    x: Math.min(x1, x2), y: Math.min(y1, y2), w: Math.abs(x2 - x1), h: Math.abs(y2 - y1),
    flipH: x2 < x1, flipV: y2 < y1, line: { color: C.accent4, width: 1.5, endArrowType: "triangle" },
  });
  if (label) txt(s, label, Object.assign({ fontSize: 11, color: C.accent4 }, lo));
}
function seg(s, x1, y1, x2, y2) {
  s.addShape(pres.shapes.LINE, { x: Math.min(x1, x2), y: Math.min(y1, y2), w: Math.abs(x2 - x1), h: Math.abs(y2 - y1), line: { color: C.accent4, width: 1.5 } });
}

// ---------------------------------------------------------------- 1. 표지
pres.addSection({ title: "도입" });
{
  const s = pres.addSlide({ masterName: "COVER", sectionTitle: "도입" });
  s.addText([{ text: "곱셈기 없는 RV32I CPU로", options: { breakLine: true } }, { text: "INT8 선형계층 계산하기" }], { placeholder: "title" });
  s.addText([
    { text: "EE362 Project 1 · R1.4 공통 flow · 2026-11-17", options: { breakLine: true } },
    { text: "박기호 (어셈블리 최적화) · 김대현 (CPU 파이프라인)", options: { color: C.accent3 } },
  ], { placeholder: "body" });
  s.addNotes("EE362 Project 1 발표를 시작하겠습니다. 곱셈기가 없는 RV32I CPU에서 INT8 선형계층을 얼마나 빨리 계산할 수 있는지, 어셈블리와 CPU 두 쪽에서 개선한 결과를 말씀드리겠습니다. 어셈블리는 박기호, CPU 파이프라인은 김대현이 맡았습니다.");
  n++;
}

// ---------------------------------------------------------------- 2. 과제와 평가
{
  const s = content("과제와 평가 규칙", "배경", "계산은 X 8개와 4×8 가중치의 내적에 BIAS를 더하는 것입니다. 데이터 위치는 case마다 바뀌어서 설정 블록에서 매번 읽어야 하고, 마지막 store로 DONE을 써야 끝납니다. 명령은 기본 8개만 필수이고, 저희는 선택 명령을 쓰지 않았습니다. 점수는 통과 팀끼리 상대평가이며 실행시간 T의 가중치가 면적·전력의 두 배라는 점이 설계 방향을 정했습니다.", "도입");
  card(s, { x: 0.6, y: 1.5, w: 7.2, h: 1.0 });
  txt(s, "Y[j] = BIAS[j] + Σ X[i] · W[j][i]      i = 0..7,  j = 0..3", { x: 0.85, y: 1.5, w: 6.8, h: 1.0, fontSize: 20, bold: true, color: C.text2, valign: "middle" });
  bullets(s, [
    "X·W는 INT8, BIAS·Y는 INT32. 데이터 주소는 case마다 달라 0x300 설정 블록에서 매번 읽는다",
    "Y 4개를 쓴 뒤 마지막 store로 DONE_ADDR ← DONE_TOKEN. 여기까지가 cycle 수",
    "명령: 기본 8개(ADD SUB AND ADDI LW SW BEQ JAL) 필수. 우리는 선택 명령을 쓰지 않았다",
    "합성 대상은 TOP(CPU)만. IMEM·DMEM은 TB 쪽, SDC는 주기 숫자만 바꿀 수 있다",
  ], { x: 0.6, y: 2.8, w: 7.2, h: 3.8, fontSize: 16 });
  card(s, { x: 8.2, y: 1.5, w: 4.55, h: 4.5 });
  txt(s, [
    { text: "점수 (관문 통과 팀끼리 상대평가)", options: { bold: true, fontSize: 16, color: C.accent2, breakLine: true } },
    { text: " ", options: { fontSize: 8, breakLine: true } },
    { text: "S = 12.5·T_best/T", options: { bold: true, fontSize: 20, breakLine: true } },
    { text: "    + 6.25·A_best/A", options: { bold: true, fontSize: 20, breakLine: true } },
    { text: "    + 6.25·P_best/P", options: { bold: true, fontSize: 20, breakLine: true } },
    { text: " ", options: { fontSize: 8, breakLine: true } },
    { text: "T = 평균 cycle ÷ f", options: { fontSize: 16, breakLine: true } },
    { text: "A = CPU cell + IMEM + DMEM 면적", options: { fontSize: 16, breakLine: true } },
    { text: "P = CPU + 메모리 동적 + 정적 전력", options: { fontSize: 16, breakLine: true } },
    { text: " ", options: { fontSize: 8, breakLine: true } },
    { text: "관문: 24 case 기능, 제어·연결, 재현·개선 근거, 포트·ISA, setup/hold. 하나라도 FAIL이면 PPA 0점", options: { fontSize: 15, color: C.accent4 } },
  ], { x: 8.45, y: 1.7, w: 4.1, h: 4.9, paraSpaceAfter: 4 });
}

// ---------------------------------------------------------------- 3. 결론
{
  const s = content("결론: EX 분기 5단 파이프라인 + int8_fastv2, 1.62 ns", "요약", "결론부터 말씀드리면, EX 단에서 분기를 판정하는 5단 파이프라인에 int8_fastv2 프로그램을 1.62 ns로 돌리는 조합이 가장 좋았습니다. 실행시간 1.021 마이크로초, 공개 16 case 모두 통과했습니다. 같은 단일 사이클 CPU에서 배포 기준 프로그램을 돌린 것과 비교하면 30.4배 빠르고, 그중 14.75배는 프로그램, 2.06배는 CPU 구조에서 나왔습니다.", "도입");
  const stats = [
    ["1.0210 µs", "실행시간 T"], ["617.28 MHz", "주파수 (1.62 ns)"], ["100,342.97", "면적 A (µm²)"],
    ["15.4104 mW", "전력 P"], ["16 / 16", "공개 case PASS"],
  ];
  stats.forEach(([v, k], i) => {
    const x = 0.6 + i * 2.45;
    card(s, { x, y: 1.55, w: 2.25, h: 1.6, objectName: "stat-" + i });
    txt(s, v, { x: x + 0.15, y: 1.75, w: 1.95, h: 0.7, fontSize: 22, bold: true, color: i === 0 ? C.accent1 : C.text2, align: "center", valign: "middle" });
    txt(s, k, { x: x + 0.15, y: 2.5, w: 1.95, h: 0.45, fontSize: 13, color: C.accent4, align: "center" });
  });
  txt(s, [{ text: "기준본 대비 ", options: {} }, hl("30.4배", { fontSize: 30 }), { text: " 빠르다  =  프로그램 14.75배 × CPU 구조 2.06배", options: {} }],
    { x: 0.6, y: 3.5, w: 12.1, h: 0.7, fontSize: 22, bold: true, valign: "middle" });
  const steps = [
    ["기준본", "단일 사이클 3.82 ns\n배포 프로그램 (57 word)", "8,135.69 cycle\nT 31.0783 µs"],
    ["프로그램 개선 ×14.75", "단일 사이클 3.82 ns\nint8_fastv2 (193 word)", "551.50 cycle\nT 2.1067 µs"],
    ["CPU 개선 ×2.06", "EX 파이프라인 1.62 ns\nint8_fastv2", "630.25 cycle\nT 1.0210 µs"],
  ];
  steps.forEach(([h, a, b], i) => {
    const x = 0.6 + i * 4.15;
    card(s, { x, y: 4.45, w: 3.75, h: 2.25, fill: { color: i === 2 ? C.text2 : C.background2 }, line: { color: i === 2 ? C.text2 : C.background2 } });
    const fg = i === 2 ? C.background1 : C.text1;
    txt(s, [
      { text: h, options: { bold: true, fontSize: 16, color: i === 2 ? C.accent3 : C.accent2, breakLine: true } },
      { text: a, options: { fontSize: 14, color: fg, breakLine: true } },
      { text: b, options: { fontSize: 16, bold: true, color: fg } },
    ], { x: x + 0.25, y: 4.6, w: 3.3, h: 2.0, paraSpaceAfter: 6 });
    if (i < 2) arrow(s, x + 3.78, 5.57, x + 4.12, 5.57);
  });
}

// ---------------------------------------------------------------- 4. 구조
pres.addSection({ title: "설계" });
{
  const s = content("설계: 고정 인터페이스와 5단 파이프라인", "피어리뷰 ① 설계 이해", "TOP은 CPU만 담고, 메모리는 수업이 제공하는 testbench 쪽에 있습니다. CPU는 PC를 내보내 IMEM에서 INSTR를 받고, MEM 단에서 ALURESULT·WRITEDATA·MEMWRITE로 DMEM에 쓰고 READDATA로 읽습니다. 예약 포트 40개는 계약대로 두었습니다. CORE 안은 IF·ID·EX·MEM·WB 5단이고, CONTROLLER는 ID 단에서 명령을 해독합니다.", "설계");
  s.addShape(pres.shapes.RECTANGLE, { x: 0.6, y: 1.4, w: 12.15, h: 4.65, fill: { color: C.background1 }, line: { color: C.accent3, width: 1, dashType: "dash" }, objectName: "tb-top" });
  txt(s, "TB_TOP (수업 제공, 수정 불가)", { x: 0.75, y: 1.52, w: 3.5, h: 0.3, fontSize: 12, color: C.accent4 });
  const box = (x, y, w, h, t, o) => s.addText(t, Object.assign({ shape: pres.shapes.ROUNDED_RECTANGLE, rectRadius: 0.06, x, y, w, h, fill: { color: C.background2 }, line: { color: C.accent3, width: 1 }, fontSize: 13, color: C.text1, align: "center", valign: "middle", isTextBox: true, margin: 2 }, o));
  box(0.9, 2.75, 1.8, 1.2, [{ text: "IMEM", options: { bold: true, breakLine: true } }, { text: "64/256/512 word", options: { fontSize: 11 } }]);
  box(0.9, 4.45, 1.8, 1.2, [{ text: "DMEM", options: { bold: true, breakLine: true } }, { text: "512 word", options: { fontSize: 11 } }]);
  s.addShape(pres.shapes.ROUNDED_RECTANGLE, { rectRadius: 0.06, x: 3.6, y: 1.6, w: 8.95, h: 4.3, fill: { color: C.background1 }, line: { color: C.text2, width: 1.5 }, objectName: "top" });
  txt(s, "TOP (합성 대상, 48 포트)", { x: 3.75, y: 1.7, w: 3.5, h: 0.3, fontSize: 12, bold: true, color: C.text2 });
  txt(s, "예약 입력 20개 = 0, 예약 출력 20개 미연결", { x: 8.0, y: 1.7, w: 4.4, h: 0.3, fontSize: 11, color: C.accent4, align: "right" });
  s.addShape(pres.shapes.ROUNDED_RECTANGLE, { rectRadius: 0.06, x: 3.9, y: 2.05, w: 8.4, h: 3.65, fill: { color: C.background1 }, line: { color: C.accent3, width: 1 }, objectName: "core" });
  txt(s, "CORE", { x: 4.0, y: 2.1, w: 1.0, h: 0.3, fontSize: 12, bold: true, color: C.text2 });
  const st = [["IF", "PC·인출"], ["ID", "해독·레지스터"], ["EX", "ALU·분기 판정"], ["MEM", "DMEM 접근"], ["WB", "레지스터 쓰기"]];
  st.forEach(([a, b], i) => box(4.2 + i * 1.6, 2.9, 1.35, 0.9, [{ text: a, options: { bold: true, fontSize: 15, breakLine: true } }, { text: b, options: { fontSize: 11 } }],
    i === 2 ? { fill: { color: C.text2 }, color: C.background1, line: { color: C.text2 } } : {}));
  for (let i = 0; i < 4; i++) arrow(s, 5.55 + i * 1.6, 3.35, 5.8 + i * 1.6, 3.35);
  box(5.55, 2.13, 1.9, 0.55, "CONTROLLER", { fontSize: 12, bold: true, fill: { color: C.background1 } });
  seg(s, 6.475, 2.68, 6.475, 2.9);
  // IMEM <-> IF
  arrow(s, 4.2, 3.1, 2.7, 3.1, "PC", { x: 3.0, y: 2.78, w: 1.0, h: 0.3 });
  arrow(s, 2.7, 3.6, 4.2, 3.6, "INSTR", { x: 3.0, y: 3.63, w: 1.0, h: 0.3 });
  // MEM <-> DMEM
  seg(s, 9.45, 3.8, 9.45, 4.7);
  arrow(s, 9.45, 4.7, 2.7, 4.7, "ALURESULT · WRITEDATA · MEMWRITE", { x: 3.0, y: 4.38, w: 4.5, h: 0.3 });
  seg(s, 2.7, 5.3, 10.0, 5.3);
  arrow(s, 10.0, 5.3, 10.0, 3.8, "READDATA", { x: 3.0, y: 5.33, w: 2.0, h: 0.3 });
  bullets(s, [
    "분기·JAL은 EX 단에서 판정. taken이면 IF·ID 두 명령을 버린다 (2 cycle)",
    "데이터 의존은 MEM·WB → EX 포워딩, lw 직후 사용만 1 cycle stall. 버블은 INSTR 0 → CONTROLLER가 ILLEGAL로 해독해 제어 신호 전부 0",
  ], { x: 0.6, y: 6.15, w: 12.1, h: 0.75, fontSize: 13, paraSpaceAfter: 2 });
}

// ---------------------------------------------------------------- 5. 제어 흐름 비교
{
  const s = content("세 CPU의 제어 흐름과 해저드 처리", "피어리뷰 ① 설계 이해", "같은 조건에서 세 CPU를 비교했습니다. 세 폴더는 CORE.v 한 파일만 다릅니다. 분기를 판정하는 단이 늦을수록 taken 분기 손실이 커지지만, 다음 장에서 보듯 주기가 짧아집니다. 구현하지 않은 명령은 모두 ILLEGAL로 처리해 상태를 바꾸지 않습니다.", "설계");
  const r = [
    [H(""), H("단일 사이클"), H("파이프라인 ID"), H("파이프라인 EX (선택)", { fill: { color: C.accent1 } })],
    ["분기·JAL 판정", "같은 cycle", "ID 단", "EX 단"],
    ["taken 분기·JAL 손실", "0", "1 cycle", "2 cycle"],
    ["lw 직후 사용", "0", "1 cycle stall (BEQ는 MEM의 load도 대기)", "1 cycle stall"],
    ["그 밖의 데이터 의존", "—", "포워딩, 0 cycle", "MEM·WB → EX 포워딩, 0 cycle"],
    ["분기 예측", "—", "없음 (항상 PC+4)", "없음 (항상 PC+4)"],
    ["불법·미구현 명령", "ILLEGAL=1, 상태 변경 없음", "같음", "같음 (버블도 이 경로)"],
    ["RESET", "동기 active-high, PC=0", "같음", "같음"],
    ["최소 통과 주기", "3.82 ns", "2.36 ns", hl("1.62 ns")],
  ];
  table(s, r.map((row, i) => row.map((c, j) => (typeof c === "string" ? { text: c, options: j === 0 ? { bold: true, color: C.accent4 } : {} } : c))),
    { x: 0.6, y: 1.5, w: 12.15, colW: [2.6, 2.9, 3.6, 3.05], rowH: 0.52, fontSize: 14 });
  txt(s, "세 폴더는 rtl/CORE.v만 다르다. TOP·CONTROLLER·TB·메모리·SDC·프로그램 HEX는 같다.", { x: 0.6, y: 6.4, w: 12.1, h: 0.4, fontSize: 13, color: C.accent4 });
}

// ---------------------------------------------------------------- 6. 프로그램
pres.addSection({ title: "개선" });
{
  const s = content("코드 변경 ①: 반복 덧셈 곱을 비트 직렬 곱으로", "피어리뷰 ④ 개선 근거", "기준 프로그램은 곱을 반복 덧셈으로 만들고 SCRATCH에 저장했다가 다시 읽습니다. 저희는 X의 비트를 하나씩 보고, 비트가 1이면 2의 k승배 된 W를 누산기에 더하는 비트 직렬 곱으로 바꿨습니다. 비트 검사 한 번을 출력 네 행이 같이 쓰는 것이 핵심입니다. 그 결과 단일 사이클에서 평균 cycle이 8135에서 551로 14.75배 줄었습니다.", "개선");
  bullets(s, [
    "기준본: 반복 덧셈 곱 + SCRATCH 저장·재로드",
    "X[i]의 비트 k가 1이면 네 누산기에 W[j][i]·2ᵏ을 더한다. 비트 7은 부호 비트라 뺀다",
    "2ᵏ은 add w,w,w로 매번 2배. 비트 검사 1번(and + beq)을 출력 4행이 같이 쓴다",
    "누산기를 BIAS로 시작해 SCRATCH를 쓰지 않는다 → case당 load 50 · store 5",
    "fast: 루프를 펼쳐 분기를 줄였다. 대가로 IMEM 256 구간",
    "v2: 같은 알고리즘에서 파이프라인이 버리는 cycle만 줄였다",
  ], { x: 0.6, y: 1.55, w: 5.6, h: 5.2, fontSize: 15 });
  const cats = ["기준본", "int8_small", "int8_opt64", "int8_opt64v2", "int8_fast", "int8_fastv2"];
  s.addChart(pres.charts.BAR, [{ name: "평균 cycle", labels: cats, values: cats.map((c) => CYC[c === "기준본" ? "baseline" : c][0]) }], {
    x: 6.5, y: 1.45, w: 6.25, h: 5.35, barDir: "bar", catAxisOrientation: "maxMin",
    chartColors: ["9AAFC2", "5E7387", "5E7387", "5E7387", "5E7387", "C4622D"],
    showTitle: true, title: "평균 cycle, 단일 사이클 CPU (공개 16 case)", titleFontSize: 14, titleColor: HX.dk1, titleFontFace: "+mn-lt",
    showValue: true, dataLabelPosition: "outEnd", dataLabelFormatCode: "#,##0.0", dataLabelFontSize: 12, dataLabelColor: HX.dk1, dataLabelFontFace: "+mn-lt",
    catAxisLabelFontSize: 12, catAxisLabelColor: HX.dk1, catAxisLabelFontFace: "+mn-lt",
    valAxisHidden: true, valGridLine: { style: "none" }, catGridLine: { style: "none" }, showLegend: false, valAxisMaxVal: 10000,
  });
}

// ---------------------------------------------------------------- 7. CPU 개선
{
  const s = content("코드 변경 ②: 주기를 정하는 경로와 RTL 개선", "피어리뷰 ④ 개선 근거", "setup 보고서에서 가장 느린 경로를 확인했습니다. 단일 사이클은 입력 지연과 출력 지연 1 ns씩이 한 경로에 들어가서 3.82 ns가 한계입니다. ID 판은 EX의 ALU 결과를 ID의 비교기로 포워딩해 같은 cycle에 PC를 정해야 해서 길어집니다. EX 판은 남은 경로가 분기 목표 덧셈기 하나입니다. 오른쪽 네 가지 개선은 cycle 수를 바꾸지 않고 경로만 줄였습니다.", "개선");
  txt(s, "가장 느린 경로 (setup 보고서)", { x: 0.6, y: 1.5, w: 6, h: 0.4, fontSize: 16, bold: true, color: C.accent2 });
  const paths = [
    ["단일 3.82 ns", "INSTR 입력 → 레지스터 읽기 → ALU 덧셈기 → ALURESULT 출력. 입출력 지연 1.00 ns씩 포함"],
    ["ID 2.36 ns", "MEM 결과 → EX 포워딩 → ALU → ID 비교기 → 분기 판정 → PC. 분기 손실 1 cycle의 대가"],
    ["EX 1.62 ns", "PCE 레지스터 → 분기 목표 덧셈기 → PC 선택"],
  ];
  paths.forEach(([a, b], i) => {
    const y = 2.0 + i * 1.3;
    card(s, { x: 0.6, y, w: 5.9, h: 1.15, fill: { color: i === 2 ? C.text2 : C.background2 }, line: { color: i === 2 ? C.text2 : C.background2 } });
    txt(s, [{ text: a, options: { bold: true, fontSize: 15, breakLine: true, color: i === 2 ? C.accent3 : C.text2 } }, { text: b, options: { fontSize: 13, color: i === 2 ? C.background1 : C.text1 } }],
      { x: 0.8, y: y + 0.1, w: 5.5, h: 0.98 });
  });
  txt(s, "cycle 수를 바꾸지 않은 개선 4가지", { x: 6.9, y: 1.5, w: 5.8, h: 0.4, fontSize: 16, bold: true, color: C.accent2 });
  const imp = [
    ["BEQ 같음 판정을 ALU와 병렬인 비교기로 (EX)", "분기 경로에서 뺄셈기 제거"],
    ["포워딩 select를 ID에서 미리 계산", "EX의 레지스터 번호 비교기 제거"],
    ["버블 때 제어 비트만 0", "flush·stall 신호의 팬아웃 축소"],
    ["result mux를 MEM 단으로", "WB 우회 경로 mux 제거, FF 66개 감소"],
  ];
  imp.forEach(([a, b], i) => {
    const y = 2.0 + i * 0.98;
    s.addText(String(i + 1), { shape: pres.shapes.OVAL, x: 6.9, y: y + 0.12, w: 0.5, h: 0.5, fill: { color: C.accent2 }, color: C.background1, bold: true, fontSize: 15, align: "center", valign: "middle", isTextBox: true, margin: 0 });
    txt(s, [{ text: a, options: { bold: true, fontSize: 14, breakLine: true } }, { text: b, options: { fontSize: 13, color: C.accent4 } }], { x: 7.6, y, w: 5.15, h: 0.85 });
  });
  txt(s, [{ text: "같은 R1.4 flow에서 개선 전 EX 2.30 ns → 1.62 ns, ID 3.00 ns → 2.36 ns.", options: { breakLine: true } }, { text: "개선 전 주기는 최소 주기를 찾기 전 값이라, 차이 전부가 RTL 효과는 아니다." }],
    { x: 0.6, y: 6.05, w: 12.15, h: 0.75, fontSize: 13, color: C.accent4 });
}

// ---------------------------------------------------------------- 8. 기준본 vs 개선본
pres.addSection({ title: "결과" });
{
  const s = content("같은 조건에서 기준본과 개선본의 T·A·P", "피어리뷰 ③ PPA 비교", "같은 단일 사이클 CPU와 같은 SDC에서 프로그램만 바꾼 것이 첫 단계, 같은 프로그램에서 CPU만 바꾼 것이 둘째 단계입니다. T는 30.4배 줄었고, 면적은 IMEM이 256 구간으로 커지고 파이프라인 레지스터가 늘어 29.4% 늘었습니다. 전력은 주파수가 2.36배 올라 늘었습니다.", "결과");
  const pend = BASE_P === null ? { text: "서버 측정 예정", options: { color: C.accent5, bold: true } } : f4(BASE_P);
  const r = [
    [H("단계"), H("CPU · 주기"), H("프로그램"), H("평균 cycle"), H("T (µs)"), H("A (µm²)"), H("P (mW)")],
    ["기준본", "단일 사이클 · 3.82 ns", "baseline (57 word)", f2(CYC.baseline[0]), f4(BASE_T), f2(A64[0]), pend],
    ["① 프로그램 개선", "단일 사이클 · 3.82 ns", "int8_fastv2 (193 word)", f2(CYC.int8_fastv2[0]), f4(T.int8_fastv2[0]), f2(A256[0]), f4(P.int8_fastv2[0])],
    [hl("② CPU 개선 (최종)"), hl("EX 파이프라인 · 1.62 ns"), hl("int8_fastv2"), hl(f2(CYC.int8_fastv2[2])), hl(f4(T.int8_fastv2[2])), hl(f2(A256[2])), hl(f4(P.int8_fastv2[2]))],
  ];
  table(s, r, { x: 0.6, y: 1.5, w: 12.15, colW: [1.95, 2.4, 2.35, 1.35, 1.2, 1.45, 1.45], rowH: 0.55, fontSize: 14, align: "center" });
  const k = [
    ["T", (BASE_T / T.int8_fastv2[2]).toFixed(1) + "배 빠름", "프로그램 14.75배 × CPU 구조 2.06배"],
    ["A", "+" + ((A256[2] / A64[0] - 1) * 100).toFixed(1) + "%", "IMEM 256 구간 +18,638.80, 파이프라인 레지스터 등 CPU +4,170.50 µm²"],
    ["P", (P.int8_fastv2[2] / P.int8_fastv2[0]).toFixed(2) + "배 (① 대비)", "주파수 2.36배라 CPU 전력도 2.70배"],
  ];
  k.forEach(([a, b, c], i) => {
    const x = 0.6 + i * 4.1;
    card(s, { x, y: 4.0, w: 3.85, h: 1.55 });
    txt(s, [{ text: a + "  ", options: { bold: true, fontSize: 18, color: C.accent2 } }, { text: b, options: { bold: true, fontSize: 22, color: C.text2, breakLine: true } }, { text: c, options: { fontSize: 13, color: C.text1 } }],
      { x: x + 0.25, y: 4.12, w: 3.4, h: 1.35, paraSpaceAfter: 6 });
  });
  txt(s, "기준본 A는 단일 사이클 3.82 ns 합성 결과(프로그램과 무관) + IMEM 64 + DMEM. 기준본 T는 공개 16 case 평균 cycle × 3.82 ns.", { x: 0.6, y: 5.8, w: 12.15, h: 0.6, fontSize: 12, color: C.accent4 });
}

// ---------------------------------------------------------------- 9. PPA 15 조합
{
  const s = content("PPA 15개 조합 (공식 flow, 공개 16 case)", "피어리뷰 ③ PPA 비교", "세 CPU와 다섯 프로그램 15개 조합을 모두 공식 flow로 쟀습니다. 왼쪽은 실행시간입니다. 어느 프로그램이든 EX가 가장 짧고, 어느 CPU든 fastv2가 가장 짧습니다. 오른쪽은 최종 프로그램 기준 세 CPU의 T·A·P입니다. 전체 표는 부록에 있습니다.", "결과");
  const colors = ["CBD5DE", "9AAFC2", "5E7387", "8CC3CC", "C4622D"];
  s.addChart(pres.charts.BAR, PROG.map((p) => ({ name: p, labels: ["단일 3.82 ns", "ID 2.36 ns", "EX 1.62 ns"], values: T[p] })), {
    x: 0.5, y: 1.4, w: 7.0, h: 5.45, barDir: "col", barGrouping: "clustered", barGapWidthPct: 60, chartColors: colors,
    showTitle: true, title: "실행시간 T (µs), 짧을수록 좋다", titleFontSize: 14, titleColor: HX.dk1, titleFontFace: "+mn-lt",
    showValue: false, catAxisLabelFontSize: 12, catAxisLabelColor: HX.dk1, catAxisLabelFontFace: "+mn-lt",
    valAxisLabelFontSize: 11, valAxisLabelColor: HX.accent4, valAxisLabelFontFace: "+mn-lt", valAxisLabelFormatCode: "0.0",
    valGridLine: { color: "E1E6EB", size: 0.75 }, catGridLine: { style: "none" },
    showLegend: true, legendPos: "b", legendFontSize: 11, legendColor: HX.dk1, legendFontFace: "+mn-lt",
  });
  const r = [
    [H("int8_fastv2"), H("단일"), H("ID"), H("EX", { fill: { color: C.accent1 } })],
    ["주기 (ns)", "3.82", "2.36", hl("1.62")],
    ["평균 cycle", ...CYC.int8_fastv2.map(f2)],
    ["T (µs)", f4(T.int8_fastv2[0]), f4(T.int8_fastv2[1]), hl(f4(T.int8_fastv2[2]))],
    ["A_CPU (µm²)", ...ACPU.map(f2)],
    ["A 전체 (µm²)", ...A256.map(f2)],
    ["P_CPU (mW)", ...PCPU_FASTV2.map(f4)],
    ["P 전체 (mW)", ...P.int8_fastv2.map(f4)],
  ];
  table(s, r.map((row) => row.map((c, j) => (typeof c === "string" ? { text: c, options: j === 0 ? { bold: true, color: C.accent4, align: "left" } : {} } : c))),
    { x: 7.75, y: 1.5, w: 5.0, colW: [1.55, 1.15, 1.15, 1.15], rowH: 0.5, fontSize: 13, align: "right" });
  txt(s, "A는 프로그램이 64 word 이하면 IMEM 64 구간이라 18,638.80 µm² 작다.", { x: 7.75, y: 5.75, w: 5.0, h: 0.8, fontSize: 12, color: C.accent4 });
}

// ---------------------------------------------------------------- 10. 트레이드오프
{
  const s = content("트레이드오프: 무엇을 얻고 무엇을 냈나", "피어리뷰 ⑥ 한계·trade-off", "네 가지 선택의 대가를 정리했습니다. ID 판은 cycle이 적지만 주기 경로가 길어서 집니다. fast는 IMEM이 커서 면적과 전력을 잃지만 T 가중치가 두 배라 선택했습니다. EX는 전력이 가장 크지만 한 번 실행 에너지는 비슷합니다. 면적은 메모리가 대부분이라 CPU 구조로는 거의 움직이지 않습니다.", "결과");
  const cards = [
    ["1.46×", "ID 판 주기 ÷ EX 판 주기", "ID는 cycle이 6.0% 적지만 주기가 45.7% 길어 T가 36.9% 길다. 원인은 ID의 'ALU → 비교기 → PC' 경로"],
    ["−18.9%", "fastv2의 T (opt64v2 대비, EX)", "대신 A +22.8%, P +30.0%. T 배점이 A·P의 2배라 fastv2. 표 안 점수 차는 0.62로 작다"],
    ["2.20×", "EX의 P ÷ 단일 사이클의 P", "주파수만큼 스위칭이 는다. 한 번 실행 에너지 P×T는 14.74 / 16.04 / 15.73 nJ로 비슷하다 (채점 항목 아님)"],
    ["77.8%", "전체 면적 중 메모리 몫 (EX + fastv2)", "CPU 구조를 바꿔도 A는 5% 안에서 움직인다. A를 줄이는 길은 64 word 안에 넣는 것"],
  ];
  cards.forEach(([big, k, d], i) => {
    const x = 0.6 + (i % 2) * 6.15, y = 1.55 + Math.floor(i / 2) * 2.45;
    card(s, { x, y, w: 5.95, h: 2.15 });
    txt(s, big, { x: x + 0.3, y: y + 0.2, w: 2.2, h: 0.8, fontSize: 32, bold: true, color: C.accent1, valign: "middle" });
    txt(s, k, { x: x + 2.55, y: y + 0.2, w: 3.2, h: 0.8, fontSize: 14, bold: true, color: C.text2, valign: "middle" });
    txt(s, d, { x: x + 0.3, y: y + 1.1, w: 5.4, h: 1.2, fontSize: 14 });
  });
}

// ---------------------------------------------------------------- 11. 기능 증거
pres.addSection({ title: "검증과 재현" });
{
  const s = content("기능 증거: Y·DONE과 검사 범위", "피어리뷰 ② 기능 증거", "왼쪽은 최종 조합의 서버 VCS 로그입니다. 16 case 모두 Y 네 개가 정답과 같고, 마지막 store로 DONE 토큰을 썼습니다. 오른쪽은 검사 범위입니다. 공식 flow 외에 로컬에서 ISA 모델과 store 하나하나를 비교했고, 실행 중 RESET, 해저드 시험, 무작위 프로그램 150개도 돌렸습니다.", "검증과 재현");
  const log = [
    "PASS CPU demo 624 cycles", "PASS CPU large_bias 624 cycles", "PASS CPU max_positive 682 cycles",
    "PASS CPU mixed_sign 622 cycles", "PASS CPU negative_extreme 586 cycles", "PASS CPU random_00 634 cycles",
    "   ...  random_01 ~ random_09", "PASS CPU zero_weights 624 cycles", "TOTAL CPU PASS 16/16.",
  ];
  card(s, { x: 0.6, y: 1.5, w: 5.6, h: 4.0, fill: { color: C.text2 }, line: { color: C.text2 } });
  txt(s, "서버 VCS · EX 1.62 ns · int8_fastv2", { x: 0.85, y: 1.62, w: 5.1, h: 0.35, fontSize: 13, bold: true, color: C.accent3 });
  txt(s, log.join("\n"), { x: 0.85, y: 2.05, w: 5.1, h: 2.85, fontSize: 13, fontFace: "Consolas", color: C.background1, lineSpacingMultiple: 1.1 });
  txt(s, "case마다 load 50 · store 5 (Y 4 + DONE 1)", { x: 0.85, y: 4.95, w: 5.1, h: 0.4, fontSize: 13, color: C.accent3 });
  const r = [
    [H("어디서"), H("무엇을"), H("결과")],
    ["서버 공식 flow", "15개 조합 × 공개 16 case", "모두 16/16, timing PASS"],
    ["로컬 ModelSim", "store 순서·주소·데이터·최종 DMEM을 ISA 모델과 비교. 실행 중 RESET, 해저드 시험, 무작위 프로그램 150개", "CPU마다 219/219"],
    ["로컬 ModelSim", "v2 프로그램 × 세 CPU × 16 case", "모두 PASS"],
    ["계약 검사", "TOP 48 포트, CPU RTL 3개, 공통 SDC", "통과"],
  ];
  table(s, r.map((row) => row.map((c) => (typeof c === "string" ? { text: c } : c))), { x: 6.5, y: 1.5, w: 6.25, colW: [1.45, 3.0, 1.8], fontSize: 13 });
  txt(s, "정답 조건: Y 4 word 일치 → 마지막 store가 DONE_ADDR ← DONE_TOKEN, 입력·설정 영역 훼손 없음, timeout 없음", { x: 6.5, y: 4.75, w: 6.25, h: 0.75, fontSize: 13, color: C.accent4 });
}

// ---------------------------------------------------------------- 12. 재현
{
  const s = content("재현 절차: 파일·명령·조건", "피어리뷰 ⑤ 재현 방법", "같은 결과를 다시 얻는 순서입니다. 수업 배포 R1.4 패키지에 R1.7 누적 업데이트를 풀고, CORE.v와 프로그램을 넣고, SDC의 주기 숫자 하나만 1.62로 바꿉니다. 그다음 run_sim.sh에 최종 HEX를 지정하고 run_ppa.sh를 돌리면 ppa_summary.json과, R1.6부터 제출이 필수인 계층 DDC가 같은 실행에서 나옵니다. R1.7 스크립트가 서버의 Python 3.12와 vcd2saif 경로를 스스로 잡습니다. reports/cpu_hierarchy.rpt로 CORE와 CONTROLLER 계층이 남았는지 확인합니다.", "검증과 재현");
  const steps = [
    ["R1.4 패키지에 R1.7 업데이트 적용 (R1.5·R1.6 포함)", "unzip -o ../Project1_R1p7_Update_20261112.zip"],
    ["어셈블 (HEX·LST 재생성)", "python3.12 tools/rv32i_assembler.py programs/int8_fastv2.s -o programs/int8_fastv2.hex --listing programs/int8_fastv2.lst"],
    ["주기 설정 (이 숫자만 바꾼다)", "synth/common.sdc:  create_clock -name CPU_CLK -period 1.62 ..."],
    ["기능 + activity (VCS)", "bash run_sim.sh --program programs/int8_fastv2.hex"],
    ["합성 · STA · 전력 · DDC (DC)", "bash run_ppa.sh   →  results/ppa_summary.json, results/TOP_mapped.ddc, reports/cpu_hierarchy.rpt"],
  ];
  steps.forEach(([a, b], i) => {
    const y = 1.5 + i * 0.86;
    s.addText(String(i + 1), { shape: pres.shapes.OVAL, x: 0.6, y: y + 0.1, w: 0.5, h: 0.5, fill: { color: C.accent2 }, color: C.background1, bold: true, fontSize: 15, align: "center", valign: "middle", isTextBox: true, margin: 0 });
    txt(s, a, { x: 1.3, y, w: 3.7, h: 0.7, fontSize: 14, bold: true, valign: "middle" });
    card(s, { x: 5.0, y: y + 0.03, w: 7.75, h: 0.64, fill: { color: C.text2 }, line: { color: C.text2 } });
    txt(s, b, { x: 5.15, y: y + 0.03, w: 7.5, h: 0.64, fontSize: 12, fontFace: "Consolas", color: C.background1, valign: "middle" });
  });
  card(s, { x: 0.6, y: 5.95, w: 12.15, h: 0.9 });
  txt(s, [
    { text: "조건  ", options: { bold: true, color: C.accent2 } },
    { text: "SAED32 RVT SS 0.95 V 125 °C · DC compile (compile_ultra 아님), R1.6·R1.7 Tcl은 CPU 계층 유지 · 공통 SDC · RESET=0 정상 모드 STA · 공개 16 case" , options: { breakLine: true } },
    { text: "R1.7 최종 실행 fingerprint e486b618…a2260 · DDC 416 KB · 측정 기록 measurements/R1p7_20261114", options: { color: C.accent4 } },
  ], { x: 0.85, y: 6.0, w: 11.7, h: 0.8, fontSize: 13, valign: "middle" });
}

// ---------------------------------------------------------------- 13. 한계와 질의응답
{
  const s = content("한계와 예상 질문", "피어리뷰 ⑥ 한계·trade-off", "한계부터 말씀드리면, 숫자는 공개 16 case 기준이고 타이밍 여유가 수 ps라 RTL을 고치면 주기를 다시 찾아야 합니다. 선택 명령을 쓰면 루프 분기를 더 줄일 여지도 남아 있습니다. 오른쪽은 예상 질문과 답입니다.", "검증과 재현");
  txt(s, "한계", { x: 0.6, y: 1.5, w: 5.6, h: 0.4, fontSize: 16, bold: true, color: C.accent2 });
  bullets(s, [
    "숫자는 공개 16 case. 공식 성적은 숨김 8 case를 더한 24 case로 따로 나온다",
    "setup 여유가 EX 2.6 ps. RTL을 한 줄이라도 고치면 주기를 다시 찾는다",
    "통과 주기가 단조롭지 않다 (EX 1.64 실패, 1.62 통과). 합성이 주기마다 다른 회로를 만든다",
    "전력은 배치·배선 전 추정, 메모리 전력은 수업용 산식",
    "선택 명령(BNE 등)은 쓰지 않았다. 루프 분기를 더 줄일 여지가 있다",
    "R1.6·R1.7 Tcl(CPU 계층 유지)로 다시 돌려도 T·A·P·slack이 R1.4 Tcl 값과 같았다. 제출 DDC는 R1.7 실행의 것",
  ], { x: 0.6, y: 2.0, w: 5.6, h: 4.8, fontSize: 14 });
  const qa = [
    ["왜 ID가 아니라 EX인가?", "cycle은 ID가 6% 적지만 T는 EX가 36.9% 짧다 (주기 경로)"],
    ["왜 IMEM 256 구간 프로그램인가?", "T −18.9%가 A +22.8%, P +30.0%보다 크다 (배점 2:1:1)"],
    ["MUL을 쓰면 더 빠르지 않나?", "M 확장은 금지. 비트 직렬 곱이 곱셈기를 대신한다"],
    ["1.62 ns를 믿을 수 있나?", "같은 RTL·flow면 결정적이다. R1.4 두 번, R1.6·R1.7 각 한 번 모두 slack +2.6 ps"],
  ];
  qa.forEach(([q, a], i) => {
    const y = 1.5 + i * 1.2;
    card(s, { x: 6.6, y, w: 6.15, h: 1.0 });
    txt(s, [{ text: "Q. " + q, options: { bold: true, fontSize: 14, color: C.text2, breakLine: true } }, { text: "A. " + a, options: { fontSize: 13 } }], { x: 6.85, y: y + 0.1, w: 5.75, h: 0.82 });
  });
}

// ---------------------------------------------------------------- 14. 정리
{
  const s = pres.addSlide({ masterName: "COVER", sectionTitle: "검증과 재현" });
  s.addText("정리", { placeholder: "title" });
  s.addText([
    { text: "EX 분기 5단 파이프라인 + int8_fastv2, 1.62 ns: T 1.0210 µs, 공개 16/16 PASS", options: { bullet: true, breakLine: true } },
    { text: "기준본 대비 30.4배 = 비트 직렬 곱(14.75배) × 파이프라인과 경로 단축(2.06배)", options: { bullet: true, breakLine: true } },
    { text: "대가: 면적 +29.4%, 전력 증가. T 가중치 2배라 이 선택이 점수에 유리", options: { bullet: true, breakLine: true } },
    { text: "R1.7 공통 flow 재실행에서 같은 수치, 계층 DDC(CORE·CONTROLLER) 생성", options: { bullet: true } },
  ], { placeholder: "body", paraSpaceAfter: 10 });
  s.addNotes("정리하겠습니다. 최종 조합은 EX 분기 파이프라인과 int8_fastv2, 1.62 ns이고 기준본 대비 30.4배 빠릅니다. 면적과 전력은 늘었지만 실행시간 가중치가 두 배라서 이 선택을 했습니다. 질문 받겠습니다.");
  n++;
}

// ---------------------------------------------------------------- 부록
pres.addSection({ title: "부록" });
{
  const s = content("부록 A. PPA 15개 조합 전체", "부록", "발표에서 질문이 나오면 보여 줄 전체 표입니다. 표 안 점수는 이 15행끼리만 비교한 값이라 실제 점수가 아닙니다.", "부록");
  const r = [[H("CPU"), H("프로그램"), H("주기"), H("평균 cycle"), H("T (µs)"), H("A (µm²)"), H("P (mW)"), H("표 안 점수")]];
  CPU.forEach((c, ci) => PROG.forEach((p) => {
    const best = ci === 2 && p === "int8_fastv2";
    const cell = (t, al) => { const o = al ? { align: al } : {}; return best ? hl(t, o) : { text: t, options: o }; };
    r.push([cell(c, "left"), cell(p, "left"), cell(PERIOD[ci].toFixed(2)), cell(f2(CYC[p][ci])), cell(f4(T[p][ci])), cell(f2(area(p, ci))), cell(f4(P[p][ci])), cell(SCORE[p][ci].toFixed(2))]);
  }));
  table(s, r, { x: 0.6, y: 1.35, w: 12.15, colW: [1.9, 1.9, 0.9, 1.6, 1.4, 1.7, 1.35, 1.4], rowH: 0.33, fontSize: 12, align: "right" });
  txt(s, "표 안 점수 = 12.5·T_best/T + 6.25·A_best/A + 6.25·P_best/P (이 15행 기준). 실제 점수는 다른 팀 최솟값이 기준이라 다르다.", { x: 0.6, y: 6.7, w: 11.4, h: 0.3, fontSize: 11, color: C.accent4 });
}
{
  const s = content("부록 B. 주기 탐색 (공식과 같은 compile, 0.02 ns 간격)", "부록", "후보 주기마다 공식 스크립트와 같은 순서로 합성해 setup과 hold가 모두 0 이상인 가장 짧은 주기를 골랐습니다. 통과가 주기 순서대로 나오지 않는 것은 합성이 목표 주기마다 다른 회로를 만들기 때문입니다.", "부록");
  const sw = {
    "단일 사이클": [["3.90", "0.0005"], ["3.88", "0.0020"], ["3.86", "-0.0020"], ["3.84", "-0.0037"], ["3.82", "0.0008"], ["3.80", "-0.0000"]],
    "파이프라인 ID": [["2.40", "0.0016"], ["2.38", "0.0008"], ["2.36", "0.0003"], ["2.34", "-0.0006"], ["2.32", "-0.0055"], ["2.30", "-0.0019"]],
    "파이프라인 EX": [["1.70", "0.0031"], ["1.68", "0.0007"], ["1.66", "0.0002"], ["1.64", "-0.0014"], ["1.62", "0.0026"], ["1.60", "-0.0000"]],
  };
  const pick = ["3.82", "2.36", "1.62"];
  Object.entries(sw).forEach(([name, rows], i) => {
    const x = 0.6 + i * 4.1;
    txt(s, name, { x, y: 1.45, w: 3.85, h: 0.4, fontSize: 15, bold: true, color: C.accent2 });
    const t = [[H("주기 (ns)"), H("setup slack (ns)"), H("판정")]].concat(rows.map(([p, sl]) => {
      const ok = !sl.startsWith("-");
      const o = p === pick[i] ? { bold: true, fill: { color: C.background2 } } : {};
      return [{ text: p, options: o }, { text: sl.replace("-", "−"), options: o }, { text: ok ? "통과" : "실패", options: Object.assign({}, o, { color: ok ? C.accent6 : C.accent1, bold: true }) }];
    }));
    table(s, t, { x, y: 1.95, w: 3.85, colW: [1.15, 1.6, 1.1], rowH: 0.48, fontSize: 13, align: "center" });
  });
  bullets(s, [
    "1차 탐색(0.05~0.30 ns 간격)의 최소 통과 주기 3.90 / 2.40 / 1.70 ns 아래를 다시 찾았다. 음영이 고른 주기",
    "hold slack은 모든 주기에서 0.1030 ns 이상. 고른 주기의 공식 flow slack은 탐색 값과 소수 넷째 자리까지 같았다",
    "주기는 소수 둘째 자리까지만 쓴다 (TB 시간 단위 1 fs, cycle × 주기 = 실행 구간 검사)",
  ], { x: 0.6, y: 5.45, w: 12.15, h: 1.4, fontSize: 13, paraSpaceAfter: 4 });
}
{
  const s = content("부록 C. 프로그램별 크기와 cycle", "부록", "프로그램 여섯 개의 크기와 세 CPU에서의 평균 cycle입니다. v2는 분기가 많은 opt64에서 효과가 컸습니다.", "부록");
  const r = [[H("프로그램"), H("word"), H("IMEM"), H("단일"), H("ID"), H("EX"), H("v2로 줄어든 cycle (EX)")]];
  ["baseline", ...PROG].forEach((p) => {
    const red = p === "int8_opt64v2" ? "−5.4% (opt64 대비)" : p === "int8_fastv2" ? "−0.9% (fast 대비)" : "";
    r.push([p === "baseline" ? "기준본 baseline" : p, String(WORDS[p]), WORDS[p] > 64 ? "256" : "64", ...CYC[p].map(f2), red].map((t, j) => ({ text: t, options: j === 0 ? { align: "left" } : {} })));
  });
  table(s, r, { x: 0.6, y: 1.5, w: 12.15, colW: [2.4, 0.95, 0.95, 1.75, 1.75, 1.75, 2.6], rowH: 0.5, fontSize: 13, align: "right" });
  bullets(s, [
    "opt64v2: 다음 비트가 0이면 JAL을 건너뛰고, 음수 X의 부호 처리 뒤 JAL을 없앴다 (63 word, IMEM 64 유지)",
    "fastv2: lw 직후 사용 stall을 없애고 설정 명령 1개를 줄였다 (193 word)",
    "두 v2 모두 분기 뒤에 잘못 인출되는 lw/sw가 메모리 접근으로 세어지지 않게 채움 명령을 넣었다",
    "기준본 cycle은 로컬 시뮬레이션 값 (서버 기준본 측정은 예정)",
  ], { x: 0.6, y: 5.25, w: 12.15, h: 1.6, fontSize: 13, paraSpaceAfter: 4 });
}
{
  const s = content("부록 D. 제출물 구성 (R1.5~R1.7 지침)", "부록", "R1.5~R1.7 공지에 따른 제출물 구성입니다. R1.6부터 results/TOP_mapped.ddc가 필수이고, 최종 PPA를 잰 바로 그 실행에서 나온 DDC와 측정 결과를 냅니다. 이 슬라이드 파일 자체가 presentation/project1.pptx로 들어갑니다. 선택 명령은 쓰지 않았으므로 단독 기능 시험 대상이 없습니다.", "부록");
  card(s, { x: 0.6, y: 1.5, w: 5.4, h: 4.45, fill: { color: C.text2 }, line: { color: C.text2 } });
  txt(s, [
    "TEAM_ID/", "  README.txt", "  rtl/TOP.v  CORE.v  CONTROLLER.v", "  asm/int8_fastv2.s  .hex  .lst", "  synth/common.sdc (1.62)  rtl.f",
    "  tools/  (Python 3.6용 공식 도구 3개)", "  run/reproduce.sh",
    "  results/ppa_summary.json  ppa_status.json", "          simulation_manifest.json", "          TOP_mapped.ddc   ← R1.6 필수", "          TOP_mapped.v  TOP_normal_mode.sdc",
    "  reports/ setup hold cpu_area", "          cpu_hierarchy  case별 power", "  logs/    compile  case 16개  dc_ppa", "  presentation/project1.pptx  .pdf",
  ].join("\n"), { x: 0.8, y: 1.62, w: 5.1, h: 4.2, fontSize: 11.5, fontFace: "Consolas", color: C.background1, lineSpacingMultiple: 1.1 });
  bullets(s, [
    "발표 슬라이드 1부 (PPTX 또는 PDF). 서술형 보고서는 내지 않는다",
    "RTL, 어셈블리 원본 .s, 재생성한 .hex·.lst",
    "기능 로그, STA·CPU area·CPU power 도구 출력, 선언 주파수 617.28 MHz",
    "실행 cycle과 load/store 횟수, IMEM 용량 (193 word → 256 구간)",
    "사용한 선택 RV32I 명령: 없음 (기본 8개만). 그래서 단독 기능 시험 대상 없음",
    "R1.6: 계층 DDC results/TOP_mapped.ddc 필수. CORE·CONTROLLER 계층을 reports/cpu_hierarchy.rpt로 확인하고, 같은 실행의 DDC와 측정 결과를 낸다",
    "재현 절차 (슬라이드 12와 같은 명령)",
  ], { x: 6.35, y: 1.5, w: 6.4, h: 5.3, fontSize: 14 });
}

{
  const s = content("부록 E. 수업 명령만으로 서버에서 재현", "피어리뷰 ⑤ 재현 방법", "공식 스크립트가 안에서 하는 일을 수업에서 쓴 명령으로 풀어 쓴 순서입니다. vcs_queue로 컴파일하고 simv로 16 case를 돌린 뒤, 배포 도구로 실행 구간 VCD를 자르고 vcd2saif로 SAIF를 만듭니다. 그다음 dc_shell_queue를 열어 W06·W07 실습처럼 analyze, elaborate, compile, report를 차례로 입력하고, case마다 read_saif와 report_power를 합니다. 마지막에 awk로 T, A, P를 계산하면 공식 결과와 같은 1.021005 µs, 100,342.97 µm², 15.4104 mW가 나옵니다.", "부록");
  const steps = [
    ["1 컴파일 (VCS)", "vcs_queue -full64 -timescale=1ns/1fs -top TB_TOP -f synth/rtl.f \\\n  sim/mem/IMEM.v sim/mem/DMEM.v sim/MEMORY_POWER.v sim/TB_TOP.v -o build/simv -l logs/compile.log"],
    ["2 16 case 실행", "for f in cases/*.json; do c=$(basename $f .json)\n  ./build/simv +PROGRAM=programs/int8_fastv2.hex +DATA=cases/${c}_dmem.hex +EXPECTED=cases/${c}_expected.hex \\\n    +F_MHZ=617.283950617 +VCD=build/$c.raw.vcd -l logs/$c.log; done"],
    ["3 실행 구간 → SAIF", "trim_vcd.py(배포 도구)로 로그의 ACTIVE_WINDOW 구간만 남김\n→ vcd2saif -input build/$c.active.vcd -output build/$c.saif"],
    ["4 합성·STA (DC)", "dc_shell_queue → source synth/library_setup.tcl · saif_map -start · analyze · elaborate TOP · link\n→ source synth/common.sdc · set_ungroup … false · compile · write_file -format ddc -hierarchy · report_hierarchy\n→ set_case_analysis 0 [get_ports RESET] · report_area · report_timing -delay_type max / min"],
    ["5 전력 (DC)", "foreach c $P1_CASES { reset_switching_activity\n  read_saif -input build/$c.saif -instance_name TB_TOP/dut -auto_map_names; report_power > reports/$c/power.rpt }"],
    ["6 T·A·P 계산", "case별 cycle·load·store(logs)와 CPU 전력(power.rpt)을 awk로 cycle 가중 평균 + 메모리 산식\n→ T 1.021005 µs · A 100,342.97 µm² · P 15.4104 mW (공식 결과와 같음)"],
  ];
  steps.forEach(([a, b], i) => {
    const y = 1.45 + i * 0.88;
    txt(s, a, { x: 0.6, y, w: 2.2, h: 0.8, fontSize: 13, bold: true, color: C.accent2, valign: "middle" });
    card(s, { x: 2.85, y, w: 9.9, h: 0.8, fill: { color: C.text2 }, line: { color: C.text2 } });
    txt(s, b, { x: 3.0, y, w: 9.65, h: 0.8, fontSize: 10, fontFace: "Consolas", color: C.background1, valign: "middle" });
  });
  txt(s, "전체 명령: 팀원용 HTML \"서버에서 재현\" · 공식 2줄 판은 슬라이드 12", { x: 0.6, y: 6.68, w: 12.15, h: 0.35, fontSize: 11, color: C.accent4 });
}

(async () => {
  await pres.writeFile({ fileName: OUT });
  // 한글 단어 중간 줄바꿈 막기: 글자 언어를 한국어로 표시하고, 모든 문단에 eaLnBrk="0"
  const JSZip = require(require.resolve("jszip", { paths: [require.resolve("pptxgenjs")] }));
  const fs = require("fs");
  const zip = await JSZip.loadAsync(fs.readFileSync(OUT));
  for (const name of Object.keys(zip.files).filter((f) => /^ppt\/slides\/slide\d+\.xml$/.test(f))) {
    let x = await zip.file(name).async("string");
    x = x.replace(/lang="en-US"/g, 'lang="ko-KR" altLang="en-US"').replace(/<a:pPr(?![^>]*eaLnBrk)/g, '<a:pPr eaLnBrk="0"').replace(/<a:p>(?!<a:pPr)/g, '<a:p><a:pPr eaLnBrk="0"/>');
    zip.file(name, x);
  }
  fs.writeFileSync(OUT, await zip.generateAsync({ type: "nodebuffer", compression: "DEFLATE" }));
  if (APPLY_THEME) await require(require("path").resolve(APPLY_THEME)).applyTheme(OUT, THEME);
  console.log("wrote", OUT, n, "slides");
})();
