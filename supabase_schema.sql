-- ========================================================
-- 회정교회 성경 대행진 웹앱: Supabase 초기 스키마 (5개 테이블)
-- ========================================================

-- 1. 성도 회원명부 테이블 (기존 '회원명부')
CREATE TABLE IF NOT EXISTS bible_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    team TEXT NOT NULL,
    password TEXT,
    status TEXT DEFAULT '미가입', -- '가입완료' / '미가입'
    role TEXT DEFAULT 'member',   -- 'admin' / 'member'
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(name, team)
);

-- 2. 성경 읽기 기록 로그 테이블 (기존 '설문지 응답 시트1')
CREATE TABLE IF NOT EXISTS bible_read_logs (
    id BIGSERIAL PRIMARY KEY,
    read_at TIMESTAMPTZ DEFAULT NOW(),
    name TEXT NOT NULL,
    team TEXT NOT NULL,
    book TEXT NOT NULL,
    chapter INT NOT NULL,
    lap INT DEFAULT 1,            -- 1독, 2독 등
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(name, team, book, chapter, lap)
);

-- 초고속 조회를 위한 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_bible_read_logs_user ON bible_read_logs (name, team);
CREATE INDEX IF NOT EXISTS idx_bible_read_logs_team ON bible_read_logs (team);
CREATE INDEX IF NOT EXISTS idx_bible_read_logs_date ON bible_read_logs (read_at);

-- 3. 오늘의 묵상 나눔 테이블 (기존 '묵상나눔')
CREATE TABLE IF NOT EXISTS bible_devotions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    name TEXT NOT NULL,
    team TEXT NOT NULL,
    read_range TEXT,
    content TEXT,
    likes TEXT[] DEFAULT ARRAY[]::TEXT[], -- 좋아요 누른 성도 이름 배열
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(date, name)
);

-- 4. 관리자 공지사항 테이블 (기존 '공지사항')
CREATE TABLE IF NOT EXISTS bible_notices (
    id SERIAL PRIMARY KEY,
    status TEXT DEFAULT 'OFF',
    title TEXT,
    content TEXT,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 기본 단일 레코드 삽입
INSERT INTO bible_notices (id, status, title, content) 
VALUES (1, 'OFF', '', '')
ON CONFLICT (id) DO NOTHING;

-- 5. 성경 66권 기본 메타데이터 테이블 (기존 '성경데이터')
CREATE TABLE IF NOT EXISTS bible_books (
    id SERIAL PRIMARY KEY,
    book_order INT NOT NULL,
    testament TEXT NOT NULL,        -- '구약' / '신약'
    book_name TEXT NOT NULL UNIQUE, -- '창세기', '출애굽기' ...
    total_chapters INT NOT NULL     -- 총 장수
);

-- ========================================================
-- RLS (보안 정책) 활성화 및 웹앱 접근 허용 정책
-- ========================================================
ALTER TABLE bible_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE bible_read_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE bible_devotions ENABLE ROW LEVEL SECURITY;
ALTER TABLE bible_notices ENABLE ROW LEVEL SECURITY;
ALTER TABLE bible_books ENABLE ROW LEVEL SECURITY;

-- 웹앱에서 자유롭게 데이터 조회/입력/수정/삭제가 가능하도록 정책 부여
DROP POLICY IF EXISTS "Allow public all on bible_members" ON bible_members;
CREATE POLICY "Allow public all on bible_members" ON bible_members FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow public all on bible_read_logs" ON bible_read_logs;
CREATE POLICY "Allow public all on bible_read_logs" ON bible_read_logs FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow public all on bible_devotions" ON bible_devotions;
CREATE POLICY "Allow public all on bible_devotions" ON bible_devotions FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow public all on bible_notices" ON bible_notices;
CREATE POLICY "Allow public all on bible_notices" ON bible_notices FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow public all on bible_books" ON bible_books;
CREATE POLICY "Allow public all on bible_books" ON bible_books FOR ALL USING (true) WITH CHECK (true);
