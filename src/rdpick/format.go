package main

import (
	"encoding/json"
	"fmt"
	"strings"
	"time"
)

// outputItem は json/tsv 出力で使うフィールドだけに絞った形。
type outputItem struct {
	Title   string   `json:"title"`
	Link    string   `json:"link"`
	Tags    []string `json:"tags"`
	Domain  string   `json:"domain"`
	Created string   `json:"created"`
	Excerpt string   `json:"excerpt"`
	Note    string   `json:"note"`
}

// FormatMarkdown は Claude Code に読ませる想定の Markdown 形式で出力する。
func FormatMarkdown(items []RaindropItem, total int, search string, collection int, sort string) string {
	var sb strings.Builder

	fmt.Fprintf(&sb, "# Query: %s\n", search)
	fmt.Fprintf(&sb, "Fetched %d of %d matches (collection: %d, sort: %s)\n\n", len(items), total, collection, sort)

	for _, item := range items {
		fmt.Fprintf(&sb, "- [%s](%s)\n", escapeMarkdownText(item.Title), escapeMarkdownURL(item.Link))

		if len(item.Tags) > 0 {
			fmt.Fprintf(&sb, "  - tags: %s\n", strings.Join(item.Tags, ", "))
		}

		fmt.Fprintf(&sb, "  - domain: %s / created: %s\n", item.Domain, formatDate(item.Created))

		if excerpt := collapseWhitespace(item.Excerpt); excerpt != "" {
			fmt.Fprintf(&sb, "  - excerpt: %s\n", excerpt)
		}
		if note := collapseWhitespace(item.Note); note != "" {
			fmt.Fprintf(&sb, "  - note: %s\n", note)
		}
	}

	return sb.String()
}

// FormatJSON は必要フィールドのみに絞った配列を整形済み JSON で返す。
func FormatJSON(items []RaindropItem) (string, error) {
	out := make([]outputItem, 0, len(items))
	for _, item := range items {
		out = append(out, outputItem{
			Title:   item.Title,
			Link:    item.Link,
			Tags:    item.Tags,
			Domain:  item.Domain,
			Created: item.Created,
			Excerpt: item.Excerpt,
			Note:    item.Note,
		})
	}

	b, err := json.MarshalIndent(out, "", "  ")
	if err != nil {
		return "", fmt.Errorf("failed to marshal JSON output: %w", err)
	}
	return string(b), nil
}

// FormatTSV はヘッダ行つきの TSV を返す。セル内のタブ・改行は空白に置換する。
func FormatTSV(items []RaindropItem) string {
	var sb strings.Builder

	sb.WriteString("title\tlink\ttags\tdomain\tcreated\texcerpt\n")
	for _, item := range items {
		fmt.Fprintf(&sb, "%s\t%s\t%s\t%s\t%s\t%s\n",
			sanitizeTSVField(item.Title),
			sanitizeTSVField(item.Link),
			sanitizeTSVField(strings.Join(item.Tags, ",")),
			sanitizeTSVField(item.Domain),
			sanitizeTSVField(item.Created),
			sanitizeTSVField(item.Excerpt),
		)
	}

	return sb.String()
}

var tsvFieldReplacer = strings.NewReplacer("\r\n", " ", "\t", " ", "\n", " ", "\r", " ")

// sanitizeTSVField はセル内のタブ・改行を空白に置換する。
func sanitizeTSVField(s string) string {
	return tsvFieldReplacer.Replace(s)
}

var markdownTextReplacer = strings.NewReplacer(`\`, `\\`, "[", `\[`, "]", `\]`)

// escapeMarkdownText はリンクラベルとして安全な1行のテキストに整える。
// 改行が入るとぶら下がりのサブ項目構造が壊れ、角括弧が入るとリンク構文が
// 途中で終端してしまうため、どちらも潰しておく。
func escapeMarkdownText(s string) string {
	return markdownTextReplacer.Replace(collapseWhitespace(s))
}

var markdownURLReplacer = strings.NewReplacer("(", "%28", ")", "%29", " ", "%20")

// escapeMarkdownURL は URL 自体に含まれる括弧をパーセントエンコードする。
// 括弧をそのまま埋めると Markdown のリンクが途中で閉じてしまう。
func escapeMarkdownURL(s string) string {
	return markdownURLReplacer.Replace(s)
}

// collapseWhitespace は改行・タブ等の連続する空白を単一の空白に畳んで1行にする。
// 長さは切り詰めない。
func collapseWhitespace(s string) string {
	return strings.Join(strings.Fields(s), " ")
}

// formatDate は Raindrop API の ISO8601 形式 ("2026-01-02T03:04:05.000Z") を
// "2026-01-02" に整形する。パースできない場合は "T" より前を返し、それも無ければ元の文字列を返す。
func formatDate(s string) string {
	t, err := time.Parse(time.RFC3339, s)
	if err == nil {
		return t.Format("2006-01-02")
	}
	if idx := strings.Index(s, "T"); idx > 0 {
		return s[:idx]
	}
	return s
}
