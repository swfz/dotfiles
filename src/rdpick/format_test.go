package main

import (
	"encoding/json"
	"strings"
	"testing"
)

func TestFormatMarkdown(t *testing.T) {
	tests := []struct {
		name       string
		items      []RaindropItem
		total      int
		search     string
		collection int
		sort       string
		wantLines  []string
		notWant    []string
	}{
		{
			name:       "基本ケース",
			search:     "可観測性",
			total:      87,
			collection: 0,
			sort:       "score",
			items: []RaindropItem{
				{
					Title:   "SLOの決め方",
					Link:    "https://example.com/slo",
					Tags:    []string{"sre", "slo"},
					Domain:  "example.com",
					Created: "2026-01-02T03:04:05.000Z",
					Excerpt: "エラーバジェットの考え方は...",
				},
			},
			wantLines: []string{
				"# Query: 可観測性",
				"Fetched 1 of 87 matches (collection: 0, sort: score)",
				"- [SLOの決め方](https://example.com/slo)",
				"  - tags: sre, slo",
				"  - domain: example.com / created: 2026-01-02",
				"  - excerpt: エラーバジェットの考え方は...",
			},
		},
		{
			name: "excerptとnoteが空なら行を出さない",
			items: []RaindropItem{
				{Title: "t", Link: "https://example.com", Domain: "example.com", Created: "2026-01-02T00:00:00.000Z"},
			},
			notWant: []string{"excerpt:", "note:", "tags:"},
		},
		{
			name: "noteがあれば行を出す",
			items: []RaindropItem{
				{Title: "t", Link: "https://example.com", Domain: "example.com", Created: "2026-01-02T00:00:00.000Z", Note: "メモ内容"},
			},
			wantLines: []string{"  - note: メモ内容"},
		},
		{
			name: "excerptの改行は空白に畳んで1行にする",
			items: []RaindropItem{
				{Title: "t", Link: "https://example.com", Domain: "example.com", Created: "2026-01-02T00:00:00.000Z", Excerpt: "1行目\n2行目\r\n3行目"},
			},
			wantLines: []string{"  - excerpt: 1行目 2行目 3行目"},
		},
		{
			name: "titleの改行は畳み、角括弧はエスケープする",
			items: []RaindropItem{
				{Title: "[速報]\nGo 1.28 リリース", Link: "https://example.com/go", Domain: "example.com", Created: "2026-01-02T00:00:00.000Z"},
			},
			wantLines: []string{`- [\[速報\] Go 1.28 リリース](https://example.com/go)`},
		},
		{
			name: "linkに含まれる括弧はパーセントエンコードする",
			items: []RaindropItem{
				{Title: "Go", Link: "https://ja.wikipedia.org/wiki/Go_(プログラミング言語)", Domain: "ja.wikipedia.org", Created: "2026-01-02T00:00:00.000Z"},
			},
			wantLines: []string{"- [Go](https://ja.wikipedia.org/wiki/Go_%28プログラミング言語%29)"},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := FormatMarkdown(tt.items, tt.total, tt.search, tt.collection, tt.sort)
			for _, want := range tt.wantLines {
				if !strings.Contains(got, want) {
					t.Errorf("FormatMarkdown() output missing line %q\nfull output:\n%s", want, got)
				}
			}
			for _, notWant := range tt.notWant {
				if strings.Contains(got, notWant) {
					t.Errorf("FormatMarkdown() output should not contain %q\nfull output:\n%s", notWant, got)
				}
			}
		})
	}
}

func TestFormatJSON(t *testing.T) {
	items := []RaindropItem{
		{
			Title:   "t",
			Link:    "https://example.com",
			Tags:    []string{"a", "b"},
			Domain:  "example.com",
			Created: "2026-01-02T00:00:00.000Z",
			Excerpt: "ex\ncerpt",
			Note:    "note",
			// これらは出力に含まれないはずのフィールド
			ID:   123,
			Type: "link",
		},
	}

	got, err := FormatJSON(items)
	if err != nil {
		t.Fatalf("FormatJSON() unexpected error: %v", err)
	}

	var decoded []map[string]any
	if err := json.Unmarshal([]byte(got), &decoded); err != nil {
		t.Fatalf("FormatJSON() output is not valid JSON: %v", err)
	}
	if len(decoded) != 1 {
		t.Fatalf("len(decoded) = %d, want 1", len(decoded))
	}

	entry := decoded[0]
	for _, field := range []string{"title", "link", "tags", "domain", "created", "excerpt", "note"} {
		if _, ok := entry[field]; !ok {
			t.Errorf("FormatJSON() output missing field %q", field)
		}
	}
	if _, ok := entry["_id"]; ok {
		t.Errorf("FormatJSON() output should not include _id")
	}
	if _, ok := entry["type"]; ok {
		t.Errorf("FormatJSON() output should not include type")
	}
}

func TestFormatTSV(t *testing.T) {
	items := []RaindropItem{
		{
			Title:   "タイトル\t改行\n入り",
			Link:    "https://example.com",
			Tags:    []string{"a", "b"},
			Domain:  "example.com",
			Created: "2026-01-02T00:00:00.000Z",
			Excerpt: "抜粋\r\n複数行",
		},
	}

	got := FormatTSV(items)
	lines := strings.Split(strings.TrimRight(got, "\n"), "\n")

	if len(lines) != 2 {
		t.Fatalf("len(lines) = %d, want 2 (header + 1 row)", len(lines))
	}
	if lines[0] != "title\tlink\ttags\tdomain\tcreated\texcerpt" {
		t.Errorf("header = %q, want expected header", lines[0])
	}

	cells := strings.Split(lines[1], "\t")
	if len(cells) != 6 {
		t.Fatalf("len(cells) = %d, want 6, row=%q", len(cells), lines[1])
	}
	if cells[0] != "タイトル 改行 入り" {
		t.Errorf("title cell = %q, want tab/newline replaced with space", cells[0])
	}
	if cells[2] != "a,b" {
		t.Errorf("tags cell = %q, want %q", cells[2], "a,b")
	}
	if cells[5] != "抜粋 複数行" {
		t.Errorf("excerpt cell = %q, want %q", cells[5], "抜粋 複数行")
	}
}

func TestFormatDate(t *testing.T) {
	tests := []struct {
		name string
		in   string
		want string
	}{
		{name: "ミリ秒付きISO8601", in: "2026-01-02T03:04:05.000Z", want: "2026-01-02"},
		{name: "ミリ秒無しISO8601", in: "2026-01-02T03:04:05Z", want: "2026-01-02"},
		{name: "パース不可でもTより前を返す", in: "2026-01-02Tbroken", want: "2026-01-02"},
		{name: "完全に不正なら元の文字列を返す", in: "not-a-date", want: "not-a-date"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := formatDate(tt.in)
			if got != tt.want {
				t.Errorf("formatDate(%q) = %q, want %q", tt.in, got, tt.want)
			}
		})
	}
}
