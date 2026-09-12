// Command rdpick fetches candidate bookmarks from Raindrop.io so that
// theme relevance can be judged downstream (e.g. by feeding the output
// into Claude Code). It only fetches and formats data; it does not make
// any relevance judgement itself.
package main

import (
	"context"
	"errors"
	"flag"
	"fmt"
	"io"
	"os"
	"os/signal"
	"strings"
	"syscall"
)

const usageText = `Usage: rdpick [options] <query>

Fetch candidate bookmarks from Raindrop.io (query is optional if -tag or
-since is given, but at least one of query/-tag/-since is required).

Examples:
  rdpick -tag sre -tag slo "可観測性"
  rdpick -collection 12345 -since 2026-01-01 -format json "kubernetes"
  rdpick -tag golang -limit 20 -format tsv

Options:
`

// tagList は -tag フラグを複数回指定できるようにする flag.Value 実装。
type tagList []string

func (t *tagList) String() string {
	if t == nil {
		return ""
	}
	return strings.Join(*t, ",")
}

func (t *tagList) Set(value string) error {
	*t = append(*t, value)
	return nil
}

func main() {
	if err := run(os.Args[1:], os.Stdout, os.Stderr); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}

func run(args []string, stdout, stderr io.Writer) error {
	fs := flag.NewFlagSet("rdpick", flag.ContinueOnError)
	fs.SetOutput(stderr)
	fs.Usage = func() {
		fmt.Fprint(stderr, usageText)
		fs.PrintDefaults()
	}

	collection := fs.Int("collection", 0, "collection ID to search (0 = all collections, -1 = unsorted)")
	limit := fs.Int("limit", 100, "maximum number of items to fetch")
	format := fs.String("format", "markdown", "output format: markdown, json, tsv")
	sort := fs.String("sort", "score", "sort order: score (relevancy), -created, created, title, -title, domain, -domain, -sort (manual order)")
	since := fs.String("since", "", "only include items created on/after this date (YYYY-MM-DD)")
	nested := fs.Bool("nested", false, "include nested collections")
	verbose := fs.Bool("verbose", false, "print debug output to stderr")

	var tags tagList
	fs.Var(&tags, "tag", "filter by tag (repeatable)")

	if err := fs.Parse(args); err != nil {
		if errors.Is(err, flag.ErrHelp) {
			return nil
		}
		return err
	}

	query := strings.Join(fs.Args(), " ")
	if query == "" && len(tags) == 0 && *since == "" {
		fs.Usage()
		return fmt.Errorf("no query, -tag, or -since given: nothing to search for")
	}

	if *limit <= 0 {
		return fmt.Errorf("-limit must be a positive integer, got %d", *limit)
	}

	switch *format {
	case "markdown", "json", "tsv":
	default:
		return fmt.Errorf("invalid -format %q: must be one of markdown, json, tsv", *format)
	}

	token := os.Getenv("RAINDROP_TOKEN")
	if token == "" {
		return fmt.Errorf(`RAINDROP_TOKEN environment variable is not set

Get a test token from https://app.raindrop.io/settings/integrations
and set it, e.g.:
  export RAINDROP_TOKEN=your_token_here`)
	}

	search, err := BuildSearch(query, tags, *since)
	if err != nil {
		return err
	}
	if search == "" {
		fs.Usage()
		return fmt.Errorf("search query is empty after parsing arguments: refusing to fetch the entire collection")
	}

	client := NewClient(token)
	client.Verbose = *verbose
	if *verbose {
		fmt.Fprintf(stderr, "[DEBUG] search=%q collection=%d sort=%s limit=%d nested=%v\n", search, *collection, *sort, *limit, *nested)
	}

	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	items, total, err := client.Fetch(ctx, *collection, search, *sort, *limit, *nested)
	if err != nil {
		return fmt.Errorf("failed to fetch raindrops: %w", err)
	}

	switch *format {
	case "markdown":
		fmt.Fprint(stdout, FormatMarkdown(items, total, search, *collection, *sort))
	case "json":
		out, err := FormatJSON(items)
		if err != nil {
			return err
		}
		fmt.Fprintln(stdout, out)
	case "tsv":
		fmt.Fprint(stdout, FormatTSV(items))
	}

	return nil
}
