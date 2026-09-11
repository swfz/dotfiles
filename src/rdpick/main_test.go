package main

import (
	"bytes"
	"strings"
	"testing"
)

func TestRunArgumentValidation(t *testing.T) {
	tests := []struct {
		name    string
		args    []string
		token   string
		wantErr string
	}{
		{
			name:    "query/-tag/-since がすべて無い",
			args:    nil,
			token:   "test-token",
			wantErr: "no query, -tag, or -since given",
		},
		{
			name:    "空文字のタグだけでは全件取得に落とさない",
			args:    []string{"-tag", ""},
			token:   "test-token",
			wantErr: "search query is empty",
		},
		{
			name:    "limitが0以下",
			args:    []string{"-limit", "0", "test"},
			token:   "test-token",
			wantErr: "-limit must be a positive integer",
		},
		{
			name:    "未知のformat",
			args:    []string{"-format", "yaml", "test"},
			token:   "test-token",
			wantErr: `invalid -format "yaml"`,
		},
		{
			name:    "不正なsince",
			args:    []string{"-since", "2026/01/01", "test"},
			token:   "test-token",
			wantErr: "invalid -since value",
		},
		{
			name:    "トークン未設定",
			args:    []string{"test"},
			token:   "",
			wantErr: "RAINDROP_TOKEN environment variable is not set",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Setenv("RAINDROP_TOKEN", tt.token)

			var stdout, stderr bytes.Buffer
			err := run(tt.args, &stdout, &stderr)
			if err == nil {
				t.Fatalf("run() error = nil, want error containing %q", tt.wantErr)
			}
			if !strings.Contains(err.Error(), tt.wantErr) {
				t.Errorf("run() error = %v, want message containing %q", err, tt.wantErr)
			}
			if stdout.Len() != 0 {
				t.Errorf("run() wrote to stdout on error: %q", stdout.String())
			}
		})
	}
}

func TestRunHelp(t *testing.T) {
	t.Setenv("RAINDROP_TOKEN", "test-token")

	var stdout, stderr bytes.Buffer
	if err := run([]string{"-h"}, &stdout, &stderr); err != nil {
		t.Fatalf("run(-h) error = %v, want nil", err)
	}
	if !strings.Contains(stderr.String(), "Usage: rdpick") {
		t.Errorf("run(-h) stderr = %q, want usage text", stderr.String())
	}
}
