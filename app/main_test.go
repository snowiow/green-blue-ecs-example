package main

import (
	"net/http"
	"net/http/httptest"
	"testing"
)

func Test_fileHandler(t *testing.T) {
	fh := fileHandler()
	req, _ := http.NewRequest("GET", "/", nil)
	w := httptest.NewRecorder()
	fh.ServeHTTP(w, req)
	if w.Code != http.StatusOK {
		t.Errorf("Home page didn't return %v", http.StatusOK)
	}
}
