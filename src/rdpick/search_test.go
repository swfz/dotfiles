package main

import "testing"

func TestBuildSearch(t *testing.T) {
	tests := []struct {
		name    string
		query   string
		tags    []string
		since   string
		want    string
		wantErr bool
	}{
		{
			name:  "queryのみ",
			query: "可観測性",
			want:  "可観測性",
		},
		{
			name:  "タグ複数",
			query: "",
			tags:  []string{"sre", "slo"},
			want:  "#sre #slo",
		},
		{
			name:  "since指定",
			query: "",
			since: "2026-01-01",
			want:  "created:>2026-01-01",
		},
		{
			name:  "全部組み合わせ",
			query: "可観測性",
			tags:  []string{"sre", "slo"},
			since: "2026-01-01",
			want:  "可観測性 #sre #slo created:>2026-01-01",
		},
		{
			name:  "空白入りタグは引用する",
			query: "",
			tags:  []string{"foo bar"},
			want:  `#"foo bar"`,
		},
		{
			name:    "不正なsinceはエラー",
			query:   "",
			since:   "2026/01/01",
			wantErr: true,
		},
		{
			name:  "空のタグ要素は無視する",
			query: "",
			tags:  []string{"", "sre"},
			want:  "#sre",
		},
		{
			name: "全部空なら空文字列",
			want: "",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, err := BuildSearch(tt.query, tt.tags, tt.since)
			if tt.wantErr {
				if err == nil {
					t.Fatalf("BuildSearch() error = nil, want error")
				}
				return
			}
			if err != nil {
				t.Fatalf("BuildSearch() unexpected error: %v", err)
			}
			if got != tt.want {
				t.Errorf("BuildSearch() = %q, want %q", got, tt.want)
			}
		})
	}
}
