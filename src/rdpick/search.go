package main

import (
	"fmt"
	"strings"
	"time"
)

// sinceDateLayout は -since フラグで受け付ける日付フォーマット。
const sinceDateLayout = "2006-01-02"

// BuildSearch は位置引数のクエリ、タグ、日付下限を Raindrop API の search
// クエリ文字列 1 本に組み立てる。
//
//   - query はそのまま使う
//   - tags の各要素は "#foo" に変換する（空白を含む場合は "#\"foo bar\"" のように引用する）
//   - since は "YYYY-MM-DD" 形式でなければエラーとし、"created:>YYYY-MM-DD" に変換する
//   - 組み立てた各要素はスペース区切りで連結する
func BuildSearch(query string, tags []string, since string) (string, error) {
	parts := make([]string, 0, len(tags)+2)

	if query != "" {
		parts = append(parts, query)
	}

	for _, tag := range tags {
		if tag == "" {
			continue
		}
		if strings.ContainsAny(tag, " \t") {
			parts = append(parts, fmt.Sprintf(`#"%s"`, tag))
		} else {
			parts = append(parts, "#"+tag)
		}
	}

	if since != "" {
		if _, err := time.Parse(sinceDateLayout, since); err != nil {
			return "", fmt.Errorf("invalid -since value %q: expected format YYYY-MM-DD: %w", since, err)
		}
		parts = append(parts, "created:>"+since)
	}

	return strings.Join(parts, " "), nil
}
