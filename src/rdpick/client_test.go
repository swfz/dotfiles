package main

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"net/http/httptest"
	"strconv"
	"strings"
	"testing"
	"time"
)

func newTestClient(baseURL string) *Client {
	c := NewClient("test-token")
	c.BaseURL = baseURL
	return c
}

func itemsForRange(start, count int) []RaindropItem {
	items := make([]RaindropItem, 0, count)
	for i := 0; i < count; i++ {
		items = append(items, RaindropItem{ID: int64(start + i), Title: fmt.Sprintf("item-%d", start+i)})
	}
	return items
}

func TestClientFetchPaging(t *testing.T) {
	t.Run("limitちょうどでページ境界にまたがる", func(t *testing.T) {
		const total = 120
		server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			page, _ := strconv.Atoi(r.URL.Query().Get("page"))
			start := page * perPage
			remaining := total - start
			if remaining < 0 {
				remaining = 0
			}
			count := perPage
			if remaining < count {
				count = remaining
			}
			resp := raindropResponse{Result: true, Items: itemsForRange(start, count), Count: total}
			w.Header().Set("Content-Type", "application/json")
			json.NewEncoder(w).Encode(resp)
		}))
		defer server.Close()

		c := newTestClient(server.URL)
		items, count, err := c.Fetch(context.Background(), 0, "", "score", 120, false)
		if err != nil {
			t.Fatalf("Fetch() unexpected error: %v", err)
		}
		if len(items) != 120 {
			t.Errorf("len(items) = %d, want 120", len(items))
		}
		if count != total {
			t.Errorf("count = %d, want %d", count, total)
		}
	})

	t.Run("limit超過分は切り捨てられる", func(t *testing.T) {
		server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			page, _ := strconv.Atoi(r.URL.Query().Get("page"))
			resp := raindropResponse{Result: true, Items: itemsForRange(page*perPage, perPage), Count: 1000}
			w.Header().Set("Content-Type", "application/json")
			json.NewEncoder(w).Encode(resp)
		}))
		defer server.Close()

		c := newTestClient(server.URL)
		items, count, err := c.Fetch(context.Background(), 0, "", "score", 70, false)
		if err != nil {
			t.Fatalf("Fetch() unexpected error: %v", err)
		}
		if len(items) != 70 {
			t.Errorf("len(items) = %d, want 70", len(items))
		}
		if count != 1000 {
			t.Errorf("count = %d, want 1000", count)
		}
	})

	t.Run("perpage未満が返ったら最終ページとして打ち切り余分に叩かない", func(t *testing.T) {
		requestedPages := 0
		server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			requestedPages++
			resp := raindropResponse{Result: true, Items: itemsForRange(0, 10), Count: 10}
			w.Header().Set("Content-Type", "application/json")
			json.NewEncoder(w).Encode(resp)
		}))
		defer server.Close()

		c := newTestClient(server.URL)
		items, count, err := c.Fetch(context.Background(), 0, "", "score", 100, false)
		if err != nil {
			t.Fatalf("Fetch() unexpected error: %v", err)
		}
		if len(items) != 10 {
			t.Errorf("len(items) = %d, want 10", len(items))
		}
		if count != 10 {
			t.Errorf("count = %d, want 10", count)
		}
		if requestedPages != 1 {
			t.Errorf("requestedPages = %d, want 1 (must not fetch an extra empty page)", requestedPages)
		}
	})

	t.Run("itemsが空で返っても打ち切る", func(t *testing.T) {
		server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			resp := raindropResponse{Result: true, Items: []RaindropItem{}, Count: 0}
			w.Header().Set("Content-Type", "application/json")
			json.NewEncoder(w).Encode(resp)
		}))
		defer server.Close()

		c := newTestClient(server.URL)
		items, count, err := c.Fetch(context.Background(), 0, "", "score", 100, false)
		if err != nil {
			t.Fatalf("Fetch() unexpected error: %v", err)
		}
		if len(items) != 0 {
			t.Errorf("len(items) = %d, want 0", len(items))
		}
		if count != 0 {
			t.Errorf("count = %d, want 0", count)
		}
	})
}

