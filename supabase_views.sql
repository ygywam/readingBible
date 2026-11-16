-- ========================================================
-- 회정교회 성경 대행진: 초고속 랭킹 조회를 위한 통계 뷰 (View)
-- (비정상 초과 장수 클램핑 방어 코드 적용 완료)
-- ========================================================

-- 1. 성도별 성경 책별 진행 요약 뷰 (초과 장수 클램핑 적용)
CREATE OR REPLACE VIEW bible_user_book_summary AS
SELECT 
    l.name, 
    l.team, 
    l.book, 
    MAX((l.lap - 1) * b.total_chapters + LEAST(l.chapter, b.total_chapters)) as max_read_chapters,
    MAX(l.read_at) as last_read_at
FROM bible_read_logs l
JOIN bible_books b ON l.book = b.book_name
GROUP BY l.name, l.team, l.book;

-- 2. 개인별 순위 랭킹 뷰
CREATE OR REPLACE VIEW bible_view_individual_rankings AS
SELECT 
    s.name,
    s.team,
    SUM(s.max_read_chapters)::int as "totalScore",
    ROUND((SUM(s.max_read_chapters)::numeric / 1189.0) * 100, 1) as percent,
    FLOOR(SUM(s.max_read_chapters)::numeric / 1189.0)::int + 1 as lap,
    (
        SELECT sub.book 
        FROM bible_user_book_summary sub 
        WHERE sub.name = s.name AND sub.team = s.team 
        ORDER BY sub.last_read_at DESC LIMIT 1
    ) as "currentBook",
    (
        SELECT 
            CASE 
                WHEN (sub.max_read_chapters % b.total_chapters) = 0 THEN b.total_chapters 
                ELSE (sub.max_read_chapters % b.total_chapters) 
            END
        FROM bible_user_book_summary sub 
        JOIN bible_books b ON sub.book = b.book_name
        WHERE sub.name = s.name AND sub.team = s.team 
        ORDER BY sub.last_read_at DESC LIMIT 1
    ) as "currentChapter"
FROM bible_user_book_summary s
GROUP BY s.name, s.team
ORDER BY "totalScore" DESC;

-- 3. 소그룹 대항전 랭킹 뷰
CREATE OR REPLACE VIEW bible_view_team_rankings AS
WITH member_counts AS (
    SELECT team, COUNT(*)::int as "memberCount"
    FROM bible_members
    GROUP BY team
),
team_sums AS (
    SELECT 
        team, 
        SUM("totalScore") as sum_score
    FROM bible_view_individual_rankings
    GROUP BY team
)
SELECT 
    m.team,
    m."memberCount",
    ROUND(((COALESCE(t.sum_score, 0)::numeric / GREATEST(m."memberCount", 1)) / 1189.0) * 100, 1) as "totalPercent",
    CASE 
        WHEN ((COALESCE(t.sum_score, 0)::numeric / GREATEST(m."memberCount", 1)) / 1189.0) * 100 > 0 
             AND (ROUND(((COALESCE(t.sum_score, 0)::numeric / GREATEST(m."memberCount", 1)) / 1189.0) * 100, 1) % 100) = 0 THEN 100
        ELSE (ROUND(((COALESCE(t.sum_score, 0)::numeric / GREATEST(m."memberCount", 1)) / 1189.0) * 100, 1) % 100)
    END as "displayPercent",
    FLOOR(((COALESCE(t.sum_score, 0)::numeric / GREATEST(m."memberCount", 1)) / 1189.0))::int + 1 as lap
FROM member_counts m
LEFT JOIN team_sums t ON m.team = t.team
ORDER BY "totalPercent" DESC;

-- 4. 뷰에 대한 anon 조회 권한 부여
GRANT SELECT ON bible_user_book_summary TO anon, authenticated;
GRANT SELECT ON bible_view_individual_rankings TO anon, authenticated;
GRANT SELECT ON bible_view_team_rankings TO anon, authenticated;
