package main

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"strconv"
	"time"
)

// defaultBaseURL は Raindrop API のベース URL。
const defaultBaseURL = "https://api.raindrop.io/rest/v1"

// perPage は 1 リクエストあたりに取得する件数（Raindrop API の上限）。
const perPage = 50

// requestTimeout は HTTP リクエスト全体のタイムアウト。
const requestTimeout = 30 * time.Second

// defaultRateLimitWait は Retry-After ヘッダが無い場合の 429 リトライ待機時間。
const defaultRateLimitWait = 2 * time.Second

// maxRateLimitWait は Retry-After ヘッダに従って待つ上限。
// サーバが極端に長い値を返しても CLI が固まらないようにする。
const maxRateLimitWait = 60 * time.Second

// RaindropItem は Raindrop API のレスポンスから使用するフィールドのみを取り出した1件分のブックマーク。
type RaindropItem struct {
	ID         int64    `json:"_id"`
	Title      string   `json:"title"`
	Excerpt    string   `json:"excerpt"`
	Note       string   `json:"note"`
	Link       string   `json:"link"`
	Domain     string   `json:"domain"`
	Type       string   `json:"type"`
	Tags       []string `json:"tags"`
	Created    string   `json:"created"`
	LastUpdate string   `json:"lastUpdate"`
}

// raindropResponse は GET /raindrops/{collectionId} のレスポンス全体。
type raindropResponse struct {
	Result bool           `json:"result"`
	Items  []RaindropItem `json:"items"`
	Count  int            `json:"count"`
}

// Client は Raindrop API を叩くクライアント。
type Client struct {
	Token      string
	BaseURL    string
	HTTPClient *http.Client
	Verbose    bool
}

// NewClient はデフォルト設定の Client を生成する。
func NewClient(token string) *Client {
	return &Client{
		Token:   token,
		BaseURL: defaultBaseURL,
		HTTPClient: &http.Client{
			Timeout: requestTimeout,
		},
	}
}

// Fetch は search/sort 条件でヒットしたアイテムを perpage=50 でページングしながら
// limit 件（またはヒット全件、いずれか少ない方）まで取得する。
// 戻り値の2つめはレスポンスに含まれる総マッチ件数 (count) 。
func (c *Client) Fetch(ctx context.Context, collectionID int, search, sort string, limit int, nested bool) ([]RaindropItem, int, error) {
	var items []RaindropItem
	total := 0

	for page := 0; len(items) < limit; page++ {
		resp, err := c.fetchPage(ctx, collectionID, search, sort, page, nested)
		if err != nil {
			return nil, 0, err
		}
		total = resp.Count

		if c.Verbose {
			fmt.Fprintf(os.Stderr, "[DEBUG] page=%d fetched=%d\n", page, len(resp.Items))
		}

		items = append(items, resp.Items...)

		// 返却件数が perpage 未満なら最終ページなので、空ページを余分に叩かない。
		if len(resp.Items) < perPage {
			break
		}
	}

	if len(items) > limit {
		items = items[:limit]
	}

	return items, total, nil
}

// fetchPage は1ページ分を取得する。429 の場合は Retry-After（無ければ 2 秒）待ってから1回だけリトライする。
func (c *Client) fetchPage(ctx context.Context, collectionID int, search, sort string, page int, nested bool) (*raindropResponse, error) {
	resp, err := c.doGet(ctx, collectionID, search, sort, page, nested)
	if err != nil {
		return nil, fmt.Errorf("failed to call raindrop API: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode == http.StatusTooManyRequests {
		wait := rateLimitWait(resp.Header.Get("Retry-After"))
		if c.Verbose {
			fmt.Fprintf(os.Stderr, "[DEBUG] rate limited (429), retrying in %s\n", wait)
		}
		io.Copy(io.Discard, resp.Body)
		if err := sleepContext(ctx, wait); err != nil {
			return nil, fmt.Errorf("interrupted while waiting to retry after 429: %w", err)
		}

		retryResp, err := c.doGet(ctx, collectionID, search, sort, page, nested)
		if err != nil {
			return nil, fmt.Errorf("failed to call raindrop API (retry after 429): %w", err)
		}
		defer retryResp.Body.Close()

		if retryResp.StatusCode == http.StatusTooManyRequests {
			return nil, fmt.Errorf("rate limited by raindrop API (HTTP 429) even after retry")
		}
		return decodeResponse(retryResp)
	}

	return decodeResponse(resp)
}

// doGet は1ページ分のリクエストを組み立てて送信する。
func (c *Client) doGet(ctx context.Context, collectionID int, search, sort string, page int, nested bool) (*http.Response, error) {
	u, err := url.Parse(fmt.Sprintf("%s/raindrops/%d", c.BaseURL, collectionID))
	if err != nil {
		return nil, fmt.Errorf("failed to build request URL: %w", err)
	}

	q := u.Query()
	if search != "" {
		q.Set("search", search)
	}
	q.Set("sort", sort)
	q.Set("page", strconv.Itoa(page))
	q.Set("perpage", strconv.Itoa(perPage))
	if nested {
		q.Set("nested", "true")
	}
	u.RawQuery = q.Encode()

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, u.String(), nil)
	if err != nil {
		return nil, fmt.Errorf("failed to build HTTP request: %w", err)
	}
	req.Header.Set("Authorization", "Bearer "+c.Token)

	if c.Verbose {
		fmt.Fprintf(os.Stderr, "[DEBUG] GET %s (page=%d)\n", u.String(), page)
	}

	return c.HTTPClient.Do(req)
}

// decodeResponse はステータスコードを見てエラーを判定し、問題なければ JSON をデコードする。
func decodeResponse(resp *http.Response) (*raindropResponse, error) {
	if resp.StatusCode == http.StatusUnauthorized {
		return nil, fmt.Errorf("raindrop API returned 401 Unauthorized: token is invalid or expired (check RAINDROP_TOKEN)")
	}

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(io.LimitReader(resp.Body, 500))
		io.Copy(io.Discard, resp.Body)
		return nil, fmt.Errorf("raindrop API returned unexpected status %d: %s", resp.StatusCode, string(body))
	}

	var result raindropResponse
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, fmt.Errorf("failed to decode raindrop API response: %w", err)
	}

	return &result, nil
}

// rateLimitWait は Retry-After ヘッダの値から待機時間を決める。
// 空文字またはパース不可な場合は defaultRateLimitWait を返す。
func rateLimitWait(retryAfter string) time.Duration {
	if retryAfter == "" {
		return defaultRateLimitWait
	}
	secs, err := strconv.Atoi(retryAfter)
	if err != nil || secs < 0 {
		return defaultRateLimitWait
	}
	wait := time.Duration(secs) * time.Second
	if wait > maxRateLimitWait {
		return maxRateLimitWait
	}
	return wait
}

// sleepContext は d だけ待つ。待っている間に ctx がキャンセルされたら
// その時点で ctx.Err() を返して中断する。
func sleepContext(ctx context.Context, d time.Duration) error {
	if d <= 0 {
		return ctx.Err()
	}
	timer := time.NewTimer(d)
	defer timer.Stop()

	select {
	case <-ctx.Done():
		return ctx.Err()
	case <-timer.C:
		return nil
	}
}
