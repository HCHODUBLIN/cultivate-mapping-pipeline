#!/bin/bash
# =============================================================
# Snowflake 전용 SQL 스캔 스크립트
# 프로젝트 루트에서 실행하세요: bash infra/scripts/check_snowflake_sql.sh
# =============================================================

echo "=============================================="
echo "🔍 Snowflake 전용 SQL 스캔 시작"
echo "=============================================="
echo ""

# 스캔 대상 디렉토리 (models + snowflake)
DIRS="models snowflake"
FOUND=0
CRITICAL=0

# 함수별 스캔
scan_pattern() {
  local name="$1"
  local pattern="$2"
  local desc="$3"
  local is_critical="$4"

  local count=0
  for dir in $DIRS; do
    if [ -d "$dir" ]; then
      local result=$(grep -rni "$pattern" "$dir" --include="*.sql" 2>/dev/null | wc -l)
      count=$((count + result))
    fi
  done

  if [ $count -gt 0 ]; then
    printf "  %-25s %3d건  — %s\n" "$name" "$count" "$desc"
    FOUND=$((FOUND + count))
    if [ "$is_critical" = "1" ]; then
      CRITICAL=$((CRITICAL + count))
    fi
  fi
}

echo "스캔 대상: $DIRS"
echo ""

# JSON/반정형 데이터 (critical)
scan_pattern "FLATTEN" '\bFLATTEN\b' "반정형 데이터 펼치기" 1
scan_pattern "LATERAL FLATTEN" 'LATERAL[[:space:]]*FLATTEN' "LATERAL FLATTEN 구문" 1
scan_pattern "PARSE_JSON" '\bPARSE_JSON\b' "JSON 파싱" 1
scan_pattern "TRY_PARSE_JSON" '\bTRY_PARSE_JSON\b' "안전한 JSON 파싱" 1
scan_pattern "OBJECT_CONSTRUCT" '\bOBJECT_CONSTRUCT\b' "JSON 객체 생성" 1
scan_pattern "ARRAY_CONSTRUCT" '\bARRAY_CONSTRUCT\b' "배열 생성" 0
scan_pattern "GET_PATH" '\bGET_PATH\b' "JSON 경로 접근" 0

# 타입 변환
scan_pattern "TRY_TO_NUMBER" '\bTRY_TO_NUMBER\b' "안전한 숫자 변환" 0
scan_pattern "TRY_TO_DATE" '\bTRY_TO_DATE\b' "안전한 날짜 변환" 0
scan_pattern "TRY_TO_TIMESTAMP" '\bTRY_TO_TIMESTAMP\b' "안전한 타임스탬프 변환" 0
scan_pattern "TRY_CAST" '\bTRY_CAST\b' "안전한 타입 변환" 0
scan_pattern "TO_VARIANT" '\bTO_VARIANT\b' "VARIANT 타입 변환" 1

# 문자열
scan_pattern "SPLIT_PART" '\bSPLIT_PART\b' "문자열 분리" 0
scan_pattern "STRTOK_TO_ARRAY" '\bSTRTOK_TO_ARRAY\b' "문자열→배열 분리" 0

# 날짜/시간
scan_pattern "DATEADD" '\bDATEADD\b' "날짜 더하기" 0
scan_pattern "DATEDIFF" '\bDATEDIFF\b' "날짜 차이" 0

# Snowflake 고유 구문 (critical)
scan_pattern "GENERATOR" '\bGENERATOR\b' "행 생성기" 1
scan_pattern "COPY INTO" 'COPY[[:space:]]*INTO' "데이터 로딩" 1
scan_pattern "MERGE INTO" 'MERGE[[:space:]]*INTO' "MERGE 구문" 0
scan_pattern "CREATE OR REPLACE" 'CREATE[[:space:]]*OR[[:space:]]*REPLACE' "CREATE OR REPLACE" 0
scan_pattern "QUALIFY" '\bQUALIFY\b' "윈도우 함수 필터" 0

# 타입 캐스팅 (::)
for dir in $DIRS; do
  if [ -d "$dir" ]; then
    count=$(grep -rn '::[A-Z]' "$dir" --include="*.sql" 2>/dev/null | wc -l)
    if [ $count -gt 0 ]; then
      printf "  %-25s %3d건  — %s\n" "::" "$count" "타입 캐스팅 (value::TYPE)"
      FOUND=$((FOUND + count))
    fi
  fi
done

echo ""
echo "=============================================="
echo "📊 스캔 결과 요약"
echo "=============================================="
echo ""
echo "총 발견: $FOUND건"
echo "Critical (DuckDB 미지원): $CRITICAL건"
echo ""

if [ $CRITICAL -gt 10 ]; then
  echo "🔴 Snowflake 전용 구문 많음 → Snowflake CI 환경 권장"
  echo "   DuckDB CI는 seed/단순 모델만 적용 가능"
elif [ $CRITICAL -gt 0 ]; then
  echo "🟡 일부 Snowflake 전용 구문 있음 → 하이브리드 추천"
  echo "   DuckDB: seed + 표준 SQL 모델"
  echo "   Snowflake: 전용 함수가 포함된 모델"
elif [ $FOUND -gt 0 ]; then
  echo "🟢 호환 가능한 수준 → DuckDB CI 적용 가능"
  echo "   일부 함수명만 조정하면 DuckDB로 전환 가능"
else
  echo "✅ Snowflake 전용 함수 없음 → DuckDB CI 매우 적합"
fi

echo ""
echo "=============================================="