func TestClientFetchErrors(t *testing.T) {
	t.Run("401はトークン無効のエラーになる", func(t *testing.T) {
		server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			w.WriteHeader(http.StatusUnauthorized)
			w.Write([]byte(`{"result":false}`))
		}))
		defer server.Close()

		c := newTestClient(server.URL)
		_, _, err := c.Fetch(context.Background(), 0, "", "score", 50, false)
		if err == nil {
			t.Fatal("Fetch() error = nil, want error")
		}
		if !strings.Contains(err.Error(), "401") || !strings.Contains(err.Error(), "Unauthorized") {
			t.Errorf("Fetch() error = %v, want message mentioning 401 Unauthorized", err)
		}
	})

	t.Run("429はRetry-After後に1回だけリトライして成功する", func(t *testing.T) {
		attempts := 0
		server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			attempts++
			if attempts == 1 {
				w.Header().Set("Retry-After", "0")
				w.WriteHeader(http.StatusTooManyRequests)
				return
			}
			resp := raindropResponse{Result: true, Items: itemsForRange(0, 5), Count: 5}
			w.Header().Set("Content-Type", "application/json")
			json.NewEncoder(w).Encode(resp)
		}))
		defer server.Close()

		c := newTestClient(server.URL)
		items, _, err := c.Fetch(context.Background(), 0, "", "score", 5, false)
		if err != nil {
			t.Fatalf("Fetch() unexpected error: %v", err)
		}
		if len(items) != 5 {
			t.Errorf("len(items) = %d, want 5", len(items))
		}
		if attempts != 2 {
			t.Errorf("attempts = %d, want 2", attempts)
		}
	})

	t.Run("429がリトライ後も続く場合はエラーになる", func(t *testing.T) {
		attempts := 0
		server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			attempts++
			w.Header().Set("Retry-After", "0")
			w.WriteHeader(http.StatusTooManyRequests)
		}))
		defer server.Close()

		c := newTestClient(server.URL)
		_, _, err := c.Fetch(context.Background(), 0, "", "score", 50, false)
		if err == nil {
			t.Fatal("Fetch() error = nil, want error")
		}
		if !strings.Contains(err.Error(), "429") {
			t.Errorf("Fetch() error = %v, want message mentioning 429", err)
		}
		if attempts != 2 {
			t.Errorf("attempts = %d, want 2 (1 initial + 1 retry)", attempts)
		}
	})

	t.Run("その他の非200エラーはステータスコードと本文を含む", func(t *testing.T) {
		server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			w.WriteHeader(http.StatusInternalServerError)
			w.Write([]byte("internal server error detail"))
		}))
		defer server.Close()

		c := newTestClient(server.URL)
		_, _, err := c.Fetch(context.Background(), 0, "", "score", 50, false)
		if err == nil {
			t.Fatal("Fetch() error = nil, want error")
		}
		if !strings.Contains(err.Error(), "500") || !strings.Contains(err.Error(), "internal server error detail") {
			t.Errorf("Fetch() error = %v, want message mentioning 500 and body", err)
		}
	})

	t.Run("不正なJSONはデコードエラーになる", func(t *testing.T) {
		server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			w.Header().Set("Content-Type", "application/json")
			w.Write([]byte("{not valid json"))
		}))
		defer server.Close()

		c := newTestClient(server.URL)
		_, _, err := c.Fetch(context.Background(), 0, "", "score", 50, false)
		if err == nil {
			t.Fatal("Fetch() error = nil, want error")
		}
	})
}

func TestRateLimitWait(t *testing.T) {
	tests := []struct {
		name       string
		retryAfter string
		want       int64 // seconds
	}{
		{name: "空文字はデフォルト", retryAfter: "", want: 2},
		{name: "正の整数はそのまま秒に変換", retryAfter: "5", want: 5},
		{name: "0はそのまま使う", retryAfter: "0", want: 0},
		{name: "パース不可はデフォルト", retryAfter: "not-a-number", want: 2},
		{name: "負数はデフォルト", retryAfter: "-1", want: 2},
		{name: "上限以内ならそのまま使う", retryAfter: "60", want: 60},
		{name: "上限を超える値は上限に丸める", retryAfter: "86400", want: 60},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := rateLimitWait(tt.retryAfter)
			if got.Seconds() != float64(tt.want) {
				t.Errorf("rateLimitWait(%q) = %v, want %d seconds", tt.retryAfter, got, tt.want)
			}
		})
	}
}

func TestSleepContext(t *testing.T) {
	t.Run("待機中にキャンセルされたら中断する", func(t *testing.T) {
		ctx, cancel := context.WithCancel(context.Background())
		cancel()

		err := sleepContext(ctx, 10*time.Second)
		if !errors.Is(err, context.Canceled) {
			t.Errorf("sleepContext() error = %v, want context.Canceled", err)
		}
	})

	t.Run("待機時間が経過したらnilを返す", func(t *testing.T) {
		if err := sleepContext(context.Background(), time.Millisecond); err != nil {
			t.Errorf("sleepContext() error = %v, want nil", err)
		}
	})
}

func TestClientFetchRateLimitInterrupted(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Retry-After", "30")
		w.WriteHeader(http.StatusTooManyRequests)
	}))
	defer server.Close()

	ctx, cancel := context.WithTimeout(context.Background(), 200*time.Millisecond)
	defer cancel()

	c := newTestClient(server.URL)
	_, _, err := c.Fetch(ctx, 0, "test", "score", 50, false)
	if err == nil {
		t.Fatal("Fetch() error = nil, want error")
	}
	if !strings.Contains(err.Error(), "interrupted") {
		t.Errorf("Fetch() error = %v, want message mentioning interrupted", err)
	}
}
